import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  BillingEventDocument,
  BillingEventMongoDocument,
  SubscriptionPlanDocument,
  SubscriptionPlanInterval,
  SubscriptionPlanMongoDocument,
  SubscriptionDocument,
  SubscriptionMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  cleanUndefined,
  toId,
} from '@shared/infrastructure/database/mongo.utils';

export type SubscriptionRecord = {
  id: string;
  tenantId: string;
  provider: 'stripe';
  planInterval?: SubscriptionPlanInterval | null;
  planName?: string | null;
  priceCents?: number | null;
  currency?: string | null;
  customerId?: string | null;
  subscriptionId?: string | null;
  checkoutSessionId?: string | null;
  priceId?: string | null;
  status: string;
  currentPeriodEnd?: Date | null;
  cancelAtPeriodEnd: boolean;
  createdAt: Date;
  updatedAt: Date;
};

export type SubscriptionPlanRecord = {
  id: string;
  interval: SubscriptionPlanInterval;
  name: string;
  description: string;
  priceCents: number;
  currency: string;
  stripePriceId?: string | null;
  active: boolean;
  highlighted: boolean;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class BillingRepository {
  constructor(
    @InjectModel(SubscriptionDocument.name)
    private subscriptions: Model<SubscriptionMongoDocument>,
    @InjectModel(SubscriptionPlanDocument.name)
    private plans: Model<SubscriptionPlanMongoDocument>,
    @InjectModel(BillingEventDocument.name)
    private events: Model<BillingEventMongoDocument>,
  ) {}

  private toRecord(
    document: SubscriptionMongoDocument | null,
  ): SubscriptionRecord | null {
    if (!document) return null;
    return {
      id: toId(document),
      tenantId: document.tenantId,
      provider: 'stripe',
      planInterval: document.planInterval ?? null,
      planName: document.planName ?? null,
      priceCents: document.priceCents ?? null,
      currency: document.currency ?? null,
      customerId: document.customerId ?? null,
      subscriptionId: document.subscriptionId ?? null,
      checkoutSessionId: document.checkoutSessionId ?? null,
      priceId: document.priceId ?? null,
      status: document.status,
      currentPeriodEnd: document.currentPeriodEnd ?? null,
      cancelAtPeriodEnd: document.cancelAtPeriodEnd ?? false,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
    };
  }

  private toPlanRecord(
    document: SubscriptionPlanMongoDocument | null,
  ): SubscriptionPlanRecord | null {
    if (!document) return null;
    return {
      id: toId(document),
      interval: document.interval,
      name: document.name,
      description: document.description,
      priceCents: document.priceCents,
      currency: document.currency,
      stripePriceId: document.stripePriceId ?? null,
      active: document.active,
      highlighted: document.highlighted,
      sortOrder: document.sortOrder,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
    };
  }

  async findByTenant(tenantId: string) {
    return this.toRecord(await this.subscriptions.findOne({ tenantId }).exec());
  }

  async findBySubscriptionId(subscriptionId: string) {
    return this.toRecord(
      await this.subscriptions.findOne({ subscriptionId }).exec(),
    );
  }

  async upsert(
    tenantId: string,
    data: Partial<
      Omit<SubscriptionRecord, 'id' | 'tenantId' | 'createdAt' | 'updatedAt'>
    >,
  ) {
    return this.toRecord(
      await this.subscriptions
        .findOneAndUpdate(
          { tenantId },
          {
            $set: cleanUndefined(data as Record<string, unknown>),
            $setOnInsert: { tenantId, provider: 'stripe' },
          },
          { upsert: true, new: true, setDefaultsOnInsert: true },
        )
        .exec(),
    )!;
  }

  async ensureDefaultPlans(): Promise<void> {
    await Promise.all(
      defaultPlans.map((plan) =>
        this.plans
          .updateOne(
            { interval: plan.interval },
            { $setOnInsert: plan },
            { upsert: true },
          )
          .exec(),
      ),
    );
  }

  async listPlans(options: { activeOnly?: boolean } = {}) {
    await this.ensureDefaultPlans();
    const filter = options.activeOnly ? { active: true } : {};
    const documents = await this.plans
      .find(filter)
      .sort({ sortOrder: 1, createdAt: 1 })
      .exec();
    return documents.map((document) => this.toPlanRecord(document)!);
  }

  async findPlanByInterval(
    interval: SubscriptionPlanInterval,
    options: { activeOnly?: boolean } = {},
  ) {
    await this.ensureDefaultPlans();
    return this.toPlanRecord(
      await this.plans
        .findOne({
          interval,
          ...(options.activeOnly ? { active: true } : {}),
        })
        .exec(),
    );
  }

  async updatePlan(
    interval: SubscriptionPlanInterval,
    data: Partial<
      Omit<
        SubscriptionPlanRecord,
        'id' | 'interval' | 'createdAt' | 'updatedAt'
      >
    >,
  ) {
    await this.ensureDefaultPlans();
    return this.toPlanRecord(
      await this.plans
        .findOneAndUpdate(
          { interval },
          { $set: cleanUndefined(data as Record<string, unknown>) },
          { new: true, runValidators: true },
        )
        .exec(),
    );
  }

  async reserveEvent(providerEventId: string, type: string): Promise<boolean> {
    try {
      await this.events.create({ providerEventId, type });
      return true;
    } catch (error) {
      if ((error as { code?: number })?.code === 11000) return false;
      throw error;
    }
  }

  async releaseEvent(providerEventId: string): Promise<void> {
    await this.events.deleteOne({ providerEventId }).exec();
  }
}

const defaultPlans: Array<
  Omit<SubscriptionPlanRecord, 'id' | 'createdAt' | 'updatedAt'>
> = [
  {
    interval: 'monthly',
    name: 'Mensal',
    description: 'Acesso completo com cobrança mês a mês.',
    priceCents: 1990,
    currency: 'BRL',
    active: true,
    highlighted: false,
    sortOrder: 10,
  },
  {
    interval: 'semiannual',
    name: 'Semestral',
    description: 'Seis meses de acesso completo com valor reduzido.',
    priceCents: 9990,
    currency: 'BRL',
    active: true,
    highlighted: true,
    sortOrder: 20,
  },
  {
    interval: 'annual',
    name: 'Anual',
    description: 'Um ano inteiro para cuidar da história da família.',
    priceCents: 17990,
    currency: 'BRL',
    active: true,
    highlighted: false,
    sortOrder: 30,
  },
  {
    interval: 'lifetime',
    name: 'Vitalícia',
    description: 'Pagamento único para manter o espaço ativo para sempre.',
    priceCents: 49990,
    currency: 'BRL',
    active: true,
    highlighted: false,
    sortOrder: 40,
  },
];
