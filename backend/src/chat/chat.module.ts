import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { ChatService } from './application/chat.service';
import { ChatRepository } from './infrastructure/repositories/chat.repository';
import { ChatGateway } from './interfaces/gateways/chat.gateway';
import { ListsModule } from '../lists/lists.module';
import { FotosModule } from '../fotos/fotos.module';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule, ListsModule, FotosModule],
  providers: [ChatService, ChatRepository, ChatGateway],
})
export class ChatModule {}
