import { Hono } from 'hono';
import { secureHeaders } from 'hono/secure-headers';
import { getCookie } from 'hono/cookie';
import type { AppEnv, Env, JobMessage } from './env';
import { corsOrigins } from './env';
import { CSRF_COOKIE, authMiddleware, constantTimeEqual, loadPrincipal, principalFromRequest } from './auth';
import { ApiError, errorResponse, unauthorized } from './http';
import { authRoutes } from './routes/auth';
import {
  invitationRoutes,
  platformRoutes,
  tenantRoutes,
  userRoutes,
} from './routes/tenants';
import {
  cartaRoutes,
  homeRoutes,
  listsRoutes,
  musicasRoutes,
  notasRoutes,
} from './routes/content';
import { fotosRoutes, uploadsRoutes } from './routes/fotos';
import { notificationsRoutes } from './routes/notifications';
import { locationRoutes } from './routes/location';
import { gamesRoutes } from './routes/games';
import { demoRoutes } from './routes/demo';
import { TenantRealtime } from './durable/realtime';
import { RateLimiter } from './durable/rate-limit';
import { handleJob, handleScheduled } from './jobs';
import { queryOne } from './db';
import { consumeWsTicket } from './ws-ticket';

const app = new Hono<AppEnv>();

app.use('*', async (c, next) => {
  c.set('requestId', crypto.randomUUID());
  await next();
  c.header('x-request-id', c.get('requestId'));
});

app.use('/api/*', secureHeaders({ crossOriginResourcePolicy: 'cross-origin' }));

app.use('/api/*', async (c, next) => {
  const origin = c.req.header('origin');
  const allowed = corsOrigins(c.env);
  if (origin && allowed.includes(origin)) {
    c.header('Access-Control-Allow-Origin', origin);
    c.header('Access-Control-Allow-Credentials', 'true');
    c.header('Vary', 'Origin');
  }
  if (c.req.method === 'OPTIONS') {
    c.header('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS');
    c.header('Access-Control-Allow-Headers', 'Content-Type, X-CSRF-Token, Last-Event-ID');
    c.header('Access-Control-Max-Age', '86400');
    return c.body(null, 204);
  }
  await next();
});

const publicPosts = new Set([
  '/api/auth/register',
  '/api/auth/login',
  '/api/public/demo-sessions',
]);

app.use('/api/*', async (c, next) => {
  if (['GET', 'HEAD', 'OPTIONS'].includes(c.req.method)) return next();
  if (publicPosts.has(c.req.path)) return next();
  if (c.req.path.startsWith('/api/uploads/')) return next();
  const cookie = getCookie(c, CSRF_COOKIE);
  const header = c.req.header('x-csrf-token');
  if (!cookie || !header || !constantTimeEqual(cookie, header)) {
    throw new ApiError(403, 'Token CSRF inválido ou ausente.', 'ForbiddenException');
  }
  await next();
});

app.use('/api/*', async (c, next) => {
  const isAuth = c.req.path === '/api/auth/login' || c.req.path === '/api/auth/register';
  const limit = isAuth ? 10 : Number(c.env.THROTTLE_LIMIT ?? 120);
  const windowMs = Number(c.env.THROTTLE_TTL_MS ?? 60000);
  if (!Number.isFinite(limit) || limit <= 0 || !Number.isFinite(windowMs) || windowMs <= 0) {
    return next();
  }
  const ip = c.req.header('cf-connecting-ip') ?? 'unknown';
  const stub = c.env.RATE_LIMITER.get(c.env.RATE_LIMITER.idFromName(ip)) as DurableObjectStub & {
    hit: (key: string, limit: number, windowMs: number) => Promise<{
      allowed: boolean;
      remaining: number;
      retryAfter: number;
    }>;
  };
  const result = await stub.hit(c.req.path, limit, windowMs);
  if (!result.allowed) {
    c.header('Retry-After', String(result.retryAfter));
    throw new ApiError(429, 'Muitas tentativas. Aguarde um pouco e tente novamente.');
  }
  await next();
});

app.get('/api/health', (c) =>
  c.json({ ok: true, process: 'api', timestamp: new Date().toISOString() }),
);

app.get('/api/health/live', (c) =>
  c.json({ ok: true, process: 'api', timestamp: new Date().toISOString() }),
);

app.get('/api/health/ready', async (c) => {
  try {
    await queryOne(c.env.DB, 'SELECT 1 AS ok');
    return c.json({ ok: true, d1: 'up', timestamp: new Date().toISOString() });
  } catch (error) {
    return c.json(
      {
        ok: false,
        message: error instanceof Error ? error.message : 'Banco indisponível',
        timestamp: new Date().toISOString(),
      },
      503,
    );
  }
});

app.route('/api/auth', authRoutes);
app.route('/api/tenant', tenantRoutes);
app.route('/api/invitations', invitationRoutes);
app.route('/api/users', userRoutes);
app.route('/api/platform', platformRoutes);
app.route('/api/notas', notasRoutes);
app.route('/api/cartas', cartaRoutes('letter', 'cartas'));
app.route('/api/journey', cartaRoutes('journey', 'nossaHistoria'));
app.route('/api/musicas', musicasRoutes);
app.route('/api/lists', listsRoutes);
app.route('/api/home/settings', homeRoutes);
app.route('/api/fotos', fotosRoutes);
app.route('/api/uploads', uploadsRoutes);
app.route('/api/notifications', notificationsRoutes);
app.route('/api/location', locationRoutes);
app.route('/api/games', gamesRoutes);
app.route('/api/public/demo-sessions', demoRoutes);

app.get('/ws', async (c) => {
  const ticket = c.req.query('ticket');
  let principal;
  if (ticket) {
    const consumed = await consumeWsTicket(c.env, ticket);
    if (!consumed) throw unauthorized('Ticket inválido ou expirado.');
    principal = await loadPrincipal(c.env, consumed.user_id, consumed.tenant_id);
    if (!principal) throw unauthorized('Sessão inválida.');
  } else {
    principal = await principalFromRequest(c);
  }
  const forward = new Request(c.req.raw);
  forward.headers.set('x-user-id', principal.id);
  forward.headers.set('x-tenant-id', principal.tenantId);
  forward.headers.set('x-user-name', encodeURIComponent(principal.name ?? principal.email));
  forward.headers.set('x-user-role', principal.role);
  forward.headers.set('x-user-access', principal.access.join(','));
  forward.headers.set('x-user-admin', principal.membershipRole === 'owner' || principal.membershipRole === 'admin' ? '1' : '0');
  const stub = c.env.REALTIME.get(c.env.REALTIME.idFromName(principal.tenantId));
  return stub.fetch(forward);
});

app.notFound((c) =>
  c.json(
    {
      ok: false,
      message: 'Rota não encontrada.',
      error: 'NotFoundException',
      statusCode: 404,
      timestamp: new Date().toISOString(),
    },
    404,
  ),
);

app.onError((error, c) => errorResponse(c, error));

export { TenantRealtime, RateLimiter };

export default {
  fetch: app.fetch,
  async queue(batch: MessageBatch<unknown>, env: Env): Promise<void> {
    for (const message of batch.messages) {
      try {
        await handleJob(env, message.body as JobMessage);
        message.ack();
      } catch (error) {
        console.error(
          JSON.stringify({
            level: 'error',
            message: 'Falha ao processar job',
            job: (message.body as JobMessage).type,
            error: error instanceof Error ? error.message : String(error),
          }),
        );
        message.retry();
      }
    }
  },
  async scheduled(_controller: ScheduledController, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(handleScheduled(env));
  },
} satisfies ExportedHandler<Env>;
