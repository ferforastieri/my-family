import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
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
  CsrfController,
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
import { NotasModule } from './notas/notas.module';
import { TenancyModule } from './tenancy/tenancy.module';
import { BillingModule } from './billing/billing.module';
import { PublicSiteModule } from './public-site/public-site.module';
import { MarketingModule } from './marketing/marketing.module';
import { TenantContextInterceptor } from './auth/application/services/tenant-context.interceptor';

@Module({
  imports: [
    EnvironmentModule.forRoot(),
    ThrottlerModule.forRootAsync({
      inject: [Environment],
      useFactory: (environment: Environment) => ({
        errorMessage: 'Muitas tentativas. Aguarde um pouco e tente novamente.',
        throttlers: [
          {
            name: 'default',
            ttl: environment.security.throttleTtlMs,
            limit: environment.security.throttleLimit,
          },
        ],
      }),
    }),
    DatabaseModule,
    QueueModule,
    EmailModule,
    UploadModule,
    TenancyModule,
    BillingModule,
    PublicSiteModule,
    MarketingModule,
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
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_INTERCEPTOR, useClass: ApiResponseInterceptor },
    { provide: APP_INTERCEPTOR, useClass: TenantContextInterceptor },
    { provide: APP_FILTER, useClass: ApiExceptionFilter },
  ],
  controllers: [CsrfController],
})
export class AppModule {}
