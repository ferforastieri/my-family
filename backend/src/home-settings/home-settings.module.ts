import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { HomeSettingsService } from './application/home-settings.service';
import { HomeSettingsRepository } from './infrastructure/home-settings.repository';
import { HomeSettingsGateway } from './interfaces/home-settings.gateway';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  providers: [
    HomeSettingsService,
    HomeSettingsRepository,
    HomeSettingsGateway,
  ],
  exports: [HomeSettingsService],
})
export class HomeSettingsModule {}
