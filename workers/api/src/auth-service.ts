import type { Env } from './env';
import { execute, jsonArray, now, queryOne } from './db';
import {
  hashToken,
  normalizeAccessKeys,
  type UserAccessKey,
  type UserRole,
} from './auth';
import { badRequest, conflict, notFound, unauthorized } from './http';
import { hashPassword, verifyPassword } from './password';
import { normalizeEmail } from './email';
import {
  acceptInvitation,
  consumeSession,
  createFamily,
  findTenantById,
  listMembershipsForUser,
  revokeSession,
  tenantIdForSlug,
  tenantPrincipal,
  tokenResponse,
} from './tenants';

export interface UserEntity {
  id: string;
  email: string;
  name: string | null;
  role: UserRole;
  access: UserAccessKey[];
  avatarPath: string | null;
  platformRole: 'super_admin' | null;
  createdAt: string;
  updatedAt: string;
  passwordHash: string;
}

interface UserRow {
  id: string;
  email: string;
  password_hash: string;
  name: string | null;
  role: string;
  access: string;
  avatar_path: string | null;
  platform_role: string | null;
  created_at: number;
  updated_at: number;
}

function userFromRow(row: UserRow): UserEntity {
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    role: row.role as UserRole,
    access: normalizeAccessKeys(jsonArray(row.access)),
    avatarPath: row.avatar_path,
    platformRole: row.platform_role === 'super_admin' ? 'super_admin' : null,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
    passwordHash: row.password_hash,
  };
}

export async function findUserById(env: Env, id: string): Promise<UserEntity | null> {
  const row = await queryOne<UserRow>(env.DB, 'SELECT * FROM users WHERE id = ?', [id]);
  return row ? userFromRow(row) : null;
}

export async function findUserByEmail(env: Env, email: string): Promise<UserEntity | null> {
  const row = await queryOne<UserRow>(env.DB, 'SELECT * FROM users WHERE email = ?', [email]);
  return row ? userFromRow(row) : null;
}

export async function createUser(
  env: Env,
  data: { email: string; password: string; name?: string; platformRole?: 'super_admin' },
): Promise<UserEntity> {
  const email = normalizeEmail(data.email);
  if (data.password.length < 8) {
    throw badRequest('A senha deve ter pelo menos 8 caracteres.');
  }
  if (await findUserByEmail(env, email)) {
    throw conflict('Este email já está cadastrado.');
  }
  const id = crypto.randomUUID();
  const timestamp = now();
  const passwordHash = await hashPassword(data.password);
  await execute(
    env.DB,
    `INSERT INTO users (id, email, password_hash, name, role, access, platform_role, created_at, updated_at)
     VALUES (?, ?, ?, ?, 'friends', '[]', ?, ?, ?)`,
    [
      id,
      email,
      passwordHash,
      data.name?.trim() || null,
      data.platformRole ?? null,
      timestamp,
      timestamp,
    ],
  );
  return (await findUserById(env, id))!;
}

export async function updateUser(
  env: Env,
  id: string,
  data: {
    name?: string;
    role?: UserRole;
    access?: UserAccessKey[];
    avatarPath?: string;
    platformRole?: 'super_admin';
  },
): Promise<UserEntity | null> {
  const sets: string[] = [];
  const params: unknown[] = [];
  if (data.name !== undefined) {
    sets.push('name = ?');
    params.push(data.name);
  }
  if (data.role !== undefined) {
    sets.push('role = ?');
    params.push(data.role);
  }
  if (data.access !== undefined) {
    sets.push('access = ?');
    params.push(JSON.stringify(normalizeAccessKeys(data.access)));
  }
  if (data.avatarPath !== undefined) {
    sets.push('avatar_path = ?');
    params.push(data.avatarPath);
  }
  if (data.platformRole !== undefined) {
    sets.push('platform_role = ?');
    params.push(data.platformRole);
  }
  if (sets.length) {
    sets.push('updated_at = ?');
    params.push(now(), id);
    await execute(env.DB, `UPDATE users SET ${sets.join(', ')} WHERE id = ?`, params);
  }
  return findUserById(env, id);
}

