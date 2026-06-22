import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Req,
  Body,
  Param,
  NotFoundException,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import type { Request } from 'express';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { NotificationsService } from '../../application/services/notifications.service';
import { NotificationSchedulerService } from '../../application/services/notification-scheduler.service';
import {
  FcmSubscriptionDto,
  NotificationCreateDto,
  NotificationSendDto,
} from '../dto/notification.dto';
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
  async subscribe(
    @Req() request: Request & { user: UserEntity },
    @Body() body: { subscription: FcmSubscriptionDto; userAgent?: string },
  ) {
    if (body.subscription?.token) {
      await this.notifications.pushSubscribe(
        body.subscription,
        request.user,
        body.userAgent,
      );
    }
    return { ok: true, message: 'Notificações ativadas.' };
  }

  @Post('unsubscribe')
  async unsubscribe(@Body() body: { token: string }) {
    if (body.token) await this.notifications.pushUnsubscribe(body.token);
    return { ok: true, message: 'Notificações desativadas.' };
  }

  @Delete()
  async clear() {
    await this.notifications.clearAll();
    return { ok: true, message: 'Notificações limpas.' };
  }

  @Get('scheduled/list')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async scheduledList() {
    return this.scheduler.list();
  }

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async one(@Param('id') id: string) {
    const n = await this.notifications.findOne(id);
    if (!n) throw new NotFoundException('Notificação não encontrada');
    return n;
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async create(@Body() dto: NotificationCreateDto) {
    const row = await this.notifications.create(dto);
    return { message: 'Notificação salva.', ...row };
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async update(
    @Param('id') id: string,
    @Body() dto: Partial<NotificationCreateDto>,
  ) {
    const n = await this.notifications.update(id, dto);
    if (!n) throw new NotFoundException('Notificação não encontrada');
    return { message: 'Notificação atualizada.', ...n };
  }

  @Delete('scheduled/:id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async deleteScheduled(@Param('id') id: string) {
    const ok = await this.scheduler.delete(id);
    if (!ok) throw new NotFoundException('Agendamento não encontrado');
    return { ok, message: 'Agendamento removido.' };
  }

  @Post('send')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async sendNow(@Body() body: NotificationSendDto) {
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    const row = await this.notifications.send(body.title, body.body, body.url);
    return { message: 'Notificação enviada.', ...row };
  }

  @Post('schedule')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async schedule(
    @Body()
    body: {
      title: string;
      body?: string;
      url?: string;
      scheduledAt: string;
    },
  ) {
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    if (!body?.scheduledAt)
      throw new BadRequestException('scheduledAt é obrigatório (ISO 8601)');
    const at = new Date(body.scheduledAt);
    if (Number.isNaN(at.getTime()))
      throw new BadRequestException('scheduledAt inválido');
    const row = await this.scheduler.schedule(body);
    return { message: 'Notificação agendada.', ...row };
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async delete(@Param('id') id: string) {
    const ok = await this.notifications.delete(id);
    if (!ok) throw new NotFoundException('Notificação não encontrada');
    return { ok, message: 'Notificação removida.' };
  }
}
