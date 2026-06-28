import { BadRequestException } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { NotificationsService } from '../../application/services/notifications.service';
import { NotificationSchedulerService } from '../../application/services/notification-scheduler.service';
import {
  FcmSubscribeRequestDto,
  FcmUnsubscribeDto,
  NotificationCreateDto,
  NotificationListQueryDto,
  NotificationScheduleDto,
  NotificationSendDto,
  NotificationUpdateMessageDto,
  ScheduledNotificationListQueryDto,
} from '../dto/notification.dto';
import { IdMessageDto } from '@shared/interfaces/websocket/websocket.dto';

@WebSocketGateway()
export class NotificationsGateway {
  constructor(
    private notifications: NotificationsService,
    private scheduler: NotificationSchedulerService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('notifications.list')
  async list(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: NotificationListQueryDto,
  ) {
    const user = await this.session.requireTenant(client);
    return this.notifications.list(query, user);
  }

  @SubscribeMessage('notifications.create')
  async create(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: NotificationCreateDto,
  ) {
    await this.session.requireAdmin(client);
    const row = await this.notifications.create(dto);
    return { message: 'Notificação salva.', ...row };
  }

  @SubscribeMessage('notifications.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: NotificationUpdateMessageDto,
  ) {
    await this.session.requireAdmin(client);
    const row = await this.notifications.update(body.id, body.data);
    return row ? { message: 'Notificação atualizada.', ...row } : row;
  }

  @SubscribeMessage('notifications.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: IdMessageDto,
  ) {
    await this.session.requireAdmin(client);
    return {
      ok: await this.notifications.delete(body.id),
      message: 'Notificação removida.',
    };
  }

  @SubscribeMessage('notifications.clear')
  async clear(@ConnectedSocket() client: Socket) {
    await this.session.requireAdmin(client);
    await this.notifications.clearAll();
    return { ok: true, message: 'Notificações limpas.' };
  }

  @SubscribeMessage('notifications.read')
  async read(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: IdMessageDto,
  ) {
    const user = await this.session.requireTenant(client);
    const row = await this.notifications.markRead(body.id, user);
    return row ? { message: 'Notificação lida.', ...row } : row;
  }

  @SubscribeMessage('notifications.readAll')
  async readAll(@ConnectedSocket() client: Socket) {
    const user = await this.session.requireTenant(client);
    const count = await this.notifications.markAllRead(user);
    return { ok: true, count, message: 'Notificações lidas.' };
  }

  @SubscribeMessage('notifications.send')
  async send(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: NotificationSendDto,
  ) {
    await this.session.requireAdmin(client);
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    const row = await this.notifications.send(body.title, body.body, body.url);
    return { message: 'Notificação enviada.', ...row };
  }

  @SubscribeMessage('notifications.schedule')
  async schedule(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: NotificationScheduleDto,
  ) {
    await this.session.requireAdmin(client);
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    const at = new Date(body.scheduledAt);
    if (Number.isNaN(at.getTime()))
      throw new BadRequestException('scheduledAt inválido');
    const row = await this.scheduler.schedule(body);
    return { message: 'Notificação agendada.', ...row };
  }

  @SubscribeMessage('notifications.scheduled.list')
  async listScheduled(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: ScheduledNotificationListQueryDto,
  ) {
    await this.session.requireAdmin(client);
    return this.scheduler.list(query);
  }

  @SubscribeMessage('notifications.scheduled.delete')
  async deleteScheduled(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: IdMessageDto,
  ) {
    await this.session.requireAdmin(client);
    return {
      ok: await this.scheduler.delete(body.id),
      message: 'Agendamento removido.',
    };
  }

  @SubscribeMessage('notifications.subscribe')
  async subscribe(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: FcmSubscribeRequestDto,
  ) {
    const user = await this.session.requireTenant(client);
    if (body.subscription?.token) {
      try {
        await this.notifications.pushSubscribe(
          body.subscription,
          user,
          body.userAgent,
        );
      } catch {
        return {
          ok: false,
          message:
            'Não foi possível ativar notificações agora. O app tentará novamente.',
        };
      }
    }
    return { ok: true, message: 'Notificações ativadas.' };
  }

  @SubscribeMessage('notifications.unsubscribe')
  async unsubscribe(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: FcmUnsubscribeDto,
  ) {
    const user = await this.session.requireTenant(client);
    if (body.token) await this.notifications.pushUnsubscribe(body.token, user);
    return { ok: true, message: 'Notificações desativadas.' };
  }
}
