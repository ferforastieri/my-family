import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { LoggerModule } from 'nestjs-pino';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import {
  Environment,
  EnvironmentModule,
} from '@shared/infrastructure/environment/environment.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { UploadModule } from '@shared/infrastructure/upload';
import { QueueModule } from '@shared/infrastructure/queue';
import {
  ApiExceptionFilter,
  ApiResponseInterceptor,
} from '@shared/interfaces/http';
import { AuthModule } from '@auth/auth.module';
import { FotosModule } from '@fotos/fotos.module';
import { MusicasModule } from '@musicas/musicas.module';
import { CartasModule } from '@cartas/cartas.module';
import { HealthModule } from './health/health.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ChatModule } from './chat/chat.module';
import { GamesModule } from './games/games.module';
import { ListsModule } from './lists/lists.module';
import { LocationModule } from './location/location.module';
import { HomeSettingsModule } from './home-settings/home-settings.module';
import { TenancyModule } from './tenancy/tenancy.module';
import { TenantContextInterceptor } from './tenancy/interfaces/tenant-context.interceptor';
import { DemoModule } from './demo/demo.module';
import { NotasModule } from './notas/notas.module';
import { RedisThrottlerStorage } from '@shared/infrastructure/security/redis-throttler.storage';
import { buildRateLimiters } from '@shared/infrastructure/security/rate-limit.config';
import { CsrfGuard } from '@shared/infrastructure/security/csrf.guard';

@Module({
  imports: [
    EnvironmentModule.forRoot(),
    LoggerModule.forRootAsync({
      inject: [Environment],
      useFactory: (environment: Environment) => ({
        pinoHttp: {
          level: environment.log.level,
          transport: environment.isDevelopment()
            ? {
                target: 'pino-pretty',
                options: {
                  colorize: true,
                  levelFirst: true,
                  singleLine: true,
                  translateTime: 'SYS:yyyy-mm-dd HH:MM:ss.l o',
                  ignore: 'pid,hostname,context,env',
                  messageFormat: '[{context}] {msg}',
                  errorLikeObjectKeys: ['err', 'error'],
                },
              }
            : undefined,
          customProps: () => ({
            env: environment.type,
          }),
          customSuccessMessage: (request, response) =>
            `${request.method} ${request.url} -> ${response.statusCode}`,
          customErrorMessage: (request, response, error) =>
            `${request.method} ${request.url} -> ${response.statusCode}: ${error.message}`,
          serializers: {
            req(request) {
              return {
                id: request.id,
                method: request.method,
                url: String(request.url ?? '').replace(
                  /([?&]token=)[^&]+/g,
                  '$1[REDACTED]',
                ),
                query:
                  request.query && typeof request.query === 'object'
                    ? { ...request.query, token: undefined }
                    : request.query,
                params: request.params,
                remoteAddress: request.remoteAddress,
                remotePort: request.remotePort,
              };
            },
            res(response) {
              return {
                statusCode: response.statusCode,
              };
            },
            err(error) {
              return {
                type: error.type,
                message: error.message,
                stack: error.stack,
              };
            },
          },
          redact: {
            paths: [
              'req.headers.authorization',
              'req.headers.cookie',
              'req.body.code',
              'req.body.token',
              'req.body.password',
              'req.body.subscription.token',
              'req.body.firebaseServiceAccountJson',
              'req.body.FIREBASE_SERVICE_ACCOUNT_JSON',
            ],
            censor: '[REDACTED]',
          },
        },
      }),
    }),
    ThrottlerModule.forRootAsync({
      inject: [Environment],
      useFactory: (environment: Environment) => ({
        errorMessage: 'Muitas tentativas. Aguarde um pouco e tente novamente.',
        ...(environment.redis?.url
          ? { storage: new RedisThrottlerStorage(environment.redis.url) }
          : {}),
        throttlers: buildRateLimiters(environment),
      }),
    }),
    DatabaseModule,
    QueueModule,
    UploadModule,
    HealthModule,
    AuthModule,
    FotosModule,
    MusicasModule,
    CartasModule,
    NotificationsModule,
    ChatModule,
    GamesModule,
    ListsModule,
    NotasModule,
    LocationModule,
    HomeSettingsModule,
    TenancyModule,
    DemoModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: CsrfGuard },
    { provide: APP_INTERCEPTOR, useClass: ApiResponseInterceptor },
    { provide: APP_INTERCEPTOR, useClass: TenantContextInterceptor },
    { provide: APP_FILTER, useClass: ApiExceptionFilter },
  ],
})
export class AppModule {}
