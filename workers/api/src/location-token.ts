import type { Env } from './env';
import { execute, now, queryOne } from './db';
import {
  hashToken,
  loadPrincipal,
  randomToken,
  type Principal,
} from './auth';

const THIRTY_DAYS = 30 * 24 * 60 * 60 * 1000;

export async function createLocationToken(
  env: Env,
  userId: string,
  tenantId: string,
): Promise<string> {
  const token = randomToken(48);
  await execute(env.DB, 'DELETE FROM location_tokens WHERE user_id = ?', [userId]);
  await execute(
    env.DB,
    `INSERT INTO location_tokens (token_hash, user_id, tenant_id, expires_at, created_at)
     VALUES (?, ?, ?, ?, ?)`,
    [await hashToken(token), userId, tenantId, Date.now() + THIRTY_DAYS, now()],
  );
  return token;
}

export async function principalFromLocationToken(
  env: Env,
  token: string,
): Promise<Principal | null> {
  if (!token) return null;
  const row = await queryOne<{ user_id: string; tenant_id: string }>(
    env.DB,
    'SELECT user_id, tenant_id FROM location_tokens WHERE token_hash = ? AND expires_at > ?',
    [await hashToken(token), now()],
  );
  if (!row) return null;
  return loadPrincipal(env, row.user_id, row.tenant_id);
}
