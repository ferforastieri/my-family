import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { LoggerModule } from 'nestjs-pino';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import {
  Environment,
  EnvironmentModule,
} from '@shared/infrastructure/environment/environment.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EmailModule } from '@shared/infrastructure/email/email.module';
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

@Module({
  imports: [
    EnvironmentModule.forRoot(),
    LoggerModule.forRootAsync({
      inject: [Environment],
      useFactory: (environment: Environment) => ({
        pinoHttp: {
          level: environment.log.level,
          transport: environment.isProduction()
            ? undefined
            : {
                target: 'pino-pretty',
                options: {
                  colorize: true,
                  singleLine: true,
                  translateTime: 'SYS:standard',
                },
              },
          redact: {
            paths: [
              'req.headers.authorization',
              'req.headers.cookie',
              'req.body.password',
              'req.body.newPassword',
              'req.body.token',
            ],
            censor: '[REDACTED]',
          },
        },
      }),
    }),
    ThrottlerModule.forRootAsync({
      inject: [Environment],
      useFactory: (environment: Environment) => [
        {
          name: 'default',
          ttl: environment.security.throttleTtlMs,
          limit: environment.security.throttleLimit,
        },
      ],
    }),
    DatabaseModule,
    QueueModule,
    EmailModule,
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
    LocationModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_INTERCEPTOR, useClass: ApiResponseInterceptor },
    { provide: APP_FILTER, useClass: ApiExceptionFilter },
  ],
})
export class AppModule {}
