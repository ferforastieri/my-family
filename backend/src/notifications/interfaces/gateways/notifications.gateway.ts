import { BadRequestException } from '@nestjs/common';
import { ConnectedSocket, MessageBody, SubscribeMessage, WebSocketGateway } from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/ws-session.service';
import { NotificationsService, NotificationCreateDto } from '../../application/notifications.service';
import { NotificationSchedulerService } from '../../application/notification-scheduler.service';

@WebSocketGateway({ cors: { origin: '*' } })
export class NotificationsGateway {
  constructor(
    private notifications: NotificationsService,
    private scheduler: NotificationSchedulerService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('notifications.list')
  list() {
    return this.notifications.list();
  }

  @SubscribeMessage('notifications.create')
  async create(@ConnectedSocket() client: Socket, @MessageBody() dto: NotificationCreateDto) {
    await this.session.requireRole(client, ['admin']);
    return this.notifications.create(dto);
  }

  @SubscribeMessage('notifications.update')
  async update(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string; data: Partial<NotificationCreateDto> }) {
    await this.session.requireRole(client, ['admin']);
    return this.notifications.update(body.id, body.data);
  }

  @SubscribeMessage('notifications.delete')
  async delete(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string }) {
    await this.session.requireRole(client, ['admin']);
    return { ok: await this.notifications.delete(body.id) };
  }

  @SubscribeMessage('notifications.clear')
  async clear(@ConnectedSocket() client: Socket) {
    await this.session.requireUser(client);
    await this.notifications.clearAll();
    return { ok: true };
  }

  @SubscribeMessage('notifications.send')
  async send(@ConnectedSocket() client: Socket, @MessageBody() body: { title: string; body?: string; url?: string }) {
    await this.session.requireRole(client, ['admin']);
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    return this.notifications.send(body.title, body.body, body.url);
  }

  @SubscribeMessage('notifications.schedule')
  async schedule(@ConnectedSocket() client: Socket, @MessageBody() body: { title: string; body?: string; url?: string; scheduledAt: string }) {
    await this.session.requireRole(client, ['admin']);
    if (!body?.title) throw new BadRequestException('title é obrigatório');
    const at = new Date(body.scheduledAt);
    if (Number.isNaN(at.getTime())) throw new BadRequestException('scheduledAt inválido');
    return this.scheduler.schedule(body);
  }

  @SubscribeMessage('notifications.subscribe')
  async subscribe(@MessageBody() body: { subscription: { token: string; platform?: 'web' | 'android' | 'ios' | 'unknown' }; userAgent?: string }) {
    if (body.subscription?.token) {
      await this.notifications.pushSubscribe(body.subscription, body.userAgent);
    }
    return { ok: true };
  }

  @SubscribeMessage('notifications.unsubscribe')
  async unsubscribe(@MessageBody() body: { token: string }) {
    if (body.token) await this.notifications.pushUnsubscribe(body.token);
    return { ok: true };
  }
}
