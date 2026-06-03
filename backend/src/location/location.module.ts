import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { NotificationsModule } from '../notifications/notifications.module';
import { LocationService } from './application/location.service';
import { LocationRepository } from './infrastructure/repositories/location.repository';
import { LocationGateway } from './interfaces/gateways/location.gateway';
import { LocationQueueProcessor } from './infrastructure/queues/location-queue.processor';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule, NotificationsModule],
  providers: [LocationService, LocationRepository, LocationGateway, LocationQueueProcessor],
})
export class LocationModule {}
