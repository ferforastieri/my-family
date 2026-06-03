import { EventEmitter } from 'node:events';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { Logger } from 'nestjs-pino';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { Environment } from '@shared/infrastructure/environment/environment.module';

async function bootstrap() {
  EventEmitter.defaultMaxListeners = 50;
  const app = await NestFactory.create(AppModule, {
    cors: false,
    bufferLogs: true,
  });
  app.useLogger(app.get(Logger));
  const environment = app.get(Environment);

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

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  await app.listen(environment.http.port);
}
bootstrap();

function parseCorsOrigin(origin: string): string | string[] {
  const items = origin
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  return items.length > 1 ? items : items[0];
}
