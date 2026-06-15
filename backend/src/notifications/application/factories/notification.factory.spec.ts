import { notificationFactory } from './notification.factory';

describe('NotificationFactory', () => {
  it('defaults created notifications to manual', () => {
    expect(
      notificationFactory.create({
        title: 'Lembrete',
        body: 'Mensagem',
        url: '/',
      }).type,
    ).toBe('manual');
  });

  it('keeps push notifications as push', () => {
    expect(
      notificationFactory.createPush({
        title: 'Lembrete',
        body: 'Mensagem',
        url: '/',
      }).type,
    ).toBe('push');
  });
});
