import { EventEmitter } from 'node:events';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { NestFactory } from '@nestjs/core';
import { RequestMethod } from '@nestjs/common';
import * as express from 'express';
import helmet from 'helmet';
import * as cookieParser from 'cookie-parser';
import { doubleCsrf } from 'csrf-csrf';
import { AppModule } from './app.module';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { ConfiguredIoAdapter } from '@shared/infrastructure/websocket/configured-io.adapter';

async function bootstrap() {
  EventEmitter.defaultMaxListeners = 50;
  const app = await NestFactory.create(AppModule, {
    cors: false,
    rawBody: true,
  });
  const environment = app.get(Environment);
  app.useWebSocketAdapter(new ConfiguredIoAdapter(app, environment));

  const httpServer = app.getHttpAdapter().getInstance();
  httpServer.disable('x-powered-by');
  httpServer.set('trust proxy', 1);
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          baseUri: ["'self'"],
          connectSrc: ["'self'", 'http:', 'https:', 'ws:', 'wss:'],
          fontSrc: ["'self'", 'data:', 'https:'],
          frameAncestors: ["'self'"],
          imgSrc: ["'self'", 'data:', 'blob:', 'https:'],
          objectSrc: ["'none'"],
          manifestSrc: ["'self'"],
          scriptSrc: [
            "'self'",
            "'unsafe-inline'",
            "'wasm-unsafe-eval'",
            'https:',
          ],
          styleSrc: ["'self'", "'unsafe-inline'", 'https:'],
          workerSrc: ["'self'", 'blob:'],
        },
      },
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
      request.path === '/app' ||
      request.path.startsWith('/app/') ||
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
    credentials: environment.cors.origin !== '*',
  });
  serveFlutterWeb(httpServer);

  await app.listen(environment.http.port, '0.0.0.0');
}
bootstrap();

function serveFlutterWeb(httpServer: express.Express): void {
  const appPath = join(process.cwd(), 'public', 'app');
  const indexPath = join(appPath, 'index.html');
  if (!existsSync(indexPath)) return;

  httpServer.get('/app', (_request, response) => {
    response.redirect(308, '/app/');
  });
  httpServer.use(
    '/app',
    express.static(appPath, {
      index: 'index.html',
      setHeaders: (response, filePath) => {
        const normalizedPath = filePath.replace(/\\/g, '/');
        const canUseLongCache =
          normalizedPath.includes('/assets/') ||
          normalizedPath.includes('/canvaskit/');
        response.setHeader(
          'Cache-Control',
          canUseLongCache
            ? 'public, max-age=31536000, immutable'
            : 'no-cache',
        );
      },
    }),
  );
  httpServer.get(/^\/app\/.*$/, (_request, response) => {
    response.setHeader('Cache-Control', 'no-store');
    response.sendFile(indexPath);
  });
}

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


