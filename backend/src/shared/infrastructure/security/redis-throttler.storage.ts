import type { ThrottlerStorage } from '@nestjs/throttler';
import { createClient } from 'redis';

const incrementScript = `
local blockedTtl = redis.call('PTTL', KEYS[2])
if blockedTtl > 0 then
  local current = tonumber(redis.call('GET', KEYS[1]) or '0')
  return { current, redis.call('PTTL', KEYS[1]), 1, blockedTtl }
end
local total = redis.call('INCR', KEYS[1])
if total == 1 then redis.call('PEXPIRE', KEYS[1], ARGV[1]) end
local ttl = redis.call('PTTL', KEYS[1])
if total > tonumber(ARGV[2]) then
  local duration = tonumber(ARGV[3])
  if duration <= 0 then duration = tonumber(ARGV[1]) end
  redis.call('SET', KEYS[2], '1', 'PX', duration)
  return { total, ttl, 1, duration }
end
return { total, ttl, 0, 0 }
`;

export class RedisThrottlerStorage implements ThrottlerStorage {
  private client;
  private connection?: Promise<void>;

  constructor(redisUrl: string) {
    this.client = createClient({ url: redisUrl });
    this.client.on('error', () => undefined);
  }

  private connect() {
    if (this.connection === undefined) {
      this.connection = this.client.connect();
    }
    return this.connection;
  }

  async increment(
    key: string,
    ttl: number,
    limit: number,
    blockDuration: number,
    throttlerName: string,
  ): Promise<{
    totalHits: number;
    timeToExpire: number;
    isBlocked: boolean;
    timeToBlockExpire: number;
  }> {
    await this.connect();
    const result = (await this.client.eval(incrementScript, {
      keys: [
        `throttle:${throttlerName}:${key}`,
        `throttle:block:${throttlerName}:${key}`,
      ],
      arguments: [String(ttl), String(limit), String(blockDuration)],
    })) as number[];
    return {
      totalHits: Number(result[0]),
      timeToExpire: Math.max(0, Number(result[1])),
      isBlocked: Number(result[2]) === 1,
      timeToBlockExpire: Math.max(0, Number(result[3])),
    };
  }
}
