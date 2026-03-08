import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  ServiceUnavailableException,
  NotFoundException,
  UseGuards,
  BadRequestException,
  ParseIntPipe,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { NotificationsService, PushSubscriptionDto, NotificationCreateDto } from './notifications.service';
import { NOTIFICATION_QUEUE_NAME, NotificationJobPayload } from './notification-queue.processor';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { RolesGuard } from '@auth/guards/roles.guard';
import { Roles } from '@auth/decorators/roles.decorator';
@Controller('notifications')
export class NotificationsController {
  constructor(
    private notifications: NotificationsService,
    @InjectQueue(NOTIFICATION_QUEUE_NAME) private queue: Queue,
  ) {}

  @Get()
  async list() {
    return this.notifications.list();
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

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  async clear() {
    await this.notifications.clearAll();
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async one(@Param('id', ParseIntPipe) id: number) {
    const n = await this.notifications.findOne(id);
    if (!n) throw new NotFoundException('Notificação não encontrada');
    return n;
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async create(@Body() dto: NotificationCreateDto) {
    return this.notifications.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async update(@Param('id', ParseIntPipe) id: number, @Body() dto: Partial<NotificationCreateDto>) {
    const n = await this.notifications.update(id, dto);
    if (!n) throw new NotFoundException('Notificação não encontrada');
    return n;
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async delete(@Param('id', ParseIntPipe) id: number) {
    const ok = await this.notifications.delete(id);
    if (!ok) throw new NotFoundException('Notificação não encontrada');
  }

  @Post('send')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async sendNow(@Body() body: { title: string; body?: string; url?: string }) {
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    return this.notifications.send(body.title, body.body, body.url);
  }

  @Post('schedule')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async schedule(@Body() body: { title: string; body?: string; url?: string; scheduledAt: string }) {
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    if (!body?.scheduledAt) throw new BadRequestException('scheduledAt é obrigatório (ISO 8601)');
    const at = new Date(body.scheduledAt);
    if (Number.isNaN(at.getTime())) throw new BadRequestException('scheduledAt inválido');
    const delay = at.getTime() - Date.now();
    if (delay <= 0) throw new BadRequestException('scheduledAt deve ser no futuro');
    const payload: NotificationJobPayload = { title: body.title, body: body.body, url: body.url };
    await this.queue.add('send', payload, { delay });
    return { scheduledAt: body.scheduledAt, delayMs: delay };
  }
}
