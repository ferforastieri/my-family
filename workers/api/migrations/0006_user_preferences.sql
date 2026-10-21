CREATE TABLE IF NOT EXISTS user_preferences (
  user_id TEXT PRIMARY KEY,
  primary_color TEXT,
  font_family TEXT,
  theme_mode TEXT NOT NULL DEFAULT 'light',
  home_scene TEXT NOT NULL DEFAULT 'flowers',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON user_preferences(user_id);
