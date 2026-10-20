import type { Env } from './env';
import { execute, jsonArray, now, queryOne } from './db';
import {
  hashToken,
  normalizeAccessKeys,
  type UserAccessKey,
  type UserRole,
} from './auth';
import { badRequest, conflict, unauthorized } from './http';
import {
  hashOtp,
  isOtp,
  randomOtp,
  verifyOtpHash,
} from './otp';
import {
  channelConfigured,
  normalizePhoneNumber,
  sendOtp,
  type PhoneChannel,
} from './messaging';
import {
  acceptInvitation,
  createFamily,
  createSession,
  consumeSession,
  findTenantById,
  listMembershipsForUser,
  revokeSession,
  tenantIdForSlug,
  tenantPrincipal,
  tokenResponse,
} from './tenants';
import { isProduction } from './env';

export interface UserEntity {
  id: string;
  phoneNumber: string;
  name: string | null;
  role: UserRole;
  access: UserAccessKey[];
  avatarPath: string | null;
  platformRole: 'super_admin' | null;
  createdAt: string;
  updatedAt: string;
}

interface UserRow {
  id: string;
  phone_number: string;
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
    phoneNumber: row.phone_number,
    name: row.name,
    role: row.role as UserRole,
    access: normalizeAccessKeys(jsonArray(row.access)),
    avatarPath: row.avatar_path,
    platformRole: row.platform_role === 'super_admin' ? 'super_admin' : null,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

export async function findUserById(env: Env, id: string): Promise<UserEntity | null> {
  const row = await queryOne<UserRow>(env.DB, 'SELECT * FROM users WHERE id = ?', [id]);
  return row ? userFromRow(row) : null;
}

export async function findUserByPhone(env: Env, phoneNumber: string): Promise<UserEntity | null> {
  const row = await queryOne<UserRow>(env.DB, 'SELECT * FROM users WHERE phone_number = ?', [
    phoneNumber,
  ]);
  return row ? userFromRow(row) : null;
}

export async function createUser(
  env: Env,
  phoneNumber: string,
  data: { name?: string; platformRole?: 'super_admin' } = {},
): Promise<UserEntity> {
  if (await findUserByPhone(env, phoneNumber)) {
    throw conflict('Celular já cadastrado.');
  }
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    env.DB,
    `INSERT INTO users (id, phone_number, name, role, access, platform_role, created_at, updated_at)
     VALUES (?, ?, ?, 'friends', '[]', ?, ?, ?)`,
    [id, phoneNumber, data.name ?? null, data.platformRole ?? null, timestamp, timestamp],
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

export async function requestCode(env: Env, phone: string, channel: PhoneChannel) {
  const phoneNumber = normalizePhoneNumber(env, phone);
  const code = randomOtp();
  await execute(env.DB, 'DELETE FROM phone_challenges WHERE phone_number = ?', [phoneNumber]);
  await execute(
    env.DB,
    `INSERT INTO phone_challenges (id, phone_number, code_hash, channel, attempts, expires_at, created_at)
     VALUES (?, ?, ?, ?, 0, ?, ?)`,
    [
      crypto.randomUUID(),
      phoneNumber,
      await hashOtp(env.PHONE_OTP_SECRET, phoneNumber, code),
      channel,
      Date.now() + 5 * 60 * 1000,
      now(),
    ],
  );

  if (channelConfigured(env)) {
    await sendOtp(env, phoneNumber, code, channel);
    return { phoneNumber, expiresIn: 300 };
  }
  if (!isProduction(env)) {
    return { phoneNumber, expiresIn: 300, devCode: code };
  }
  await sendOtp(env, phoneNumber, code, channel);
  return { phoneNumber, expiresIn: 300 };
}

interface ChallengeRow {
  id: string;
  code_hash: string;
  attempts: number;
}

async function verifyCode(env: Env, phoneNumber: string, code: string): Promise<void> {
  if (!isOtp(code)) throw unauthorized('Código inválido ou expirado.');
  const challenge = await queryOne<ChallengeRow>(
    env.DB,
    `SELECT id, code_hash, attempts FROM phone_challenges
      WHERE phone_number = ? AND consumed_at IS NULL AND expires_at > ? AND attempts < 5
      ORDER BY created_at DESC LIMIT 1`,
    [phoneNumber, now()],
  );
  if (!challenge) throw unauthorized('Código inválido ou expirado.');
  const expected = await hashOtp(env.PHONE_OTP_SECRET, phoneNumber, code);
  if (!verifyOtpHash(challenge.code_hash, expected)) {
    await execute(env.DB, 'UPDATE phone_challenges SET attempts = attempts + 1 WHERE id = ?', [
      challenge.id,
    ]);
    throw unauthorized('Código inválido ou expirado.');
  }
  const consumed = await execute(
    env.DB,
    'UPDATE phone_challenges SET consumed_at = ? WHERE id = ? AND consumed_at IS NULL',
    [now(), challenge.id],
  );
  if (consumed.meta.changes !== 1) throw unauthorized('Código inválido ou expirado.');
}

export async function authenticateWithCode(
  env: Env,
  input: {
    phone: string;
    code: string;
    invitationToken?: string;
    tenantSlug?: string;
    userAgent?: string;
  },
) {
  const phoneNumber = normalizePhoneNumber(env, input.phone);
  let user = await findUserByPhone(env, phoneNumber);
  await verifyCode(env, phoneNumber, input.code);

  if (!user) {
    const configuredAdmin = env.PLATFORM_ADMIN_PHONE
      ? normalizePhoneNumber(env, env.PLATFORM_ADMIN_PHONE)
      : undefined;
    user = await createUser(env, phoneNumber, {
      ...(configuredAdmin === phoneNumber
        ? { platformRole: 'super_admin' as const }
        : {}),
    });
    try {
      if (input.invitationToken) {
        const tenant = await acceptInvitation(env, user.id, input.invitationToken);
        return tokenResponse(env, user, tenant?.id, input.userAgent);
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

  if (input.invitationToken) {
    const tenant = await acceptInvitation(env, user.id, input.invitationToken);
    return tokenResponse(env, user, tenant?.id, input.userAgent);
  }
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
  if (refreshToken) await revokeSession(env, await hashToken(refreshToken));
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
  if (!tenant) throw badRequest('Família não encontrada.');
  return tenant;
}
