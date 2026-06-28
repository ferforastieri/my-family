import type { Factory } from '@shared/application/mapper';
import {
  NotificationCreateDto,
  NotificationSendDto,
  type NotificationType,
} from '../../interfaces/dto/notification.dto';

export type NotificationWrite = {
  title: string;
  body: string;
  url: string;
  icon?: string;
  type?: NotificationType;
};

export class NotificationFactory implements Factory<
  NotificationCreateDto | NotificationSendDto,
  NotificationWrite
> {
  create(
    input: NotificationCreateDto | NotificationSendDto,
  ): NotificationWrite {
    return {
      title: input.title ?? 'Sua Família',
      body: input.body ?? '',
      url: input.url ?? '/home',
      icon: 'icon' in input ? input.icon : undefined,
      type: 'type' in input ? (input.type ?? 'manual') : 'manual',
    };
  }

  createPush(input: NotificationSendDto): NotificationWrite {
    return {
      ...this.create(input),
      icon: '/favicon-192.png',
      type: 'push',
    };
  }
}

export const notificationFactory = new NotificationFactory();
