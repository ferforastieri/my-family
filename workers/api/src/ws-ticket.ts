import type { Env } from './env';
import { execute, now, queryOne } from './db';
import { randomToken } from './auth';

export async function createWsTicket(
  env: Env,
  userId: string,
  tenantId: string,
): Promise<string> {
  const token = randomToken(32);
  await execute(
    env.DB,
    `INSERT INTO ws_tickets (token, user_id, tenant_id, expires_at, created_at)
     VALUES (?, ?, ?, ?, ?)`,
    [token, userId, tenantId, Date.now() + 60_000, now()],
  );
  return token;
}

export async function consumeWsTicket(
  env: Env,
  token: string,
): Promise<{ user_id: string; tenant_id: string } | null> {
  return queryOne<{ user_id: string; tenant_id: string }>(
    env.DB,
    `UPDATE ws_tickets SET used_at = ?
      WHERE token = ? AND used_at IS NULL AND expires_at > ?
      RETURNING user_id, tenant_id`,
    [now(), token, now()],
  );
}
