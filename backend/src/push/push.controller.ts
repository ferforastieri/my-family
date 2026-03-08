import { Controller, Get, Post, Body, HttpCode, HttpStatus, ServiceUnavailableException } from '@nestjs/common';
import { PushService, PushSubscriptionDto } from './push.service';

@Controller('push')
export class PushController {
  constructor(private push: PushService) {}

  @Get('vapid-public')
  getVapidPublic(): { publicKey: string } {
    const key = this.push.getVapidPublicKey();
    if (!key) throw new ServiceUnavailableException('Push notifications are not configured');
    return { publicKey: key };
  }

  @Post('subscribe')
  @HttpCode(HttpStatus.NO_CONTENT)
  async subscribe(
    @Body() body: { subscription: PushSubscriptionDto; userAgent?: string },
  ): Promise<void> {
    if (!body.subscription?.endpoint || !body.subscription?.keys) return;
    await this.push.subscribe(body.subscription, body.userAgent);
  }

  @Post('unsubscribe')
  @HttpCode(HttpStatus.NO_CONTENT)
  async unsubscribe(@Body() body: { endpoint: string }): Promise<void> {
    if (body.endpoint) await this.push.unsubscribe(body.endpoint);
  }
}
