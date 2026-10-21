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
  listTenants,
  login,
  logout,
  refresh,
  register,
  switchTenant,
  updateAvatar,
  updateProfile,
} from '../auth-service';
import { badRequest, envelope, parseBody } from '../http';
import { verifyTurnstile } from '../turnstile';
import { signedMediaUrl, serveMedia } from '../media';
import { createWsTicket } from '../ws-ticket';
import { createLocationToken } from '../location-token';
import { execute, now, queryOne } from '../db';

const authRoutes = new Hono<AppEnv>();

const registerSchema = z.object({
  name: z.string().min(1).max(120),
  email: z.string().email().max(200),
  password: z.string().min(8).max(200),
  invitationToken: z.string().max(128).optional(),
  tenantSlug: z.string().max(48).optional(),
  turnstileToken: z.string().max(2048).optional(),
});

const loginSchema = z.object({
  email: z.string().email().max(200),
  password: z.string().min(1).max(200),
  tenantSlug: z.string().max(48).optional(),
  turnstileToken: z.string().max(2048).optional(),
});

function publicSession<T extends { accessToken: string; refreshToken: string }>(session: T) {
  const { accessToken: _access, refreshToken: _refresh, ...rest } = session;
  void _access;
  void _refresh;
  return rest;
}

authRoutes.post('/register', async (c) => {
  const dto = await parseBody(c, registerSchema);
  await verifyTurnstile(c.env, dto.turnstileToken, c.req.header('cf-connecting-ip'), {
    required: false,
    action: 'auth',
  });
  const session = await register(c.env, {
    ...dto,
    userAgent: c.req.header('user-agent'),
  });
  const csrfToken = setSessionCookies(c, c.env, session.accessToken, session.refreshToken);
  c.header('Cache-Control', 'no-store');
  return envelope(c, {
    message: 'Conta criada.',
    ...publicSession(session),
    csrfToken,
  });
});

authRoutes.post('/login', async (c) => {
  const dto = await parseBody(c, loginSchema);
  await verifyTurnstile(c.env, dto.turnstileToken, c.req.header('cf-connecting-ip'), {
    required: false,
    action: 'auth',
  });
  const session = await login(c.env, {
    ...dto,
    userAgent: c.req.header('user-agent'),
  });
  const csrfToken = setSessionCookies(c, c.env, session.accessToken, session.refreshToken);
  c.header('Cache-Control', 'no-store');
  return envelope(c, {
    message: 'Login realizado.',
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

authRoutes.post('/location-token', authMiddleware, async (c) => {
  const principal = c.get('principal');
  const token = await createLocationToken(c.env, principal.id, principal.tenantId);
  return envelope(c, { token, expiresIn: 30 * 24 * 60 * 60 });
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
          email: user.email,
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
          email: user.email,
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

const preferencesSchema = z
  .object({
    primaryColor: z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional(),
    fontFamily: z.enum(['nunitoSans', 'cormorantGaramond']).optional(),
    themeMode: z.enum(['light', 'dark']).optional(),
    homeScene: z.enum(['flowers', 'aurora', 'ocean', 'night']).optional(),
  })
  .refine(
    (value) =>
      value.primaryColor !== undefined ||
      value.fontFamily !== undefined ||
      value.themeMode !== undefined ||
      value.homeScene !== undefined,
    { message: 'Informe ao menos uma preferência.' },
  );

interface UserPreferencesRow {
  primary_color: string | null;
  font_family: string | null;
  theme_mode: string;
  home_scene: string;
}

function preferencesDto(row: UserPreferencesRow | null) {
  return {
    primaryColor: row?.primary_color ?? '#9F4D4D',
    fontFamily: row?.font_family ?? 'nunitoSans',
    themeMode: row?.theme_mode === 'dark' ? 'dark' : 'light',
    homeScene: row?.home_scene ?? 'flowers',
  };
}

authRoutes.get('/preferences', authMiddleware, async (c) => {
  const principal = c.get('principal');
  const row = await queryOne<UserPreferencesRow>(
    c.env.DB,
    'SELECT primary_color, font_family, theme_mode, home_scene FROM user_preferences WHERE user_id = ?',
    [principal.id],
  );
  return envelope(c, preferencesDto(row));
});

authRoutes.patch('/preferences', authMiddleware, async (c) => {
  const principal = c.get('principal');
  const body = await parseBody(c, preferencesSchema);
  const current = await queryOne<UserPreferencesRow>(
    c.env.DB,
    'SELECT primary_color, font_family, theme_mode, home_scene FROM user_preferences WHERE user_id = ?',
    [principal.id],
  );
  const merged = {
    primaryColor: body.primaryColor?.toUpperCase() ?? current?.primary_color ?? '#9F4D4D',
    fontFamily: body.fontFamily ?? current?.font_family ?? 'nunitoSans',
    themeMode: body.themeMode ?? current?.theme_mode ?? 'light',
    homeScene: body.homeScene ?? current?.home_scene ?? 'flowers',
  };
  const timestamp = now();
  await execute(
    c.env.DB,
    `INSERT INTO user_preferences (user_id, primary_color, font_family, theme_mode, home_scene, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(user_id) DO UPDATE SET
       primary_color = excluded.primary_color,
       font_family = excluded.font_family,
       theme_mode = excluded.theme_mode,
       home_scene = excluded.home_scene,
       updated_at = excluded.updated_at`,
    [
      principal.id,
      merged.primaryColor,
      merged.fontFamily,
      merged.themeMode,
      merged.homeScene,
      timestamp,
      timestamp,
    ],
  );
  return envelope(c, {
    message: 'Preferências atualizadas.',
    ...merged,
  });
});

export { authRoutes };
