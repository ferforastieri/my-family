import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { ChatService } from './application/services/chat.service';
import { ChatRepository } from './infrastructure/repositories/chat.repository';
import { ChatGateway } from './interfaces/gateways/chat.gateway';
import { ListsModule } from '../lists/lists.module';
import { FotosModule } from '../fotos/fotos.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TenancyModule } from '@tenancy/tenancy.module';
import { WsRateLimitGuard } from '@shared/infrastructure/security/ws-rate-limit.guard';

@Module({
  imports: [
    DatabaseModule,
    MongoModelsModule,
    AuthModule,
    ListsModule,
    FotosModule,
    NotificationsModule,
    TenancyModule,
  ],
  providers: [ChatService, ChatRepository, ChatGateway, WsRateLimitGuard],
})
export class ChatModule {}
