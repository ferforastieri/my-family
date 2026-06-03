import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { ListsService } from './application/lists.service';
import { ListsRepository } from './infrastructure/repositories/lists.repository';
import { ListsGateway } from './interfaces/gateways/lists.gateway';
import { ListsRealtimeGateway } from './interfaces/gateways/lists-realtime.gateway';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  providers: [ListsService, ListsRepository, ListsGateway, ListsRealtimeGateway],
  exports: [ListsService, ListsRealtimeGateway],
})
export class ListsModule {}

