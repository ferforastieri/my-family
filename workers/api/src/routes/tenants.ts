import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../env';
import {
  authMiddleware,
  demoRestricted,
  requirePlatformAdmin,
  requireTenantAdmin,
} from '../auth';
import {
  acceptInvitation,
  findTenantById,
  invite,
  listInvitations,
  member,
  members,
  removeMember,
  revokeInvitation,
  updateMember,
  updateTenant,
} from '../tenants';
import { badRequest, envelope, notFound, paginated, parseBody, queryInt } from '../http';
import { queryAll, queryOne } from '../db';
import { broadcastToTenant } from '../realtime-service';

const tenantRoutes = new Hono<AppEnv>();
tenantRoutes.use('*', authMiddleware);

tenantRoutes.get('/', async (c) => {
  const principal = c.get('principal');
  return envelope(c, await findTenantById(c.env, principal.tenantId));
});

tenantRoutes.patch('/', requireTenantAdmin, demoRestricted, async (c) => {
  const body = await parseBody(c, z.object({ name: z.string().max(120).optional() }));
  const principal = c.get('principal');
  return envelope(
    c,
    await updateTenant(c.env, principal.tenantId, {
      ...(body.name?.trim() ? { name: body.name.trim() } : {}),
    }),
  );
});



tenantRoutes.patch('/location', requireTenantAdmin, demoRestricted, async (c) => {
  const body = await parseBody(c, z.object({ enabled: z.boolean() }));
  const principal = c.get('principal');
  const tenant = await updateTenant(c.env, principal.tenantId, {
    locationEnabled: body.enabled,
  });
  if (!body.enabled) {
    await c.env.DB.batch([
      c.env.DB.prepare('DELETE FROM location_latest WHERE tenant_id = ?').bind(
        principal.tenantId,
      ),
      c.env.DB.prepare(
        'DELETE FROM location_presences WHERE tenant_id = ?',
      ).bind(principal.tenantId),
      c.env.DB.prepare('DELETE FROM location_tokens WHERE tenant_id = ?').bind(
        principal.tenantId,
      ),
    ]);
  }
  await broadcastToTenant(c.env, principal.tenantId, 'location.settings', {
    enabled: body.enabled,
  });
  return envelope(c, {
    message: body.enabled
      ? 'Localização ativada para a família.'
      : 'Localização desativada para a família.',
    ...(tenant ?? {}),
  });
});

tenantRoutes.get('/members', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  return envelope(c, await members(c.env, principal.tenantId));
});

tenantRoutes.get('/invitations', requireTenantAdmin, async (c) => {
  const principal = c.get('principal');
  return envelope(c, await listInvitations(c.env, principal.tenantId));
});

tenantRoutes.post('/invitations', requireTenantAdmin, demoRestricted, async (c) => {
  const body = await parseBody(
    c,
    z.object({
      email: z.string().email().max(200),
      role: z.enum(['admin', 'member']).optional(),
      relationship: z.enum(['husband', 'wife', 'children', 'friends']).optional(),
      access: z.array(z.string()).optional(),
    }),
  );
  const principal = c.get('principal');
  return envelope(c, await invite(c.env, principal.tenantId, principal.id, body));
});

tenantRoutes.delete('/invitations/:id', requireTenantAdmin, demoRestricted, async (c) => {
  const principal = c.get('principal');
  const ok = await revokeInvitation(c.env, principal.tenantId, c.req.param('id'));
  return envelope(c, { ok, message: ok ? 'Convite revogado.' : 'Convite não encontrado.' });
});

const invitationRoutes = new Hono<AppEnv>();
invitationRoutes.use('*', authMiddleware);
invitationRoutes.post('/:token/accept', async (c) => {
  const principal = c.get('principal');
  const tenant = await acceptInvitation(c.env, principal.id, c.req.param('token'));
  return envelope(c, tenant);
});

const userRoutes = new Hono<AppEnv>();
userRoutes.use('*', authMiddleware, requireTenantAdmin);

userRoutes.get('/', async (c) => {
  const principal = c.get('principal');
  const items = await members(c.env, principal.tenantId);
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 20, 100));
  return envelope(
    c,
    paginated(items.slice((page - 1) * limit, page * limit), items.length, page, limit),
  );
});

userRoutes.get('/:id', async (c) => {
  const principal = c.get('principal');
  const user = await member(c.env, principal.tenantId, c.req.param('id'));
  if (!user) throw notFound('Usuário não encontrado');
  return envelope(c, user);
});

userRoutes.patch('/:id', demoRestricted, async (c) => {
  const body = await parseBody(
    c,
    z.object({
      membershipRole: z.enum(['admin', 'member']).optional(),
      role: z.enum(['husband', 'wife', 'children', 'friends']).optional(),
      access: z.array(z.string()).optional(),
    }),
  );
  const principal = c.get('principal');
  const user = await updateMember(
    c.env,
    principal.tenantId,
    principal.id,
    c.req.param('id'),
    body,
  );
  if (!user) throw notFound('Usuário não encontrado');
  return envelope(c, { message: 'Usuário atualizado.', ...user });
});

userRoutes.delete('/:id', demoRestricted, async (c) => {
  const principal = c.get('principal');
  const ok = await removeMember(
    c.env,
    principal.tenantId,
    principal.id,
    c.req.param('id'),
  );
  if (!ok) throw notFound('Usuário não encontrado');
  return envelope(c, { ok, message: 'Usuário removido.' });
});

const platformRoutes = new Hono<AppEnv>();
platformRoutes.use('*', authMiddleware, requirePlatformAdmin);

platformRoutes.get('/tenants', async (c) => {
  const page = queryInt(c.req.query('page'), 1, 100000);
  const limit = Math.min(100, queryInt(c.req.query('limit'), 20, 100));
  const offset = (page - 1) * limit;
  const [rows, total] = await Promise.all([
    queryAll<{
      id: string;
      name: string;
      slug: string;
      status: string;
      plan_code: string;
      subscription_status: string;
      is_demo: number;
      expires_at: number | null;
      created_at: number;
    }>(
      c.env.DB,
      `SELECT id, name, slug, status, plan_code, subscription_status, is_demo, expires_at, created_at
         FROM tenants WHERE status <> 'deleted'
         ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [limit, offset],
    ),
    queryOne<{ count: number }>(
      c.env.DB,
      `SELECT COUNT(*) AS count FROM tenants WHERE status <> 'deleted'`,
    ),
  ]);
  return envelope(
    c,
    paginated(
      rows.map((row) => ({
        id: row.id,
        name: row.name,
        slug: row.slug,
        status: row.status,
        planCode: row.plan_code,
        subscriptionStatus: row.subscription_status,
        isDemo: row.is_demo === 1,
        expiresAt: row.expires_at ? new Date(row.expires_at).toISOString() : null,
        createdAt: new Date(row.created_at).toISOString(),
      })),
      total?.count ?? 0,
      page,
      limit,
    ),
  );
});

platformRoutes.patch('/tenants/:id/status', async (c) => {
  const body = await parseBody(c, z.object({ status: z.enum(['active', 'suspended']) }));
  const tenant = await updateTenant(c.env, c.req.param('id'), { status: body.status });
  if (!tenant) throw notFound('Família não encontrada.');
  return envelope(c, tenant);
});

export { tenantRoutes, invitationRoutes, userRoutes, platformRoutes };
