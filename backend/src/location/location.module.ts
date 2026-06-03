import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { LocationService } from './application/location.service';
import { LocationRepository } from './infrastructure/repositories/location.repository';
import { LocationGateway } from './interfaces/gateways/location.gateway';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  providers: [LocationService, LocationRepository, LocationGateway],
})
export class LocationModule {}

