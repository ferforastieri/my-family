import { Module } from '@nestjs/common';
import { PublicSiteModule } from '../public-site/public-site.module';
import { MarketingController } from './marketing.controller';

@Module({
  imports: [PublicSiteModule],
  controllers: [MarketingController],
})
export class MarketingModule {}
