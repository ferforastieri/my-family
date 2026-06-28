import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { ListsService } from './application/services/lists.service';
import { ListsRepository } from './infrastructure/repositories/lists.repository';
import { ListsController } from './interfaces/controllers/lists.controller';
import { ListsRealtimeGateway } from './interfaces/gateways/lists-realtime.gateway';
import {
  FamilyListDocument,
  FamilyListSchema,
} from './infrastructure/persistence/family-list.schema';
import {
  FamilyListItemDocument,
  FamilyListItemSchema,
} from './infrastructure/persistence/family-list-item.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: FamilyListDocument.name, schema: FamilyListSchema },
      { name: FamilyListItemDocument.name, schema: FamilyListItemSchema },
    ]),
    AuthModule,
  ],
  controllers: [ListsController],
  providers: [
    ListsService,
    ListsRepository,
    ListsRealtimeGateway,
  ],
  exports: [ListsService, ListsRealtimeGateway],
})
export class ListsModule {}
