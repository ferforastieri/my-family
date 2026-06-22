import { Module } from '@nestjs/common';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { BillingService } from './application/billing.service';
import { BillingRepository } from './infrastructure/billing.repository';
import { BillingController } from './interfaces/billing.controller';

@Module({
  imports: [MongoModelsModule],
  controllers: [BillingController],
  providers: [BillingService, BillingRepository],
  exports: [BillingService, BillingRepository],
})
export class BillingModule {}

