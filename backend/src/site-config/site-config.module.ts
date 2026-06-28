import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { SiteConfigService } from './application/site-config.service';
import { SiteConfigController } from './interfaces/site-config.controller';
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
  controllers: [SiteConfigController],
  providers: [SiteConfigService],
  exports: [SiteConfigService],
})
export class SiteConfigModule {}
