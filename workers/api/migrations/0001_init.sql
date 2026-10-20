-- Global tables
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'friends',
  access TEXT NOT NULL DEFAULT '[]',
  avatar_path TEXT,
  platform_role TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE tenants (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'active',
  plan_code TEXT NOT NULL DEFAULT 'early_access',
  subscription_status TEXT NOT NULL DEFAULT 'active',
  theme TEXT NOT NULL DEFAULT '{"primaryColor":"#9F4D4D","fontFamily":"nunitoSans"}',
  is_demo INTEGER NOT NULL DEFAULT 0,
  expires_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_tenants_status ON tenants(status);
CREATE INDEX idx_tenants_demo ON tenants(is_demo, expires_at);

CREATE TABLE memberships (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'member',
  relationship TEXT NOT NULL DEFAULT 'friends',
  access TEXT NOT NULL DEFAULT '[]',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (tenant_id, user_id)
);
CREATE INDEX idx_memberships_user ON memberships(user_id);
CREATE INDEX idx_memberships_tenant ON memberships(tenant_id, created_at);

CREATE TABLE invitations (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'member',
  relationship TEXT NOT NULL DEFAULT 'friends',
  access TEXT NOT NULL DEFAULT '[]',
  token_hash TEXT NOT NULL UNIQUE,
  expires_at INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  invited_by TEXT,
  accepted_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_invitations_tenant ON invitations(tenant_id, status, expires_at);
CREATE INDEX idx_invitations_email ON invitations(email);

CREATE TABLE auth_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  tenant_id TEXT,
  user_agent TEXT,
  expires_at INTEGER NOT NULL,
  revoked_at INTEGER,
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_sessions_user ON auth_sessions(user_id);
CREATE INDEX idx_sessions_expiry ON auth_sessions(expires_at);

-- Tenant-scoped tables
CREATE TABLE fotos (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  url TEXT NOT NULL,
  texto TEXT,
  album TEXT,
  tipo TEXT NOT NULL,
  data INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_fotos_tenant ON fotos(tenant_id, data DESC, created_at DESC);
CREATE INDEX idx_fotos_album ON fotos(tenant_id, album);

CREATE TABLE musicas (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  titulo TEXT NOT NULL,
  artista TEXT NOT NULL,
  link_spotify TEXT NOT NULL,
  descricao TEXT,
  momento TEXT NOT NULL,
  data INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_musicas_tenant ON musicas(tenant_id, data DESC);

CREATE TABLE cartas (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  tipo TEXT NOT NULL,
  titulo TEXT NOT NULL,
  conteudo TEXT NOT NULL,
  data INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_cartas_tenant ON cartas(tenant_id, tipo, data DESC);

CREATE TABLE notas (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  titulo TEXT NOT NULL,
  conteudo TEXT NOT NULL,
  data INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_notas_tenant ON notas(tenant_id, data DESC);

CREATE TABLE family_lists (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  created_by TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_lists_tenant ON family_lists(tenant_id, created_at DESC);

CREATE TABLE family_list_items (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  list_id TEXT NOT NULL,
  text TEXT NOT NULL,
  checked INTEGER NOT NULL DEFAULT 0,
  created_by TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_list_items_tenant ON family_list_items(tenant_id, list_id, created_at);

CREATE TABLE chat_conversations (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  participant_ids TEXT NOT NULL DEFAULT '[]',
  created_by TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_conversations_tenant ON chat_conversations(tenant_id, type, updated_at DESC);

CREATE TABLE chat_messages (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  sender_id TEXT,
  sender_name TEXT NOT NULL,
  text TEXT,
  media_url TEXT,
  media_type TEXT,
  reply_to_message_id TEXT,
  read_by TEXT NOT NULL DEFAULT '[]',
  delivered_by TEXT NOT NULL DEFAULT '[]',
  edited_at INTEGER,
  deleted_at INTEGER,
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_messages_conversation ON chat_messages(tenant_id, conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON chat_messages(tenant_id, sender_id, created_at DESC);

CREATE TABLE game_completions (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  game TEXT NOT NULL,
  player_name TEXT NOT NULL,
  user_id TEXT,
  score INTEGER,
  total INTEGER,
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_completions_tenant ON game_completions(tenant_id, game, created_at DESC);

CREATE TABLE game_words (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  word TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (tenant_id, word)
);

CREATE TABLE mini_game_configs (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  instructions TEXT NOT NULL DEFAULT '',
  items TEXT NOT NULL DEFAULT '[]',
  active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (tenant_id, type)
);

CREATE TABLE quiz_questions (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  question TEXT NOT NULL,
  options TEXT NOT NULL,
  correct_index INTEGER NOT NULL,
  active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_quiz_tenant ON quiz_questions(tenant_id, active);

CREATE TABLE home_settings (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  key TEXT NOT NULL DEFAULT 'home',
  events TEXT NOT NULL DEFAULT '[]',
  gallery_images TEXT NOT NULL DEFAULT '[]',
  gallery_order INTEGER,
  gallery_title TEXT DEFAULT 'Nossas memórias',
  gallery_title_visible INTEGER NOT NULL DEFAULT 1,
  gallery_title_layout TEXT NOT NULL DEFAULT 'arc',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (tenant_id, key)
);

CREATE TABLE location_updates (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT,
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
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_location_updates_latest ON location_updates(tenant_id, user_id, created_at DESC);

CREATE TABLE location_places (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  radius_meters INTEGER NOT NULL DEFAULT 120,
  active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_location_places ON location_places(tenant_id, active, name);

CREATE TABLE location_presences (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  place_id TEXT NOT NULL,
  inside INTEGER NOT NULL,
  user_name TEXT,
  place_name TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE (tenant_id, user_id, place_id)
);

CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  url TEXT NOT NULL DEFAULT '/',
  icon TEXT,
  type TEXT NOT NULL DEFAULT 'manual',
  read_by TEXT NOT NULL DEFAULT '[]',
  created_at INTEGER NOT NULL
);
CREATE INDEX idx_notifications_tenant ON notifications(tenant_id, created_at DESC);

CREATE TABLE push_subscriptions (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  fcm_token TEXT,
  user_id TEXT,
  platform TEXT NOT NULL DEFAULT 'unknown',
  user_agent TEXT,
  created_at INTEGER NOT NULL
);
CREATE UNIQUE INDEX idx_push_token ON push_subscriptions(tenant_id, fcm_token) WHERE fcm_token IS NOT NULL;

CREATE TABLE scheduled_notifications (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  url TEXT NOT NULL DEFAULT '/',
  scheduled_at INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  sent_at INTEGER,
  error TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_scheduled_due ON scheduled_notifications(status, scheduled_at);
