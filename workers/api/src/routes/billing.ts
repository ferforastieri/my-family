import { Hono } from 'hono';
import { z } from 'zod';
import Stripe from 'stripe';
import type { AppEnv } from '../env';
import { authMiddleware } from '../auth';
import { badRequest, envelope, parseBody } from '../http';
import { execute, now, queryOne } from '../db';

interface PriceRow {
  plan: string;
  currency: string;
  amount_minor: number;
  stripe_price_id: string;
}

interface TenantBillingRow {
  id: string;
  name: string;
  plan_code: string;
  stripe_customer_id: string | null;
  stripe_subscription_id: string | null;
}

const billingRoutes = new Hono<AppEnv>();

function client(env: AppEnv['Bindings']) {
  if (!env.STRIPE_SECRET_KEY) throw new Error('Stripe não configurado.');
  return new Stripe(env.STRIPE_SECRET_KEY, {
    httpClient: Stripe.createFetchHttpClient(),
  });
}


billingRoutes.get('/prices', async (c) => {
  const rows = await c.env.DB.prepare(
    'SELECT plan, currency, amount_minor, stripe_price_id FROM plan_prices WHERE active = 1 ORDER BY plan',
  ).all<PriceRow>();
  return envelope(c, {
    items: rows.results.map((row) => ({
      plan: row.plan,
      currency: row.currency,
      amountMinor: row.amount_minor,
      priceId: row.stripe_price_id,
    })),
  });
});

billingRoutes.post('/checkout', authMiddleware, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(
    c,
    z.object({ plan: z.enum(['monthly', 'yearly']) }),
  );
  const price = await queryOne<PriceRow>(
    c.env.DB,
    'SELECT plan, currency, amount_minor, stripe_price_id FROM plan_prices WHERE plan = ? AND active = 1',
    [body.plan],
  );
  if (!price?.stripe_price_id?.startsWith('price_')) {
    throw badRequest('Plano indisponível no momento.');
  }
  const tenant = await queryOne<TenantBillingRow>(
    c.env.DB,
    'SELECT id, name, plan_code, stripe_customer_id, stripe_subscription_id FROM tenants WHERE id = ?',
    [principal.tenantId],
  );
  if (!tenant) throw badRequest('Família não encontrada.');

  const stripe = client(c.env);
  let customerId = tenant.stripe_customer_id;
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: principal.email,
      name: tenant.name,
      metadata: { tenant_id: tenant.id, app: 'siao' },
    });
    customerId = customer.id;
    await execute(
      c.env.DB,
      'UPDATE tenants SET stripe_customer_id = ?, updated_at = ? WHERE id = ?',
      [customerId, now(), tenant.id],
    );
  }

  const origin = new URL(c.req.url).origin;
  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    payment_method_types: ['card'],
    customer: customerId,
    client_reference_id: tenant.id,
    line_items: [{ price: price.stripe_price_id, quantity: 1 }],
    success_url: `${origin}/#/perfil?payment=success`,
    cancel_url: `${origin}/#/perfil?payment=cancel`,
    metadata: { tenant_id: tenant.id, plan: body.plan },
    subscription_data: { metadata: { tenant_id: tenant.id, plan: body.plan } },
  });
  return envelope(c, { url: session.url });
});

billingRoutes.post('/portal', authMiddleware, async (c) => {
  const principal = c.get('principal');
  const tenant = await queryOne<TenantBillingRow>(
    c.env.DB,
    'SELECT id, name, plan_code, stripe_customer_id, stripe_subscription_id FROM tenants WHERE id = ?',
    [principal.tenantId],
  );
  if (!tenant?.stripe_customer_id) {
    throw badRequest('Nenhuma assinatura encontrada.');
  }
  const origin = new URL(c.req.url).origin;
  const session = await client(c.env).billingPortal.sessions.create({
    customer: tenant.stripe_customer_id,
    return_url: `${origin}/#/perfil`,
  });
  return envelope(c, { url: session.url });
});

async function applySubscription(
  env: AppEnv['Bindings'],
  subscription: Stripe.Subscription,
) {
  const customerId =
    typeof subscription.customer === 'string'
      ? subscription.customer
      : subscription.customer.id;
  const item = subscription.items.data[0];
  const priceId =
    typeof item?.price === 'string' ? item.price : item?.price?.id;
  const price = priceId
    ? await queryOne<PriceRow>(
        env.DB,
        'SELECT plan, currency, amount_minor, stripe_price_id FROM plan_prices WHERE stripe_price_id = ?',
        [priceId],
      )
    : null;
  if (!price) return;
  const active =
    subscription.status === 'active' || subscription.status === 'trialing';
  const periodEnd = item?.current_period_end ?? 0;
  await execute(
    env.DB,
    `UPDATE tenants SET plan_code = ?, billing_interval = ?,
       stripe_subscription_id = ?, subscription_status = ?,
       access_until = ?, subscription_ending_at = ?, updated_at = ?
     WHERE stripe_customer_id = ?`,
    [
      active ? price.plan : 'free',
      active ? price.plan : null,
      subscription.id,
      active ? 'active' : subscription.status === 'past_due' ? 'past_due' : 'cancelled',
      active ? periodEnd : null,
      subscription.cancel_at_period_end ? subscription.cancel_at ?? periodEnd : null,
      now(),
      customerId,
    ],
  );
}

billingRoutes.post('/webhook', async (c) => {
  const signature = c.req.header('stripe-signature');
  if (!signature || !c.env.STRIPE_WEBHOOK_SECRET) {
    return c.text('Missing signature', 400);
  }
  let event: Stripe.Event;
  try {
    event = await client(c.env).webhooks.constructEventAsync(
      await c.req.text(),
      signature,
      c.env.STRIPE_WEBHOOK_SECRET,
      undefined,
      Stripe.createSubtleCryptoProvider(),
    );
  } catch {
    return c.text('Invalid signature', 400);
  }
  const seen = await queryOne<{ id: string }>(
    c.env.DB,
    'SELECT id FROM stripe_events WHERE id = ?',
    [event.id],
  );
  if (seen) return c.text('OK');
  try {
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object;
      const tenantId =
        session.client_reference_id ?? session.metadata?.tenant_id;
      const customerId =
        typeof session.customer === 'string'
          ? session.customer
          : session.customer?.id;
      if (tenantId && customerId) {
        await execute(
          c.env.DB,
          'UPDATE tenants SET stripe_customer_id = ?, updated_at = ? WHERE id = ?',
          [customerId, now(), tenantId],
        );
      }
      if (session.subscription) {
        const subscriptionId =
          typeof session.subscription === 'string'
            ? session.subscription
            : session.subscription.id;
        await applySubscription(
          c.env,
          await client(c.env).subscriptions.retrieve(subscriptionId),
        );
      }
    } else if (
      event.type === 'customer.subscription.created' ||
      event.type === 'customer.subscription.updated' ||
      event.type === 'customer.subscription.deleted'
    ) {
      await applySubscription(c.env, event.data.object);
    }
    await execute(
      c.env.DB,
      'INSERT INTO stripe_events (id, created_at) VALUES (?, ?)',
      [event.id, now()],
    );
    return c.text('OK');
  } catch {
    return c.text('Retry later', 500);
  }
});

export { billingRoutes };
