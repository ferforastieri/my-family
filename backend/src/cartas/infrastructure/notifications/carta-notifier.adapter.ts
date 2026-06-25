import { Injectable } from '@nestjs/common';
import { NotificationsService } from '@notifications/application/services/notifications.service';
import type { CartaNotifierPort } from '../../application/ports/carta-notifier.port';

@Injectable()
export class CartaNotifierAdapter implements CartaNotifierPort {
  constructor(private readonly notifications: NotificationsService) {}

  async letterCreated(title: string, authorName: string): Promise<void> {
    await this.notifications.send(
      'Nova carta de amor',
      `${authorName} escreveu: ${title}`,
      '/carta-de-amor',
      { type: 'letter' },
    );
  }
}
