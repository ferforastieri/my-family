import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { BillingService } from './application/billing.service';
import { BillingRepository } from './infrastructure/billing.repository';
import { BillingController } from './interfaces/billing.controller';
import { PaymentQueueProcessor } from './infrastructure/queues/payment-queue.processor';
import {
  BillingEventDocument,
  BillingEventSchema,
  SubscriptionDocument,
  SubscriptionSchema,
} from './infrastructure/persistence/subscription.schema';
import {
  SubscriptionPlanDocument,
  SubscriptionPlanSchema,
} from './infrastructure/persistence/subscription-plan.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SubscriptionDocument.name, schema: SubscriptionSchema },
      { name: SubscriptionPlanDocument.name, schema: SubscriptionPlanSchema },
      { name: BillingEventDocument.name, schema: BillingEventSchema },
    ]),
  ],
  controllers: [BillingController],
  providers: [BillingService, BillingRepository, PaymentQueueProcessor],
  exports: [BillingService, BillingRepository],
})
export class BillingModule {}
