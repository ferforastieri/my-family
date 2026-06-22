import type { Job } from 'bullmq';
import type { PaymentJob } from '@shared/infrastructure/queue';
import { BillingService } from '../../application/billing.service';
import { PaymentQueueProcessor } from './payment-queue.processor';

describe('PaymentQueueProcessor', () => {
  it('encaminha eventos Stripe para o serviço de billing', async () => {
    const billing = {
      processPaymentEvent: jest.fn().mockResolvedValue({ processed: true }),
    } as unknown as BillingService;
    const processor = new PaymentQueueProcessor(billing);
    const data: PaymentJob = {
      eventId: 'evt_123',
      eventType: 'checkout.session.completed',
      payload: { id: 'evt_123', type: 'checkout.session.completed' },
    };

    await expect(
      processor.process({ name: 'stripe-event', data } as Job<PaymentJob>),
    ).resolves.toEqual({ processed: true });
    expect(billing.processPaymentEvent).toHaveBeenCalledWith(data);
  });
});
