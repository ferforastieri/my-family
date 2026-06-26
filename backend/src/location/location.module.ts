import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { LocationService } from './application/services/location.service';
import { LocationRepository } from './infrastructure/repositories/location.repository';
import { LocationController } from './interfaces/controllers/location.controller';
import { LocationGateway } from './interfaces/gateways/location.gateway';
import { LocationQueueProcessor } from './infrastructure/queues/location-queue.processor';
import {
  LocationPlaceDocument,
  LocationPlaceSchema,
} from './infrastructure/persistence/location-place.schema';
import {
  LocationPresenceDocument,
  LocationPresenceSchema,
} from './infrastructure/persistence/location-presence.schema';
import {
  LocationUpdateDocument,
  LocationUpdateSchema,
} from './infrastructure/persistence/location-update.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: LocationUpdateDocument.name, schema: LocationUpdateSchema },
      { name: LocationPlaceDocument.name, schema: LocationPlaceSchema },
      { name: LocationPresenceDocument.name, schema: LocationPresenceSchema },
    ]),
    AuthModule,
    NotificationsModule,
  ],
  providers: [
    LocationService,
    LocationRepository,
    LocationGateway,
    LocationQueueProcessor,
  ],
  controllers: [LocationController],
})
export class LocationModule {}
