import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import Stripe from 'stripe';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { TenantContext } from '@tenancy/application/tenant-context';
import { TenantRepository } from '@tenancy/infrastructure/tenant.repository';
import { BillingRepository } from '../infrastructure/billing.repository';
import { JobsService, type PaymentJob } from '@shared/infrastructure/queue';
import type { UserEntity } from '@auth/domain/entities/user.entity';

@Injectable()
export class BillingService {
  constructor(
    private environment: Environment,
    private context: TenantContext,
    private tenants: TenantRepository,
    private repository: BillingRepository,
    private jobs: JobsService,
  ) {}

  async status() {
    const tenant = await this.tenants.findTenantById(this.context.tenantId);
    const subscription = await this.repository.findByTenant(
      this.context.tenantId,
    );
    return { tenantStatus: tenant?.status ?? 'canceled', subscription };
  }

  async createCheckout(user: UserEntity) {
    this.blockSupport(user);
    if (user.role !== 'owner') {
      throw new ForbiddenException(
        'Somente o proprietário pode contratar o plano.',
      );
    }
    const stripe = this.stripe();
    const config = this.config();
    const tenant = await this.tenants.findTenantById(this.context.tenantId);
    if (!tenant) throw new BadRequestException('Família não encontrada.');
    const existing = await this.repository.findByTenant(tenant.id);
    let customerId = existing?.customerId ?? undefined;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        name: tenant.name,
        metadata: { tenantId: tenant.id },
      });
      customerId = customer.id;
    }
    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      customer: customerId,
      client_reference_id: tenant.id,
      line_items: [{ price: config.stripePriceId, quantity: 1 }],
      success_url: config.successUrl,
      cancel_url: config.cancelUrl,
      allow_promotion_codes: true,
      metadata: { tenantId: tenant.id },
      subscription_data: { metadata: { tenantId: tenant.id } },
    });
    await this.repository.upsert(tenant.id, {
      customerId,
      checkoutSessionId: session.id,
      priceId: config.stripePriceId,
      status: 'checkout_created',
    });
    return { checkoutUrl: session.url };
  }

  async createPortal(user: UserEntity) {
    this.blockSupport(user);
    if (user.role !== 'owner') {
      throw new ForbiddenException(
        'Somente o proprietário gerencia a assinatura.',
      );
    }
    const subscription = await this.repository.findByTenant(
      this.context.tenantId,
    );
    if (!subscription?.customerId) {
      throw new BadRequestException('Assinatura ainda não iniciada.');
    }
    const config = this.config();
    const portal = await this.stripe().billingPortal.sessions.create({
      customer: subscription.customerId,
      return_url: config.successUrl,
    });
    return { portalUrl: portal.url };
  }

  async handleWebhook(rawBody: Buffer, signature?: string) {
    if (!signature) throw new BadRequestException('Assinatura Stripe ausente.');
    const config = this.config();
    let event: Stripe.Event;
    try {
      event = this.stripe().webhooks.constructEvent(
        rawBody,
        signature,
        config.stripeWebhookSecret,
      );
    } catch {
      throw new BadRequestException('Webhook Stripe inválido.');
    }
    await this.jobs.enqueuePaymentEvent({
      eventId: event.id,
      eventType: event.type,
      payload: event as unknown as Record<string, unknown>,
    });
    return { received: true, queued: true };
  }

  async processPaymentEvent(job: PaymentJob) {
    if (!(await this.repository.reserveEvent(job.eventId, job.eventType))) {
      return { processed: false, duplicate: true };
    }
    try {
      await this.applyEvent(job.payload as unknown as Stripe.Event);
      return { processed: true };
    } catch (error) {
      await this.repository.releaseEvent(job.eventId);
      throw error;
    }
  }

  private async applyEvent(event: Stripe.Event): Promise<void> {
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session;
      const tenantId =
        session.metadata?.tenantId || session.client_reference_id;
      const subscriptionId =
        typeof session.subscription === 'string'
          ? session.subscription
          : session.subscription?.id;
      if (!tenantId || !subscriptionId) return;
      const subscription =
        await this.stripe().subscriptions.retrieve(subscriptionId);
      await this.syncSubscription(tenantId, subscription, {
        customerId:
          typeof session.customer === 'string'
            ? session.customer
            : session.customer?.id,
        checkoutSessionId: session.id,
      });
      return;
    }

    if (
      event.type === 'customer.subscription.created' ||
      event.type === 'customer.subscription.updated' ||
      event.type === 'customer.subscription.deleted'
    ) {
      const subscription = event.data.object as Stripe.Subscription;
      const existing = await this.repository.findBySubscriptionId(
        subscription.id,
      );
      const tenantId = subscription.metadata?.tenantId || existing?.tenantId;
      if (tenantId) await this.syncSubscription(tenantId, subscription);
    }
  }

  private async syncSubscription(
    tenantId: string,
    subscription: Stripe.Subscription,
    extra: { customerId?: string; checkoutSessionId?: string } = {},
  ) {
    const raw = subscription as unknown as {
      current_period_end?: number;
      cancel_at_period_end?: boolean;
    };
    const tenantStatus = mapTenantStatus(subscription.status);
    await Promise.all([
      this.repository.upsert(tenantId, {
        subscriptionId: subscription.id,
        customerId:
          extra.customerId ||
          (typeof subscription.customer === 'string'
            ? subscription.customer
            : subscription.customer.id),
        checkoutSessionId: extra.checkoutSessionId,
        status: subscription.status,
        currentPeriodEnd: raw.current_period_end
          ? new Date(raw.current_period_end * 1000)
          : null,
        cancelAtPeriodEnd: raw.cancel_at_period_end ?? false,
      }),
      this.tenants.updateTenant(tenantId, { status: tenantStatus }),
    ]);
  }

  private config() {
    if (!this.environment.billing) {
      throw new ServiceUnavailableException(
        'Stripe não configurado. Defina STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET e STRIPE_PRICE_ID.',
      );
    }
    return this.environment.billing;
  }

  private stripe() {
    return new Stripe(this.config().stripeSecretKey);
  }

  private blockSupport(user: UserEntity) {
    if (user.sessionScope === 'support') {
      throw new ForbiddenException(
        'Assinaturas não podem ser alteradas durante suporte.',
      );
    }
  }
}

function mapTenantStatus(status: string) {
  if (status === 'active' || status === 'trialing') return 'active' as const;
  if (status === 'past_due' || status === 'unpaid') return 'past_due' as const;
  if (status === 'canceled') return 'canceled' as const;
  if (status === 'paused') return 'suspended' as const;
  return 'pending_payment' as const;
}
