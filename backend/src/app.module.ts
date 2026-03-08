import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EmailModule } from '@shared/infrastructure/email/email.module';
import { UploadModule } from '@shared/infrastructure/upload';
import { AuthModule } from '@auth/auth.module';
import { FotosModule } from '@fotos/fotos.module';
import { MusicasModule } from '@musicas/musicas.module';
import { CartasModule } from '@cartas/cartas.module';
import { HealthModule } from './health/health.module';
import { NotificationsModule } from './notifications/notifications.module';

@Module({
  imports: [
    EnvironmentModule.forRoot(),
    BullModule.forRootAsync({
      imports: [EnvironmentModule],
      inject: [Environment],
      useFactory: (env: Environment) => {
        if (!env.redis?.url) throw new Error('REDIS_URL é obrigatório');
        const u = new URL(env.redis.url);
        return {
          connection: { host: u.hostname, port: parseInt(u.port || '6379', 10) },
        };
      },
    }),
    DatabaseModule,
    EmailModule,
    UploadModule,
    HealthModule,
    AuthModule,
    FotosModule,
    MusicasModule,
    CartasModule,
    NotificationsModule,
  ],
})
export class AppModule {}
