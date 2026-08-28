import { Controller, Get } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { Connection } from 'mongoose';
import { createClient } from 'redis';
import { Environment } from '@shared/infrastructure/environment/environment.module';

@Controller('health')
export class HealthController {
  constructor(
    @InjectConnection() private mongo: Connection,
    private env: Environment,
  ) {}
  @Get()
  check() {
    return { ok: true };
  }

  @Get('live')
  live() {
    return { ok: true, process: process.env.PROCESS_ROLE ?? 'api' };
  }

  @Get('ready')
  async ready() {
    await this.mongo.db?.admin().ping();
    if (this.env.redis?.url) {
      const client = createClient({ url: this.env.redis.url });
      try {
        await client.connect();
        await client.ping();
      } finally {
        await client.disconnect().catch(() => undefined);
      }
    }
    return { ok: true, mongo: 'up', redis: this.env.redis ? 'up' : 'disabled' };
  }
}
