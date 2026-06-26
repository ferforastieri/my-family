import { Module } from '@nestjs/common';
import { PublicSiteModule } from '../public-site/public-site.module';
import { BillingModule } from '../billing/billing.module';
import { MarketingController } from './marketing.controller';

@Module({
  imports: [PublicSiteModule, BillingModule],
  controllers: [MarketingController],
})
export class MarketingModule {}
