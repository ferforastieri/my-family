import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { ListsService } from './application/services/lists.service';
import { ListsRepository } from './infrastructure/repositories/lists.repository';
import { ListsRealtimeGateway } from './interfaces/gateways/lists-realtime.gateway';
import { ListsController } from './interfaces/controllers/lists.controller';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  controllers: [ListsController],
  providers: [ListsService, ListsRepository, ListsRealtimeGateway],
  exports: [ListsService, ListsRealtimeGateway],
})
export class ListsModule {}
