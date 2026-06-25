import { NotificationsRepository } from './notifications.repository';

describe('NotificationsRepository subscriptions', () => {
  it('only removes a token owned by the authenticated user', async () => {
    const exec = jest.fn().mockResolvedValue(undefined);
    const subscriptions = {
      deleteOne: jest.fn().mockReturnValue({ exec }),
    };
    const repository = new NotificationsRepository(
      {} as never,
      subscriptions as never,
    );

    await repository.removeSubscriptionByFcmToken('fcm-token', 'user-a');

    expect(subscriptions.deleteOne).toHaveBeenCalledWith({
      fcmToken: 'fcm-token',
      userId: 'user-a',
    });
    expect(exec).toHaveBeenCalled();
  });
});
