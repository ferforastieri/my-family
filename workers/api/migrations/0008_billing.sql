ALTER TABLE tenants ADD COLUMN stripe_customer_id TEXT;
ALTER TABLE tenants ADD COLUMN stripe_subscription_id TEXT;
ALTER TABLE tenants ADD COLUMN billing_interval TEXT;
ALTER TABLE tenants ADD COLUMN access_until INTEGER;
ALTER TABLE tenants ADD COLUMN subscription_ending_at INTEGER;

UPDATE tenants SET plan_code = 'free' WHERE plan_code = 'early_access';

CREATE TABLE IF NOT EXISTS plan_prices (
  plan TEXT PRIMARY KEY CHECK (plan IN ('monthly', 'yearly')),
  currency TEXT NOT NULL DEFAULT 'brl',
  amount_minor INTEGER NOT NULL,
  stripe_price_id TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1,
  updated_at INTEGER NOT NULL
);

INSERT OR REPLACE INTO plan_prices
  (plan, currency, amount_minor, stripe_price_id, active, updated_at)
VALUES
  ('monthly', 'brl', 3000, 'price_1UTRsoR7IysHnyW1MmtFuSs1', 1, strftime('%s','now') * 1000),
  ('yearly', 'brl', 30000, 'price_1UTRsqR7IysHnyW1YF1IwusZ', 1, strftime('%s','now') * 1000);

CREATE TABLE IF NOT EXISTS stripe_events (
  id TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL
);
