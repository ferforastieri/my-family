import { createMiddleware } from 'hono/factory';
import { deleteCookie, getCookie, setCookie } from 'hono/cookie';
import type { Context } from 'hono';
import { jwtVerify, SignJWT } from 'jose';
import type { AppEnv, Env } from './env';
import { isProduction } from './env';
import { queryOne } from './db';
import { forbidden, unauthorized } from './http';

export const ACCESS_COOKIE = 'siao_access';
export const REFRESH_COOKIE = 'siao_refresh';
export const CSRF_COOKIE = 'siao_csrf';

const ISSUER = 'siao-api';
const AUDIENCE = 'siao-app';
const encoder = new TextEncoder();

export const userAccessKeys = [
  'memorias',
  'playlist',
  'cartas',
  'jogos',
  'listas',
  'notas',
  'localizacao',
  'chat',
  'nossaHistoria',
] as const;
export type UserAccessKey = (typeof userAccessKeys)[number];

export const userRoles = ['husband', 'wife', 'children', 'friends'] as const;
export type UserRole = (typeof userRoles)[number];

export type MembershipRole = 'owner' | 'admin' | 'member';

export interface TenantEntity {
  id: string;
  name: string;
  slug: string;
  status: 'active' | 'suspended' | 'deleted';
  planCode: string;
  subscriptionStatus: 'active' | 'past_due' | 'cancelled';
  theme: { primaryColor: string; fontFamily: string };
  isDemo: boolean;
  locationEnabled: boolean;
  hasLogo: boolean;
  logoVersion: number | null;
  expiresAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface Principal {
  id: string;
  email: string;
  name: string | null;
  avatarPath: string | null;
  platformRole: 'super_admin' | null;
  tenantId: string;
  tenant: TenantEntity;
  membershipId: string;
  membershipRole: MembershipRole;
  role: UserRole;
  locationSharing: boolean;
  access: UserAccessKey[];
  isDemo: boolean;
  createdAt: string;
  updatedAt: string;
}

export function normalizeAccessKeys(access?: readonly string[] | null): UserAccessKey[] {
  if (!access?.length) return [];
  return [...new Set(access)].filter((key): key is UserAccessKey =>
    userAccessKeys.includes(key as UserAccessKey),
  );
}

export function isTenantAdmin(principal?: Pick<Principal, 'membershipRole'> | null) {
  return principal?.membershipRole === 'owner' || principal?.membershipRole === 'admin';
}

export async function hashToken(value: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', encoder.encode(value));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

export function randomToken(bytes = 32): string {
  const buffer = crypto.getRandomValues(new Uint8Array(bytes));
  return [...buffer].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

export function constantTimeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let mismatch = 0;
  for (let index = 0; index < left.length; index += 1) {
    mismatch |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return mismatch === 0;
}

export async function signAccessToken(
  env: Env,
  userId: string,
  tenantId?: string,
): Promise<string> {
  return new SignJWT({ ...(tenantId ? { tenantId } : {}) })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(userId)
    .setIssuer(ISSUER)
    .setAudience(AUDIENCE)
    .setIssuedAt()
    .setExpirationTime('15m')
    .sign(encoder.encode(env.JWT_SECRET));
}

export async function verifyAccessToken(
  env: Env,
  token: string,
): Promise<{ sub: string; tenantId?: string }> {
  const { payload } = await jwtVerify(token, encoder.encode(env.JWT_SECRET), {
    issuer: ISSUER,
    audience: AUDIENCE,
    algorithms: ['HS256'],
  });
  if (!payload.sub) throw new Error('Token sem subject');
  return {
    sub: payload.sub,
    tenantId: typeof payload.tenantId === 'string' ? payload.tenantId : undefined,
  };
}

function cookieSameSite(env: Env): 'Lax' | 'Strict' | 'None' {
  const value = (env.COOKIE_SAME_SITE ?? 'lax').toLowerCase();
  if (value === 'strict') return 'Strict';
  if (value === 'none') return 'None';
  return 'Lax';
}

function cookieSecure(env: Env): boolean {
  if (env.COOKIE_SECURE === 'true') return true;
  if (env.COOKIE_SECURE === 'false') return false;
  return isProduction(env);
}

export function rotateCsrf(c: Parameters<typeof setCookie>[0], env: Env): string {
  const token = randomToken(32);
  setCookie(c, CSRF_COOKIE, token, {
    httpOnly: false,
    secure: cookieSecure(env),
    sameSite: cookieSameSite(env),
    path: '/',
    maxAge: 90 * 24 * 60 * 60,
  });
  return token;
}

export function setSessionCookies(
  c: Parameters<typeof setCookie>[0],
  env: Env,
  accessToken: string,
  refreshToken: string,
): string {
  setCookie(c, ACCESS_COOKIE, accessToken, {
    httpOnly: true,
    secure: cookieSecure(env),
    sameSite: cookieSameSite(env),
    path: '/',
    maxAge: 15 * 60,
  });
  setCookie(c, REFRESH_COOKIE, refreshToken, {
    httpOnly: true,
    secure: cookieSecure(env),
    sameSite: cookieSameSite(env),
    path: '/',
    maxAge: 90 * 24 * 60 * 60,
  });
  return rotateCsrf(c, env);
}

export function clearSessionCookies(
  c: Parameters<typeof deleteCookie>[0],
  env: Env,
): void {
  const options = {
    secure: cookieSecure(env),
    sameSite: cookieSameSite(env),
    path: '/',
  } as const;
  deleteCookie(c, ACCESS_COOKIE, options);
  deleteCookie(c, REFRESH_COOKIE, options);
  deleteCookie(c, CSRF_COOKIE, options);
}

interface PrincipalRow {
  id: string;
  email: string;
  name: string | null;
  avatar_path: string | null;
  platform_role: string | null;
  user_created_at: number;
  user_updated_at: number;
  tenant_id: string;
  tenant_name: string;
  slug: string;
  tenant_status: string;
  plan_code: string;
  subscription_status: string;
  theme: string;
  is_demo: number;
  location_enabled: number;
  location_sharing: number;
  expires_at: number | null;
  tenant_logo_path: string | null;
  tenant_logo_updated_at: number | null;
  tenant_created_at: number;
  tenant_updated_at: number;
  membership_id: string;
  membership_role: string;
  relationship: string;
  membership_access: string;
}

export async function loadPrincipal(
  env: Env,
  userId: string,
  tenantId: string,
): Promise<Principal | null> {
  const row = await queryOne<PrincipalRow>(
    env.DB,
    `SELECT u.id, u.email, u.name, u.avatar_path, u.platform_role,
            u.created_at AS user_created_at, u.updated_at AS user_updated_at,
            t.id AS tenant_id, t.name AS tenant_name, t.slug,
            t.status AS tenant_status, t.plan_code, t.subscription_status,
            t.theme, t.is_demo, t.location_enabled,
            t.logo_path AS tenant_logo_path,
            t.logo_updated_at AS tenant_logo_updated_at,
            t.expires_at,
            t.created_at AS tenant_created_at, t.updated_at AS tenant_updated_at,
            m.id AS membership_id, m.role AS membership_role,
            m.relationship, m.access AS membership_access, m.location_sharing
       FROM users u
       JOIN memberships m ON m.user_id = u.id
       JOIN tenants t ON t.id = m.tenant_id
      WHERE u.id = ? AND m.tenant_id = ?`,
    [userId, tenantId],
  );
  if (!row) return null;
  if (row.tenant_status !== 'active') {
    throw forbidden('Este ambiente está indisponível.');
  }
  let theme: { primaryColor: string; fontFamily: string } = {
    primaryColor: '#9F4D4D',
    fontFamily: 'nunitoSans',
  };
  try {
    theme = { ...theme, ...JSON.parse(row.theme) };
  } catch {
    // keep default theme
  }
  const accessRaw = (() => {
    try {
      return JSON.parse(row.membership_access) as string[];
    } catch {
      return [];
    }
  })();
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    avatarPath: row.avatar_path,
    platformRole: row.platform_role === 'super_admin' ? 'super_admin' : null,
    tenantId: row.tenant_id,
    tenant: {
      id: row.tenant_id,
      name: row.tenant_name,
      slug: row.slug,
      status: row.tenant_status as TenantEntity['status'],
      planCode: row.plan_code,
      subscriptionStatus: row.subscription_status as TenantEntity['subscriptionStatus'],
      theme,
      isDemo: row.is_demo === 1,
      locationEnabled: row.location_enabled !== 0,
      hasLogo: Boolean(row.tenant_logo_path),
      logoVersion: row.tenant_logo_updated_at,
      expiresAt: row.expires_at ? new Date(row.expires_at).toISOString() : null,
      createdAt: new Date(row.tenant_created_at).toISOString(),
      updatedAt: new Date(row.tenant_updated_at).toISOString(),
    },
    membershipId: row.membership_id,
    membershipRole: row.membership_role as MembershipRole,
    role: row.relationship as UserRole,
    access: normalizeAccessKeys(accessRaw),
    locationSharing: row.location_sharing === 1,
    isDemo: row.is_demo === 1,
    createdAt: new Date(row.user_created_at).toISOString(),
    updatedAt: new Date(row.user_updated_at).toISOString(),
  };
}

export async function principalFromRequest(c: Context<AppEnv>): Promise<Principal> {
  const token = getCookie(c, ACCESS_COOKIE);
  if (!token) throw unauthorized();
  let payload: { sub: string; tenantId?: string };
  try {
    payload = await verifyAccessToken(c.env, token);
  } catch {
    throw unauthorized('Sessão expirada. Entre novamente.');
  }
  if (!payload.tenantId) throw forbidden('Contexto de família obrigatório.');
  const principal = await loadPrincipal(c.env, payload.sub, payload.tenantId);
  if (!principal) throw forbidden('Você não participa desta família.');
  return principal;
}

export const authMiddleware = createMiddleware<AppEnv>(async (c, next) => {
  c.set('principal', await principalFromRequest(c));
  await next();
});

export function requireAccess(key: UserAccessKey) {
  return createMiddleware<AppEnv>(async (c, next) => {
    const principal = c.get('principal');
    if (!principal) throw unauthorized();
    if (isTenantAdmin(principal) || principal.access.includes(key)) {
      await next();
      return;
    }
    throw forbidden('Acesso não liberado para este recurso.');
  });
}

export const requireTenantAdmin = createMiddleware<AppEnv>(async (c, next) => {
  const principal = c.get('principal');
  if (!principal) throw unauthorized();
  if (!isTenantAdmin(principal)) {
    throw forbidden('Apenas administradores da família podem fazer isso.');
  }
  await next();
});

export const requirePlatformAdmin = createMiddleware<AppEnv>(async (c, next) => {
  const principal = c.get('principal');
  if (!principal) throw unauthorized();
  if (principal.platformRole !== 'super_admin') {
    throw forbidden('Acesso restrito à plataforma.');
  }
  await next();
});

export const demoRestricted = createMiddleware<AppEnv>(async (c, next) => {
  const principal = c.get('principal');
  if (principal?.isDemo) {
    throw forbidden('Este recurso não está disponível na demonstração.');
  }
  await next();
});
