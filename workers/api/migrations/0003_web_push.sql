ALTER TABLE push_subscriptions ADD COLUMN endpoint TEXT;
ALTER TABLE push_subscriptions ADD COLUMN p256dh TEXT;
ALTER TABLE push_subscriptions ADD COLUMN auth TEXT;
ALTER TABLE push_subscriptions ADD COLUMN kind TEXT NOT NULL DEFAULT 'fcm';
CREATE UNIQUE INDEX idx_push_endpoint ON push_subscriptions(endpoint) WHERE endpoint IS NOT NULL;
