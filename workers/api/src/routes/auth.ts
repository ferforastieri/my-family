import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../env';
import { getCookie } from 'hono/cookie';
import {
  authMiddleware,
  demoRestricted,
  REFRESH_COOKIE,
  rotateCsrf,
  setSessionCookies,
  clearSessionCookies,
} from '../auth';
import {
  authenticateWithCode,
  listTenants,
  logout,
  refresh,
  requestCode,
  switchTenant,
  updateAvatar,
  updateProfile,
} from '../auth-service';
import { badRequest, envelope, parseBody } from '../http';
import { verifyTurnstile } from '../turnstile';
import { signedMediaUrl, serveMedia } from '../media';
import { createWsTicket } from '../ws-ticket';

const authRoutes = new Hono<AppEnv>();

const requestCodeSchema = z.object({
  phone: z.string().max(32),
  channel: z.enum(['whatsapp', 'sms']),
  turnstileToken: z.string().max(2048).optional(),
});

const verifyCodeSchema = z.object({
  phone: z.string().max(32),
  code: z.string().length(6),
  invitationToken: z.string().max(128).optional(),
  tenantSlug: z.string().max(48).optional(),
});

function publicSession<T extends { accessToken: string; refreshToken: string }>(session: T) {
  const { accessToken: _access, refreshToken: _refresh, ...rest } = session;
  void _access;
  void _refresh;
  return rest;
}

authRoutes.post('/phone/request-code', async (c) => {
  const dto = await parseBody(c, requestCodeSchema);
  await verifyTurnstile(c.env, dto.turnstileToken, c.req.header('cf-connecting-ip'), {
    required: false,
    action: 'phone',
  });
  const result = await requestCode(c.env, dto.phone, dto.channel);
  return envelope(c, {
    message: `Código enviado por ${dto.channel === 'whatsapp' ? 'WhatsApp' : 'SMS'}.`,
    ...result,
  });
});

authRoutes.post('/phone/verify-code', async (c) => {
  const dto = await parseBody(c, verifyCodeSchema);
  const session = await authenticateWithCode(c.env, {
    ...dto,
    userAgent: c.req.header('user-agent'),
  });
  const csrfToken = setSessionCookies(c, c.env, session.accessToken, session.refreshToken);
  c.header('Cache-Control', 'no-store');
  return envelope(c, {
    message: 'Celular confirmado.',
    ...publicSession(session),
    csrfToken,
  });
});

authRoutes.get('/csrf', (c) => {
  c.header('Cache-Control', 'no-store');
  return envelope(c, { csrfToken: rotateCsrf(c, c.env) });
});

authRoutes.post('/refresh', async (c) => {
  const session = await refresh(c.env, getCookie(c, REFRESH_COOKIE) ?? '', c.req.header('user-agent'));
  const csrfToken = setSessionCookies(c, c.env, session.accessToken, session.refreshToken);
  c.header('Cache-Control', 'no-store');
  return envelope(c, {
    message: 'Sessão renovada.',
    ...publicSession(session),
    csrfToken,
  });
});

authRoutes.post('/logout', async (c) => {
  await logout(c.env, getCookie(c, REFRESH_COOKIE) ?? '');
  clearSessionCookies(c, c.env);
  return envelope(c, { message: 'Sessão encerrada.' });
});

authRoutes.get('/me', authMiddleware, (c) => {
  const principal = c.get('principal');
  return envelope(c, { user: principal, tenant: principal.tenant });
});

authRoutes.get('/tenants', authMiddleware, async (c) => {
  const principal = c.get('principal');
  return envelope(c, { items: await listTenants(c.env, principal.id) });
});

authRoutes.post('/ws-ticket', authMiddleware, async (c) => {
  const principal = c.get('principal');
  const ticket = await createWsTicket(c.env, principal.id, principal.tenantId);
  return envelope(c, { ticket, expiresIn: 60 });
});

authRoutes.post('/switch-tenant', authMiddleware, async (c) => {
  const body = await parseBody(c, z.object({ tenantId: z.string().min(1, 'tenantId é obrigatório') }));
  const principal = c.get('principal');
  const session = await switchTenant(
    c.env,
    principal.id,
    body.tenantId,
    c.req.header('user-agent'),
  );
  const csrfToken = setSessionCookies(c, c.env, session.accessToken, session.refreshToken);
  return envelope(c, {
    message: 'Família alterada.',
    ...publicSession(session),
    csrfToken,
  });
});

authRoutes.patch('/me', authMiddleware, demoRestricted, async (c) => {
  const body = await parseBody(c, z.object({ name: z.string().max(120).optional() }));
  const principal = c.get('principal');
  const user = await updateProfile(c.env, principal.id, body);
  return envelope(c, {
    message: 'Perfil atualizado.',
    user: user
      ? {
          id: user.id,
          phoneNumber: user.phoneNumber,
          name: user.name,
          role: user.role,
          access: user.access,
          avatarPath: user.avatarPath,
        }
      : null,
  });
});

authRoutes.post('/avatar', authMiddleware, demoRestricted, async (c) => {
  const principal = c.get('principal');
  let form: FormData;
  try {
    form = await c.req.formData();
  } catch {
    throw badRequest('Nenhum arquivo enviado');
  }
  const file = form.get('file');
  if (!(file instanceof File)) throw badRequest('Nenhum arquivo enviado');
  const mime = file.type.toLowerCase();
  if (!/^image\/(jpeg|png|webp)$/.test(mime)) {
    throw badRequest('Tipo de arquivo não permitido');
  }
  if (file.size > 10_000_000) throw badRequest('Arquivo excede o limite permitido');
  const extension = mime === 'image/png' ? '.png' : mime === 'image/webp' ? '.webp' : '.jpg';
  const key = `tenants/${principal.tenantId}/avatar/${crypto.randomUUID()}${extension}`;
  await c.env.MEDIA.put(key, await file.arrayBuffer(), {
    httpMetadata: { contentType: mime },
  });
  const user = await updateAvatar(c.env, principal.id, key);
  return envelope(c, {
    message: 'Foto do perfil atualizada.',
    user: user
      ? {
          id: user.id,
          phoneNumber: user.phoneNumber,
          name: user.name,
          role: user.role,
          avatarPath: user.avatarPath,
        }
      : null,
  });
});

authRoutes.get('/avatar', authMiddleware, async (c) => {
  const principal = c.get('principal');
  const path = c.req.query('path');
  if (!path) throw badRequest('Caminho inválido');
  if (!path.startsWith(`tenants/${principal.tenantId}/avatar/`)) {
    throw badRequest('Caminho inválido');
  }
  const signed = await signedMediaUrl(c.env, path);
  if (signed) return c.redirect(signed, 302);
  return serveMedia(c.env, path);
});

export { authRoutes };
