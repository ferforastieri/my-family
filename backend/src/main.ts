import { EventEmitter } from 'node:events';
import { NestFactory } from '@nestjs/core';
import { RequestMethod, ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import * as cookieParser from 'cookie-parser';
import { doubleCsrf } from 'csrf-csrf';
import { AppModule } from './app.module';
import { Environment } from '@shared/infrastructure/environment/environment.module';

async function bootstrap() {
  EventEmitter.defaultMaxListeners = 50;
  const app = await NestFactory.create(AppModule, {
    cors: false,
    rawBody: true,
  });
  const environment = app.get(Environment);

  app.getHttpAdapter().getInstance().disable('x-powered-by');
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );
  app.use(cookieParser());
  const { doubleCsrfProtection } = doubleCsrf({
    getSecret: () => environment.security.csrfSecret,
    getSessionIdentifier: (request) =>
      request.headers.authorization ||
      request.headers['x-forwarded-for']?.toString() ||
      request.ip ||
      'anonymous',
    cookieName: environment.isProduction()
      ? '__Host-fmf.x-csrf-token'
      : 'fmf.x-csrf-token',
    cookieOptions: {
      httpOnly: true,
      path: '/',
      sameSite: environment.isProduction() ? 'none' : 'lax',
      secure: environment.isProduction(),
    },
    getCsrfTokenFromRequest: (request) => request.headers['x-csrf-token'],
    errorConfig: {
      statusCode: 403,
      message: 'Token CSRF inválido ou ausente.',
      code: 'EBADCSRFTOKEN',
    },
    skipCsrfProtection: (request) =>
      hasBearerToken(request.headers.authorization) ||
      isAuthHttpEndpoint(request.path) ||
      request.path.endsWith('/billing/webhook') ||
      request.path.startsWith('/socket.io'),
  });
  app.use(doubleCsrfProtection);
  app.setGlobalPrefix('api', {
    exclude: [
      { path: '', method: RequestMethod.GET },
      { path: 'pt', method: RequestMethod.GET },
      { path: 'en', method: RequestMethod.GET },
      { path: 'es', method: RequestMethod.GET },
      { path: 'pt/familia/:slug', method: RequestMethod.GET },
      { path: 'en/familia/:slug', method: RequestMethod.GET },
      { path: 'es/familia/:slug', method: RequestMethod.GET },
      { path: 'marketing.css', method: RequestMethod.GET },
      { path: 'robots.txt', method: RequestMethod.GET },
      { path: 'sitemap.xml', method: RequestMethod.GET },
    ],
  });
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

function hasBearerToken(authorization?: string): boolean {
  return authorization?.trim().toLowerCase().startsWith('bearer ') === true;
}

function isAuthHttpEndpoint(path: string): boolean {
  const normalized = path.startsWith('/api/') ? path.substring(4) : path;
  return (
    normalized === '/auth/login' ||
    normalized === '/auth/register' ||
    normalized === '/auth/refresh' ||
    normalized === '/auth/forgot-password' ||
    normalized === '/auth/reset-password'
  );
}
