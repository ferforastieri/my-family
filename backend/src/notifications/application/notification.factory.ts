import type { Factory } from '@shared/application/mapper';
import {
  NotificationCreateDto,
  NotificationSendDto,
} from '../interfaces/dto/notification.dto';

export type NotificationWrite = {
  title: string;
  body: string;
  url: string;
  icon?: string;
};

export class NotificationFactory implements Factory<
  NotificationCreateDto | NotificationSendDto,
  NotificationWrite
> {
  create(
    input: NotificationCreateDto | NotificationSendDto,
  ): NotificationWrite {
    return {
      title: input.title ?? 'Nossa Família',
      body: input.body ?? '',
      url: input.url ?? '/',
      icon: 'icon' in input ? input.icon : undefined,
    };
  }

  createPush(input: NotificationSendDto): NotificationWrite {
    return {
      ...this.create(input),
      icon: '/favicon-192.png',
    };
  }
}

export const notificationFactory = new NotificationFactory();
