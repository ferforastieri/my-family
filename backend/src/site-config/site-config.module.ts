import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { SiteConfigService } from './application/site-config.service';
import { SiteConfigGateway } from './interfaces/site-config.gateway';
import {
  SiteConfigDocument,
  SiteConfigSchema,
} from './infrastructure/persistence/site-config.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SiteConfigDocument.name, schema: SiteConfigSchema },
    ]),
    AuthModule,
  ],
  providers: [SiteConfigService, SiteConfigGateway],
  exports: [SiteConfigService],
})
export class SiteConfigModule {}
