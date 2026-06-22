import { Module } from '@nestjs/common';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { BillingService } from './application/billing.service';
import { BillingRepository } from './infrastructure/billing.repository';
import { BillingController } from './interfaces/billing.controller';
import { PaymentQueueProcessor } from './infrastructure/queues/payment-queue.processor';

@Module({
  imports: [MongoModelsModule],
  controllers: [BillingController],
  providers: [BillingService, BillingRepository, PaymentQueueProcessor],
  exports: [BillingService, BillingRepository],
})
export class BillingModule {}
