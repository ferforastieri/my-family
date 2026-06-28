import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { ChatService } from './application/services/chat.service';
import { ChatRepository } from './infrastructure/repositories/chat.repository';
import { ChatRealtimeGateway } from './interfaces/gateways/chat-realtime.gateway';
import { ChatController } from './interfaces/controllers/chat.controller';
import { ListsModule } from '../lists/lists.module';
import { FotosModule } from '../fotos/fotos.module';
import { NotificationsModule } from '../notifications/notifications.module';
import {
  ChatConversationDocument,
  ChatConversationSchema,
} from './infrastructure/persistence/chat-conversation.schema';
import {
  ChatMessageDocument,
  ChatMessageSchema,
} from './infrastructure/persistence/chat-message.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: ChatConversationDocument.name, schema: ChatConversationSchema },
      { name: ChatMessageDocument.name, schema: ChatMessageSchema },
    ]),
    AuthModule,
    ListsModule,
    FotosModule,
    NotificationsModule,
  ],
  controllers: [ChatController],
  providers: [ChatService, ChatRepository, ChatRealtimeGateway],
})
export class ChatModule {}
