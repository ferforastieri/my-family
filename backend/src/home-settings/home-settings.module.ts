import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { HomeSettingsService } from './application/home-settings.service';
import { HomeSettingsRepository } from './infrastructure/home-settings.repository';
import { HomeSettingsController } from './interfaces/home-settings.controller';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  controllers: [HomeSettingsController],
  providers: [HomeSettingsService, HomeSettingsRepository],
  exports: [HomeSettingsService],
})
export class HomeSettingsModule {}
