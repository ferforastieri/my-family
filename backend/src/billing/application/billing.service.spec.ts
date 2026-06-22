import { BillingService } from './billing.service';

describe('BillingService payment jobs', () => {
  const createService = (reserveEvent: jest.Mock) => {
    const repository = {
      reserveEvent,
      releaseEvent: jest.fn(),
    };
    const service = new BillingService(
      {} as never,
      {} as never,
      {} as never,
      repository as never,
      {} as never,
    );
    return { service, repository };
  };

  it('ignora de forma idempotente um evento já processado', async () => {
    const { service, repository } = createService(
      jest.fn().mockResolvedValue(false),
    );

    await expect(
      service.processPaymentEvent({
        eventId: 'evt_duplicate',
        eventType: 'customer.subscription.updated',
        payload: {},
      }),
    ).resolves.toEqual({ processed: false, duplicate: true });
    expect(repository.releaseEvent).not.toHaveBeenCalled();
  });

  it('confirma um evento aceito pela fila', async () => {
    const { service } = createService(jest.fn().mockResolvedValue(true));

    await expect(
      service.processPaymentEvent({
        eventId: 'evt_accepted',
        eventType: 'event.not_used',
        payload: { id: 'evt_accepted', type: 'event.not_used' },
      }),
    ).resolves.toEqual({ processed: true });
  });
});
