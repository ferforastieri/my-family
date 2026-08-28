import { EventEmitter } from 'node:events';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { Logger } from 'nestjs-pino';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { RedisIoAdapter } from '@shared/infrastructure/realtime/redis-io.adapter';

async function bootstrap() {
  process.env.PROCESS_ROLE = 'api';
  EventEmitter.defaultMaxListeners = 50;
  const app = await NestFactory.create(AppModule, {
    cors: false,
    bufferLogs: true,
  });
  app.useLogger(app.get(Logger));
  const environment = app.get(Environment);
  app
    .getHttpAdapter()
    .getInstance()
    .set('trust proxy', environment.security.trustProxyHops);
  const realtimeAdapter = new RedisIoAdapter(
    app,
    environment.redis?.url,
    parseCorsOrigins(environment.cors.origin),
  );
  await realtimeAdapter.connect();
  app.useWebSocketAdapter(realtimeAdapter);

  app.getHttpAdapter().getInstance().disable('x-powered-by');
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );
  app.setGlobalPrefix('api');
  app.enableCors({
    origin: parseCorsOrigin(environment.cors.origin),
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  if (environment.isProduction() && environment.cors.origin.trim() === '*') {
    throw new Error('CORS_ORIGIN não pode ser * em produção');
  }

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  await app.listen(environment.http.port);
}
void bootstrap().catch((error: unknown) => {
  console.error('Falha ao iniciar a API.', error);
  process.exitCode = 1;
});

function parseCorsOrigins(origin: string): string[] {
  const items = origin
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  return items;
}

function parseCorsOrigin(origin: string): string | string[] {
  const items = parseCorsOrigins(origin);
  return items.length > 1 ? items : items[0];
}
