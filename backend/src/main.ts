import { EventEmitter } from 'node:events';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { Logger } from 'nestjs-pino';
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

  app.setGlobalPrefix('api');
  app.enableCors({
    origin: '*',
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
