import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../env';
import {
  authMiddleware,
  demoRestricted,
  isTenantAdmin,
  requireTenantAdmin,
} from '../auth';
import { badRequest, envelope, notFound, paginated, parseBody, queryInt } from '../http';
import { execute, jsonArray, now, queryAll, queryOne } from '../db';
import { broadcastToTenant } from '../realtime-service';
import { sendNotification } from '../jobs';

interface NotificationRow {
  id: string;
  title: string;
  body: string;
  url: string;
  icon: string | null;
  type: string;
  read_by: string;
  created_at: number;
}

function notificationDto(row: NotificationRow, userId?: string) {
  return {
    id: row.id,
    title: row.title,
    body: row.body,
    url: row.url,
    icon: row.icon,
    type: row.type,
    read: userId ? jsonArray(row.read_by).includes(userId) : false,
    at: row.created_at,
  };
}

const notificationSchema = z.object({
  title: z.string(),
  body: z.string().optional(),
  url: z.string().optional(),
  icon: z.string().optional(),
  type: z.enum(['manual', 'push', 'chat', 'location', 'letter', 'system']).optional(),
});

const notificationsRoutes = new Hono<AppEnv>();
notificationsRoutes.use('*', authMiddleware);

notificationsRoutes.get('/', async (c) => {
  const principal = c.get('principal');
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 30, 100));
  const type = c.req.query('type');
  const filter = type && ['manual', 'push', 'chat', 'location', 'letter', 'system'].includes(type)
    ? ' AND type = ?'
    : '';
  const params = type && filter ? [principal.tenantId, type] : [principal.tenantId];
  const [rows, total] = await Promise.all([
    queryAll<NotificationRow>(
      c.env.DB,
      `SELECT * FROM (
         SELECT *, ROW_NUMBER() OVER (PARTITION BY title, body, url, type ORDER BY created_at DESC) AS rn
           FROM notifications WHERE tenant_id = ?${filter}
       ) WHERE rn = 1 ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [...params, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      `SELECT COUNT(*) AS count FROM (
         SELECT 1 FROM notifications WHERE tenant_id = ?${filter} GROUP BY title, body, url, type
       )`,
      params,
    ),
  ]);
  return envelope(
    c,
    paginated(
      rows.map((row) => notificationDto(row, principal.id)),
      total?.count ?? 0,
      page,
      limit,
    ),
  );
});

notificationsRoutes.post('/subscribe', demoRestricted, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(
    c,
    z.object({
      subscription: z.object({
        token: z.string(),
        platform: z.enum(['web', 'android', 'ios', 'unknown']).optional(),
      }),
      userAgent: z.string().optional(),
    }),
  );
  const token = body.subscription.token;
  const existing = await queryOne<{ id: string }>(
    c.env.DB,
    'SELECT id FROM push_subscriptions WHERE tenant_id = ? AND fcm_token = ?',
    [principal.tenantId, token],
  );
  if (existing) {
    await execute(
      c.env.DB,
      'UPDATE push_subscriptions SET user_id = ?, platform = ?, user_agent = ? WHERE id = ?',
      [
        principal.id,
        body.subscription.platform ?? 'unknown',
        body.userAgent ?? c.req.header('user-agent') ?? null,
        existing.id,
      ],
    );
  } else {
    await execute(
      c.env.DB,
      `INSERT INTO push_subscriptions (id, tenant_id, fcm_token, user_id, platform, user_agent, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        crypto.randomUUID(),
        principal.tenantId,
        token,
        principal.id,
        body.subscription.platform ?? 'unknown',
        body.userAgent ?? c.req.header('user-agent') ?? null,
        now(),
      ],
    );
  }
  return envelope(c, { ok: true, message: 'Notificações ativadas.' });
});

notificationsRoutes.post('/unsubscribe', async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, z.object({ token: z.string() }));
  await execute(c.env.DB, 'DELETE FROM push_subscriptions WHERE tenant_id = ? AND fcm_token = ?', [
    principal.tenantId,
    body.token,
  ]);
  return envelope(c, { ok: true, message: 'Notificações desativadas.' });
});

