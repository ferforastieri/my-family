import { DurableObject } from 'cloudflare:workers';
import type { Env } from '../env';

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  retryAfter: number;
}

export class RateLimiter extends DurableObject<Env> {
  async hit(key: string, limit: number, windowMs: number): Promise<RateLimitResult> {
    const sql = this.ctx.storage.sql;
    sql.exec(
      'CREATE TABLE IF NOT EXISTS counters (key TEXT PRIMARY KEY, count INTEGER NOT NULL, reset_at INTEGER NOT NULL)',
    );
    const timestamp = Date.now();
    const row = sql
      .exec('SELECT count, reset_at FROM counters WHERE key = ?', key)
      .toArray()[0] as { count: number; reset_at: number } | undefined;
    if (!row || row.reset_at <= timestamp) {
      sql.exec(
        'INSERT INTO counters (key, count, reset_at) VALUES (?, 1, ?) ON CONFLICT(key) DO UPDATE SET count = 1, reset_at = excluded.reset_at',
        key,
        timestamp + windowMs,
      );
      return { allowed: true, remaining: Math.max(0, limit - 1), retryAfter: 0 };
    }
    if (row.count >= limit) {
      return {
        allowed: false,
        remaining: 0,
        retryAfter: Math.max(1, Math.ceil((row.reset_at - timestamp) / 1000)),
      };
    }
    sql.exec('UPDATE counters SET count = count + 1 WHERE key = ?', key);
    return {
      allowed: true,
      remaining: Math.max(0, limit - row.count - 1),
      retryAfter: 0,
    };
  }
}
