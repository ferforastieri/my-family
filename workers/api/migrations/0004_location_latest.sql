CREATE TABLE location_latest (
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  user_name TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  accuracy REAL,
  altitude REAL,
  speed REAL,
  heading REAL,
  battery_level INTEGER,
  is_charging INTEGER,
  platform TEXT NOT NULL DEFAULT 'unknown',
  last_battery_alert_at INTEGER,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (tenant_id, user_id)
);
CREATE INDEX idx_location_latest_updated ON location_latest(tenant_id, updated_at DESC);

INSERT OR REPLACE INTO location_latest (
  tenant_id, user_id, user_name, latitude, longitude, accuracy, altitude,
  speed, heading, battery_level, is_charging, platform, updated_at
)
SELECT
  tenant_id, user_id, user_name, latitude, longitude, accuracy, altitude,
  speed, heading, battery_level, is_charging, platform, created_at
FROM location_updates
WHERE user_id IS NOT NULL AND user_id <> ''
ORDER BY created_at ASC;

DROP TABLE IF EXISTS location_updates;

ALTER TABLE location_places ADD COLUMN notify_on_arrive INTEGER NOT NULL DEFAULT 1;
ALTER TABLE location_places ADD COLUMN notify_on_leave INTEGER NOT NULL DEFAULT 1;

CREATE TABLE location_tokens (
  token_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  expires_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_location_tokens_expiry ON location_tokens(expires_at);
CREATE INDEX idx_location_tokens_user ON location_tokens(user_id);