notificationsRoutes.delete('/', async (c) => {
  const principal = c.get('principal');
  await execute(c.env.DB, 'DELETE FROM notifications WHERE tenant_id = ?', [principal.tenantId]);
  await broadcastToTenant(c.env, principal.tenantId, 'notifications.cleared', null);
  return envelope(c, { ok: true, message: 'Notificações limpas.' });
});

notificationsRoutes.patch('/read-all', async (c) => {
  const principal = c.get('principal');
  const result = await execute(
    c.env.DB,
    `UPDATE notifications
        SET read_by = json_insert(read_by, '$[#]', ?)
      WHERE tenant_id = ?
        AND NOT EXISTS (SELECT 1 FROM json_each(read_by) WHERE value = ?)`,
    [principal.id, principal.tenantId, principal.id],
  );
  return envelope(c, {
    ok: true,
    count: result.meta.changes ?? 0,
    message: 'Notificações lidas.',
  });
});

notificationsRoutes.get('/scheduled/list', requireTenantAdmin, demoRestricted, async (c) => {
  const principal = c.get('principal');
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 30, 100));
  const status = c.req.query('status');
  const filter = status ? ' AND status = ?' : '';
  const params = status ? [principal.tenantId, status] : [principal.tenantId];
  const [rows, total] = await Promise.all([
    queryAll<{
      id: string;
      title: string;
      body: string;
      url: string;
      scheduled_at: number;
      status: string;
      sent_at: number | null;
      error: string | null;
      created_at: number;
    }>(
      c.env.DB,
      `SELECT * FROM scheduled_notifications WHERE tenant_id = ?${filter}
       ORDER BY scheduled_at DESC LIMIT ? OFFSET ?`,
      [...params, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      `SELECT COUNT(*) AS count FROM scheduled_notifications WHERE tenant_id = ?${filter}`,
      params,
    ),
  ]);
  return envelope(
    c,
    paginated(
      rows.map((row) => ({
        id: row.id,
        title: row.title,
        body: row.body,
        url: row.url,
        scheduledAt: new Date(row.scheduled_at).toISOString(),
        status: row.status,
        sentAt: row.sent_at ? new Date(row.sent_at).toISOString() : null,
        error: row.error,
        createdAt: new Date(row.created_at).toISOString(),
      })),
      total?.count ?? 0,
      page,
      limit,
    ),
  );
});

