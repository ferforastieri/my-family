import type { Env, JobMessage } from './env';
import { execute, now, queryAll, queryOne } from './db';
import { broadcastToTenant } from './realtime-service';
import { sendPushToTenant } from './push';

interface NotificationRow {
  id: string;
  tenant_id: string;
  title: string;
  body: string;
  url: string;
  icon: string | null;
  type: string;
  read_by: string;
  created_at: number;
}

export async function sendNotification(
  env: Env,
  tenantId: string,
  input: {
    title: string;
    body?: string;
    url?: string;
    icon?: string;
    type?: string;
    excludeUserIds?: string[];
  },
) {
  if (!input.title?.trim()) throw new Error('title é obrigatório');
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    env.DB,
    `INSERT INTO notifications (id, tenant_id, title, body, url, icon, type, read_by, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, '[]', ?)`,
    [
      id,
      tenantId,
      input.title.trim(),
      input.body?.trim() ?? '',
      input.url?.trim() || '/',
      input.icon ?? null,
      input.type ?? 'manual',
      timestamp,
    ],
  );
  const row: NotificationRow = {
    id,
    tenant_id: tenantId,
    title: input.title.trim(),
    body: input.body?.trim() ?? '',
    url: input.url?.trim() || '/',
    icon: input.icon ?? null,
    type: input.type ?? 'manual',
    read_by: '[]',
    created_at: timestamp,
  };
  await broadcastToTenant(env, tenantId, 'notifications.created', {
    id: row.id,
    title: row.title,
    body: row.body,
    url: row.url,
    icon: row.icon,
    type: row.type,
    readBy: [],
    createdAt: new Date(row.created_at).toISOString(),
  });
  const push = await sendPushToTenant(
    env,
    tenantId,
    {
      title: row.title,
      body: row.body,
      url: row.url,
      type: row.type,
      includeNotification: true,
    },
    input.excludeUserIds ?? [],
  );
  return { ...row, sent: push.sent };
}

export async function handleJob(env: Env, message: JobMessage): Promise<void> {
  switch (message.type) {
    case 'notification.send':
      await sendNotification(env, message.tenantId, message);
      return;
    case 'notification.scheduled':
      await processScheduledNotification(env, message.scheduledNotificationId);
      return;
    case 'session.cleanup':
      await purgeExpired(env);
      return;
    case 'demo.cleanup':
      await cleanupDemos(env);
      return;
    default:
      return;
  }
}

async function processScheduledNotification(env: Env, id: string): Promise<void> {
  const row = await queryOne<{
    id: string;
    tenant_id: string;
    title: string;
    body: string;
    url: string;
    status: string;
    scheduled_at: number;
  }>(env.DB, 'SELECT * FROM scheduled_notifications WHERE id = ?', [id]);
  if (!row || row.status !== 'pending' || row.scheduled_at > Date.now()) return;
  try {
    await sendNotification(env, row.tenant_id, {
      title: row.title,
      body: row.body,
      url: row.url,
      type: 'manual',
    });
    await execute(
      env.DB,
      `UPDATE scheduled_notifications SET status = 'sent', sent_at = ?, updated_at = ? WHERE id = ?`,
      [now(), now(), id],
    );
  } catch (error) {
    await execute(
      env.DB,
      `UPDATE scheduled_notifications SET status = 'failed', error = ?, updated_at = ? WHERE id = ?`,
      [error instanceof Error ? error.message : 'erro desconhecido', now(), id],
    );
  }
}

export async function handleScheduled(env: Env): Promise<void> {
  const due = await queryAll<{ id: string }>(
    env.DB,
    `SELECT id FROM scheduled_notifications
      WHERE status = 'pending' AND scheduled_at <= ?
      ORDER BY scheduled_at ASC LIMIT 100`,
    [now()],
  );
  for (const row of due) {
    await processScheduledNotification(env, row.id);
  }
  await purgeExpired(env);
  await cleanupDemos(env);
}

export async function purgeExpired(env: Env): Promise<void> {
  const timestamp = now();
  await env.DB.batch([
    env.DB.prepare('DELETE FROM auth_sessions WHERE expires_at < ?').bind(timestamp),
    env.DB.prepare(
      `DELETE FROM notifications WHERE created_at < ?`,
    ).bind(timestamp - 180 * 24 * 60 * 60 * 1000),
    env.DB.prepare('DELETE FROM ws_tickets WHERE expires_at < ?').bind(timestamp),
  ]);
}

export async function cleanupDemos(env: Env): Promise<void> {
  const expired = await queryAll<{ id: string }>(
    env.DB,
    `SELECT id FROM tenants WHERE is_demo = 1 AND expires_at IS NOT NULL AND expires_at <= ?`,
    [now()],
  );
  for (const tenant of expired) {
    await deleteTenantFiles(env, tenant.id);
    await env.DB.batch([
      ...tenantTables.map((table) =>
        env.DB.prepare(`DELETE FROM ${table} WHERE tenant_id = ?`).bind(tenant.id),
      ),
      env.DB.prepare('DELETE FROM memberships WHERE tenant_id = ?').bind(tenant.id),
      env.DB.prepare('DELETE FROM invitations WHERE tenant_id = ?').bind(tenant.id),
      env.DB.prepare('DELETE FROM auth_sessions WHERE tenant_id = ?').bind(tenant.id),
      env.DB.prepare('DELETE FROM tenants WHERE id = ?').bind(tenant.id),
      env.DB.prepare(
        `DELETE FROM users WHERE email LIKE 'demo-%@nossafamilia.local' AND id NOT IN (SELECT user_id FROM memberships)`,
      ),
    ]);
  }
}

const tenantTables = [
  'fotos',
  'musicas',
  'cartas',
  'notas',
  'family_lists',
  'family_list_items',
  'chat_conversations',
  'chat_messages',
  'game_completions',
  'game_words',
  'mini_game_configs',
  'quiz_questions',
  'home_settings',
  'location_updates',
  'location_places',
  'location_presences',
  'notifications',
  'push_subscriptions',
  'scheduled_notifications',
];

async function deleteTenantFiles(env: Env, tenantId: string): Promise<void> {
  for (const prefix of [`tenants/${tenantId}/`, `quarantine/${tenantId}/`]) {
    let cursor: string | undefined;
    do {
      const page = await env.MEDIA.list({ prefix, cursor });
      if (page.objects.length) {
        await env.MEDIA.delete(page.objects.map((object) => object.key));
      }
      cursor = page.truncated ? page.cursor : undefined;
    } while (cursor);
  }
}
