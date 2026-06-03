import { Module } from '@nestjs/common';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EmailModule } from '@shared/infrastructure/email/email.module';
import { UploadModule } from '@shared/infrastructure/upload';
import { QueueModule } from '@shared/infrastructure/queue';
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
})
export class AppModule {}