export async function deleteUser(env: Env, id: string): Promise<void> {
  await execute(env.DB, 'DELETE FROM users WHERE id = ?', [id]);
}

export async function register(
  env: Env,
  input: {
    name: string;
    email: string;
    password: string;
    invitationToken?: string;
    tenantSlug?: string;
    userAgent?: string;
  },
) {
  const email = normalizeEmail(input.email);
  const name = input.name?.trim();
  if (!name) throw badRequest('Informe seu nome.');
  const platformAdmin = env.PLATFORM_ADMIN_EMAIL
    ? normalizeEmail(env.PLATFORM_ADMIN_EMAIL)
    : null;
  const user = await createUser(env, {
    email,
    password: input.password,
    name,
    ...(platformAdmin === email ? { platformRole: 'super_admin' as const } : {}),
  });
  try {
    if (input.invitationToken) {
      const tenant = await acceptInvitation(env, user.id, input.invitationToken);
      return tokenResponse(env, user, tenant?.id, input.userAgent);
    }
    if (input.tenantSlug) {
      const tenantId = await tenantIdForSlug(env, user.id, input.tenantSlug);
      return tokenResponse(env, user, tenantId, input.userAgent);
    }
    const tenant = await createFamily(
      env,
      user.id,
      'Minha Família',
      `familia-${crypto.randomUUID().slice(0, 10)}`,
    );
    return tokenResponse(env, user, tenant.id, input.userAgent);
  } catch (error) {
    await deleteUser(env, user.id);
    throw error;
  }
}

export async function login(
  env: Env,
  input: { email: string; password: string; tenantSlug?: string; userAgent?: string },
) {
  const email = normalizeEmail(input.email);
  const user = await findUserByEmail(env, email);
  if (!user || !user.passwordHash) {
    throw unauthorized('Email ou senha inválidos.');
  }
  const valid = await verifyPassword(input.password, user.passwordHash);
  if (!valid) throw unauthorized('Email ou senha inválidos.');
  const tenantId = await tenantIdForSlug(env, user.id, input.tenantSlug);
  return tokenResponse(env, user, tenantId, input.userAgent);
}

export async function refresh(env: Env, token: string, userAgent?: string) {
  if (!token) throw badRequest('Refresh token é obrigatório');
  const session = await consumeSession(env, await hashToken(token));
  if (!session) throw unauthorized('Sessão expirada. Entre novamente.');
  const user = await findUserById(env, session.user_id);
  if (!user) throw unauthorized('Sessão expirada. Entre novamente.');
  return tokenResponse(env, user, session.tenant_id ?? undefined, userAgent);
}

export async function logout(env: Env, refreshToken: string): Promise<void> {
  if (!refreshToken) return;
  const tokenHash = await hashToken(refreshToken);
  const session = await queryOne<{ user_id: string }>(
    env.DB,
    'SELECT user_id FROM auth_sessions WHERE token_hash = ?',
    [tokenHash],
  );
  await revokeSession(env, tokenHash);
  if (session) {
    await execute(env.DB, 'DELETE FROM location_tokens WHERE user_id = ?', [
      session.user_id,
    ]);
  }
}

export async function switchTenant(
  env: Env,
  userId: string,
  tenantId: string,
  userAgent?: string,
) {
  const user = await findUserById(env, userId);
  if (!user) throw unauthorized();
  await tenantPrincipal(env, userId, tenantId);
  return tokenResponse(env, user, tenantId, userAgent);
}

export async function updateProfile(env: Env, userId: string, data: { name?: string }) {
  return updateUser(env, userId, { name: data.name?.trim() });
}

export async function updateAvatar(env: Env, userId: string, avatarPath: string) {
  return updateUser(env, userId, { avatarPath });
}

export async function listTenants(env: Env, userId: string) {
  return listMembershipsForUser(env, userId);
}

export async function currentTenant(env: Env, tenantId: string) {
  const tenant = await findTenantById(env, tenantId);
  if (!tenant) throw notFound('Família não encontrada.');
  return tenant;
}
