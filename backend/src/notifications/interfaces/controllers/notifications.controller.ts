import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  NotFoundException,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { NotificationsService } from '../../application/services/notifications.service';
import { NotificationSchedulerService } from '../../application/services/notification-scheduler.service';
import {
  FcmSubscriptionDto,
  NotificationCreateDto,
  NotificationSendDto,
} from '../dto/notification.dto';
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
  async subscribe(
    @Body() body: { subscription: FcmSubscriptionDto; userAgent?: string },
  ) {
    if (body.subscription?.token) {
      await this.notifications.pushSubscribe(body.subscription, body.userAgent);
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

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('marido', 'esposa')
  async one(@Param('id') id: string) {
    const n = await this.notifications.findOne(id);
    if (!n) throw new NotFoundException('Notificação não encontrada');
    return n;
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('marido', 'esposa')
  async create(@Body() dto: NotificationCreateDto) {
    const row = await this.notifications.create(dto);
    return { message: 'Notificação salva.', ...row };
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('marido', 'esposa')
  async update(
    @Param('id') id: string,
    @Body() dto: Partial<NotificationCreateDto>,
  ) {
    const n = await this.notifications.update(id, dto);
    if (!n) throw new NotFoundException('Notificação não encontrada');
    return { message: 'Notificação atualizada.', ...n };
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('marido', 'esposa')
  async delete(@Param('id') id: string) {
    const ok = await this.notifications.delete(id);
    if (!ok) throw new NotFoundException('Notificação não encontrada');
    return { ok, message: 'Notificação removida.' };
  }

  @Post('send')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('marido', 'esposa')
  async sendNow(@Body() body: NotificationSendDto) {
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    const row = await this.notifications.send(body.title, body.body, body.url);
    return { message: 'Notificação enviada.', ...row };
  }

  @Post('schedule')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('marido', 'esposa')
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
}
