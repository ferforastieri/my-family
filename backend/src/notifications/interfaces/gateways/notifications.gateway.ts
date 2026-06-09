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
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import {
  NotificationCreateDto,
  NotificationSendDto,
} from '../dto/notification.dto';

@WebSocketGateway({ cors: { origin: '*' } })
export class NotificationsGateway {
  constructor(
    private notifications: NotificationsService,
    private scheduler: NotificationSchedulerService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('notifications.list')
  list(@MessageBody() query?: PaginationQuery) {
    return this.notifications.list(query);
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
    @MessageBody() body: { id: string; data: Partial<NotificationCreateDto> },
  ) {
    await this.session.requireAdmin(client);
    const row = await this.notifications.update(body.id, body.data);
    return row ? { message: 'Notificação atualizada.', ...row } : row;
  }

  @SubscribeMessage('notifications.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAdmin(client);
    return {
      ok: await this.notifications.delete(body.id),
      message: 'Notificação removida.',
    };
  }

  @SubscribeMessage('notifications.clear')
  async clear(@ConnectedSocket() client: Socket) {
    await this.session.requireUser(client);
    await this.notifications.clearAll();
    return { ok: true, message: 'Notificações limpas.' };
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
    @MessageBody()
    body: { title: string; body?: string; url?: string; scheduledAt: string },
  ) {
    await this.session.requireAdmin(client);
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    const at = new Date(body.scheduledAt);
    if (Number.isNaN(at.getTime()))
      throw new BadRequestException('scheduledAt inválido');
    const row = await this.scheduler.schedule(body);
    return { message: 'Notificação agendada.', ...row };
  }

  @SubscribeMessage('notifications.subscribe')
  async subscribe(
    @MessageBody()
    body: {
      subscription: {
        token: string;
        platform?: 'web' | 'android' | 'ios' | 'unknown';
      };
      userAgent?: string;
    },
  ) {
    if (body.subscription?.token) {
      await this.notifications.pushSubscribe(body.subscription, body.userAgent);
    }
    return { ok: true, message: 'Notificações ativadas.' };
  }

  @SubscribeMessage('notifications.unsubscribe')
  async unsubscribe(@MessageBody() body: { token: string }) {
    if (body.token) await this.notifications.pushUnsubscribe(body.token);
    return { ok: true, message: 'Notificações desativadas.' };
  }
}
