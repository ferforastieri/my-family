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
  NotFoundException,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { NotificationsService } from '../../application/notifications.service';
import { NotificationSchedulerService } from '../../application/notification-scheduler.service';
import { FcmSubscriptionDto, NotificationCreateDto, NotificationSendDto } from '../dto/notification.dto';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { RolesGuard } from '@auth/guards/roles.guard';
import { Roles } from '@auth/decorators/roles.decorator';
@Controller('notifications')
export class NotificationsController {
  constructor(
    private notifications: NotificationsService,
    private scheduler: NotificationSchedulerService,
  ) {}

  @Get()
  async list() {
    return this.notifications.list();
  }

  @Post('subscribe')
  @HttpCode(HttpStatus.NO_CONTENT)
  async subscribe(@Body() body: { subscription: FcmSubscriptionDto; userAgent?: string }) {
    if (body.subscription?.token) {
      await this.notifications.pushSubscribe(body.subscription, body.userAgent);
    }
  }

  @Post('unsubscribe')
  @HttpCode(HttpStatus.NO_CONTENT)
  async unsubscribe(@Body() body: { token: string }) {
    if (body.token) await this.notifications.pushUnsubscribe(body.token);
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  async clear() {
    await this.notifications.clearAll();
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async one(@Param('id') id: string) {
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
  async update(@Param('id') id: string, @Body() dto: Partial<NotificationCreateDto>) {
    const n = await this.notifications.update(id, dto);
    if (!n) throw new NotFoundException('Notificação não encontrada');
    return n;
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async delete(@Param('id') id: string) {
    const ok = await this.notifications.delete(id);
    if (!ok) throw new NotFoundException('Notificação não encontrada');
  }

  @Post('send')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async sendNow(@Body() body: NotificationSendDto) {
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
    return this.scheduler.schedule(body);
  }
}
