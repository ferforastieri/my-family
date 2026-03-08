import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  HttpCode,
  HttpStatus,
  ServiceUnavailableException,
} from '@nestjs/common';
import { NotificationsService, PushSubscriptionDto } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private notifications: NotificationsService) {}

  @Get()
  async list() {
    return this.notifications.list();
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  async clear() {
    await this.notifications.clearAll();
  }

  @Get('vapid-public')
  vapidPublic(): { publicKey: string } {
    const key = this.notifications.getVapidPublicKey();
    if (!key) throw new ServiceUnavailableException('Push não configurado');
    return { publicKey: key };
  }

  @Post('subscribe')
  @HttpCode(HttpStatus.NO_CONTENT)
  async subscribe(@Body() body: { subscription: PushSubscriptionDto; userAgent?: string }) {
    if (body.subscription?.endpoint && body.subscription?.keys) {
      await this.notifications.pushSubscribe(body.subscription);
    }
  }

  @Post('unsubscribe')
  @HttpCode(HttpStatus.NO_CONTENT)
  async unsubscribe(@Body() body: { endpoint: string }) {
    if (body.endpoint) await this.notifications.pushUnsubscribe(body.endpoint);
  }
}