notificationsRoutes.post('/schedule', requireTenantAdmin, demoRestricted, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(
    c,
    z.object({
      title: z.string(),
      body: z.string().optional(),
      url: z.string().optional(),
      scheduledAt: z.string(),
    }),
  );
  if (!body.title.trim()) throw badRequest('title é obrigatório');
  const scheduledAt = new Date(body.scheduledAt);
  if (Number.isNaN(scheduledAt.getTime())) throw badRequest('scheduledAt inválido');
  if (scheduledAt.getTime() <= Date.now()) throw badRequest('scheduledAt deve ser no futuro');
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO scheduled_notifications (id, tenant_id, title, body, url, scheduled_at, status, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?)`,
    [
      id,
      principal.tenantId,
      body.title.trim(),
      body.body?.trim() ?? '',
      body.url?.trim() || '/',
      scheduledAt.getTime(),
      timestamp,
      timestamp,
    ],
  );
  const payload = {
    id,
    scheduledAt: scheduledAt.toISOString(),
    delayMs: scheduledAt.getTime() - Date.now(),
  };
  await broadcastToTenant(
    c.env,
    principal.tenantId,
    'notifications.scheduled.changed',
    payload,
  );
  return envelope(c, { message: 'Notificação agendada.', ...payload });
});

notificationsRoutes.post('/send', requireTenantAdmin, demoRestricted, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(
    c,
    z.object({ title: z.string(), body: z.string().optional(), url: z.string().optional() }),
  );
  if (!body.title) throw badRequest('title é obrigatório');
  const row = await sendNotification(c.env, principal.tenantId, {
    title: body.title,
    body: body.body,
    url: body.url,
    type: 'push',
  });
  return envelope(c, {
    message: 'Notificação enviada.',
    ...notificationDto(row, principal.id),
    sent: row.sent,
  });
});

notificationsRoutes.delete('/scheduled/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const result = await execute(
    c.env.DB,
    'DELETE FROM scheduled_notifications WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  const ok = result.meta.changes === 1;
  if (ok) {
    await broadcastToTenant(c.env, principal.tenantId, 'notifications.scheduled.changed', {
      id: c.req.param('id'),
      deleted: true,
    });
  }
  return envelope(c, { ok, message: 'Agendamento removido.' });
});

notificationsRoutes.patch('/:id/read', async (c) => {
  const principal = c.get('principal');
  const id = c.req.param('id');
  await execute(
    c.env.DB,
    `UPDATE notifications
        SET read_by = json_insert(read_by, '$[#]', ?)
      WHERE tenant_id = ? AND id = ?
        AND NOT EXISTS (SELECT 1 FROM json_each(read_by) WHERE value = ?)`,
    [principal.id, principal.tenantId, id, principal.id],
  );
  const row = await queryOne<NotificationRow>(
    c.env.DB,
    'SELECT * FROM notifications WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, id],
  );
  if (!row) throw notFound('Notificação não encontrada');
  return envelope(c, { message: 'Notificação lida.', ...notificationDto(row, principal.id) });
});

notificationsRoutes.get('/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const row = await queryOne<NotificationRow>(
    c.env.DB,
    'SELECT * FROM notifications WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  if (!row) throw notFound('Notificação não encontrada');
  return envelope(c, notificationDto(row, principal.id));
});

notificationsRoutes.post('/', requireTenantAdmin, demoRestricted, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, notificationSchema);
  if (!body.title?.trim()) throw badRequest('title é obrigatório');
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO notifications (id, tenant_id, title, body, url, icon, type, read_by, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, '[]', ?)`,
    [
      id,
      principal.tenantId,
      body.title.trim(),
      body.body?.trim() ?? '',
      body.url?.trim() || '/',
      body.icon ?? null,
      body.type ?? 'manual',
      timestamp,
    ],
  );
  const row = (await queryOne<NotificationRow>(
    c.env.DB,
    'SELECT * FROM notifications WHERE id = ?',
    [id],
  ))!;
  const dto = notificationDto(row, principal.id);
  await broadcastToTenant(c.env, principal.tenantId, 'notifications.created', dto);
  return envelope(c, { message: 'Notificação salva.', ...dto });
});

notificationsRoutes.patch('/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, notificationSchema.partial());
  const sets: string[] = [];
  const params: unknown[] = [];
  if (body.title !== undefined) {
    sets.push('title = ?');
    params.push(body.title.trim());
  }
  if (body.body !== undefined) {
    sets.push('body = ?');
    params.push(body.body.trim());
  }
  if (body.url !== undefined) {
    sets.push('url = ?');
    params.push(body.url.trim() || '/');
  }
  if (body.icon !== undefined) {
    sets.push('icon = ?');
    params.push(body.icon || null);
  }
  if (body.type !== undefined) {
    sets.push('type = ?');
    params.push(body.type);
  }
  if (sets.length) {
    params.push(principal.tenantId, c.req.param('id'));
    await execute(
      c.env.DB,
      `UPDATE notifications SET ${sets.join(', ')} WHERE tenant_id = ? AND id = ?`,
      params,
    );
  }
  const row = await queryOne<NotificationRow>(
    c.env.DB,
    'SELECT * FROM notifications WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  if (!row) throw notFound('Notificação não encontrada');
  const dto = notificationDto(row, principal.id);
  await broadcastToTenant(c.env, principal.tenantId, 'notifications.updated', dto);
  return envelope(c, { message: 'Notificação atualizada.', ...dto });
});

notificationsRoutes.delete('/:id', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  const result = await execute(
    c.env.DB,
    'DELETE FROM notifications WHERE tenant_id = ? AND id = ?',
    [principal.tenantId, c.req.param('id')],
  );
  const ok = result.meta.changes === 1;
  if (!ok) throw notFound('Notificação não encontrada');
  await broadcastToTenant(c.env, principal.tenantId, 'notifications.deleted', {
    id: c.req.param('id'),
  });
  return envelope(c, { ok, message: 'Notificação removida.' });
});

export { notificationsRoutes };
