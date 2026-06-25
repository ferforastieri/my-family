import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { SiteConfigService } from './application/site-config.service';
import { SiteConfigGateway } from './interfaces/site-config.gateway';

@Module({
  imports: [MongoModelsModule, AuthModule],
  providers: [SiteConfigService, SiteConfigGateway],
  exports: [SiteConfigService],
})
export class SiteConfigModule {}
