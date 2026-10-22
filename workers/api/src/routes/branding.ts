import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../env';
import {
  authMiddleware,
  demoRestricted,
  requirePlatformAdmin,
  requireTenantAdmin,
} from '../auth';
import { badRequest, envelope, parseBody } from '../http';
import { execute, now, queryOne } from '../db';

interface SettingsRow {
  terms: string;
  privacy: string;
  logo_path: string | null;
  logo_updated_at: number | null;
  updated_at: number;
}

interface LogoRow {
  logo_path: string | null;
  logo_updated_at: number | null;
}

const allowedImages = /^image\/(png|jpe?g|webp)$/i;
const maxLogoSize = 8_000_000;

async function settings(env: AppEnv['Bindings']): Promise<SettingsRow> {
  const row = await queryOne<SettingsRow>(
    env.DB,
    'SELECT terms, privacy, logo_path, logo_updated_at, updated_at FROM platform_settings WHERE id = 1',
  );
  return (
    row ?? {
      terms: '',
      privacy: '',
      logo_path: null,
      logo_updated_at: null,
      updated_at: 0,
    }
  );
}

async function imageFromR2(
  c: { env: AppEnv['Bindings'] },
  path: string | null,
  cache: string,
) {
  if (!path) return null;
  const object = await c.env.MEDIA.get(path);
  if (!object) return null;
  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('cache-control', cache);
  headers.set('x-content-type-options', 'nosniff');
  headers.set('cross-origin-resource-policy', 'cross-origin');
  return new Response(object.body, { headers });
}

async function storeLogo(
  c: { env: AppEnv['Bindings'] },
  form: FormData,
  keyPrefix: string,
): Promise<{ key: string; version: number }> {
  const file = form.get('file');
  if (!(file instanceof File)) throw badRequest('Envie uma imagem.');
  if (!allowedImages.test(file.type)) {
    throw badRequest('Use uma imagem PNG, JPG ou WebP.');
  }
  if (file.size > maxLogoSize) {
    throw badRequest('A imagem deve ter no máximo 8 MB.');
  }
  const extension = file.type === 'image/png'
    ? '.png'
    : file.type === 'image/webp'
      ? '.webp'
      : '.jpg';
  const key = `${keyPrefix}/${crypto.randomUUID()}${extension}`;
  await c.env.MEDIA.put(key, await file.arrayBuffer(), {
    httpMetadata: { contentType: file.type },
  });
  return { key, version: now() };
}

async function deleteOldLogo(env: AppEnv['Bindings'], path: string | null) {
  if (path) await env.MEDIA.delete(path).catch(() => undefined);
}

const publicRoutes = new Hono<AppEnv>();

publicRoutes.get('/branding/logo', async (c) => {
  const row = await settings(c.env);
  const image = await imageFromR2(c, row.logo_path, 'no-cache');
  return image ?? c.redirect('/assets/family-logo.png', 302);
});

publicRoutes.get('/legal', async (c) => {
  const row = await settings(c.env);
  c.header('Cache-Control', 'no-cache');
  return envelope(c, {
    terms: row.terms,
    privacy: row.privacy,
    updatedAt: new Date(row.updated_at).toISOString(),
  });
});

const tenantBrandingRoutes = new Hono<AppEnv>();
tenantBrandingRoutes.use('*', authMiddleware);

tenantBrandingRoutes.get('/logo', async (c) => {
  const principal = c.get('principal');
  const row = await queryOne<LogoRow>(
    c.env.DB,
    'SELECT logo_path, logo_updated_at FROM tenants WHERE id = ?',
    [principal.tenantId],
  );
  const image = await imageFromR2(
    c,
    row?.logo_path ?? null,
    'private, max-age=300',
  );
  return image ?? c.redirect('/api/public/branding/logo', 302);
});

tenantBrandingRoutes.post(
  '/logo',
  requireTenantAdmin,
  demoRestricted,
  async (c) => {
    const principal = c.get('principal');
    const form = await c.req.formData();
    const logo = await storeLogo(
      c,
      form,
      `tenants/${principal.tenantId}/branding/logo`,
    );
    const old = await queryOne<LogoRow>(
      c.env.DB,
      'SELECT logo_path FROM tenants WHERE id = ?',
      [principal.tenantId],
    );
    await execute(
      c.env.DB,
      'UPDATE tenants SET logo_path = ?, logo_updated_at = ?, updated_at = ? WHERE id = ?',
      [logo.key, logo.version, logo.version, principal.tenantId],
    );
    await deleteOldLogo(c.env, old?.logo_path ?? null);
    return envelope(c, {
      message: 'Logo da família atualizado.',
      version: logo.version,
    });
  },
);

const platformBrandingRoutes = new Hono<AppEnv>();
platformBrandingRoutes.use('*', authMiddleware, requirePlatformAdmin);

platformBrandingRoutes.get('/settings', async (c) => {
  const row = await settings(c.env);
  return envelope(c, {
    terms: row.terms,
    privacy: row.privacy,
    logoVersion: row.logo_updated_at,
    updatedAt: new Date(row.updated_at).toISOString(),
  });
});

platformBrandingRoutes.put('/settings', async (c) => {
  const body = await parseBody(
    c,
    z.object({
      terms: z.string().max(50000).optional(),
      privacy: z.string().max(50000).optional(),
    }),
  );
  const current = await settings(c.env);
  await execute(
    c.env.DB,
    'UPDATE platform_settings SET terms = ?, privacy = ?, updated_at = ? WHERE id = 1',
    [
      body.terms ?? current.terms,
      body.privacy ?? current.privacy,
      now(),
    ],
  );
  return envelope(c, { message: 'Conteúdo legal atualizado.' });
});

platformBrandingRoutes.post('/logo', async (c) => {
  const form = await c.req.formData();
  const logo = await storeLogo(c, form, 'platform/branding/logo');
  const current = await settings(c.env);
  await execute(
    c.env.DB,
    'UPDATE platform_settings SET logo_path = ?, logo_updated_at = ?, updated_at = ? WHERE id = 1',
    [logo.key, logo.version, now()],
  );
  await deleteOldLogo(c.env, current.logo_path);
  return envelope(c, {
    message: 'Logo global atualizado.',
    version: logo.version,
  });
});

export { publicRoutes as publicBrandingRoutes, tenantBrandingRoutes, platformBrandingRoutes };
