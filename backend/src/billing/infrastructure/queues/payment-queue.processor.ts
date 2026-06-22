import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QUEUE_NAMES, type PaymentJob } from '@shared/infrastructure/queue';
import { BillingService } from '../../application/billing.service';

@Processor(QUEUE_NAMES.payments, { concurrency: 5 })
export class PaymentQueueProcessor extends WorkerHost {
  constructor(private readonly billing: BillingService) {
    super();
  }

  process(job: Job<PaymentJob>) {
    if (job.name !== 'stripe-event') return null;
    return this.billing.processPaymentEvent(job.data);
  }
}
