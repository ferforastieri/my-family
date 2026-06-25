import { IoAdapter } from '@nestjs/platform-socket.io';
import type { INestApplicationContext } from '@nestjs/common';
import type { Server, ServerOptions } from 'socket.io';
import { Environment } from '@shared/infrastructure/environment/environment.module';

export class ConfiguredIoAdapter extends IoAdapter {
  constructor(
    app: INestApplicationContext,
    private readonly environment: Environment,
  ) {
    super(app);
  }

  createIOServer(port: number, options: Partial<ServerOptions> = {}): Server {
    const origin = parseOrigins(this.environment.cors.origin);
    return super.createIOServer(port, {
      ...options,
      cors: {
        origin,
        credentials: origin !== '*',
        methods: ['GET', 'POST'],
      },
    }) as Server;
  }
}

function parseOrigins(value: string): string | string[] {
  const origins = value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  return origins.length > 1 ? origins : origins[0] || '*';
}
