import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { HomeSettingsService } from './application/home-settings.service';
import { HomeSettingsRepository } from './infrastructure/home-settings.repository';
import { HomeSettingsGateway } from './interfaces/home-settings.gateway';
import {
  HomeSettingsDocument,
  HomeSettingsSchema,
} from './infrastructure/persistence/home-settings.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: HomeSettingsDocument.name, schema: HomeSettingsSchema },
    ]),
    AuthModule,
  ],
  providers: [
    HomeSettingsService,
    HomeSettingsRepository,
    HomeSettingsGateway,
  ],
  exports: [HomeSettingsService],
})
export class HomeSettingsModule {}
