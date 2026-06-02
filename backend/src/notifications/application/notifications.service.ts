import { Injectable } from '@nestjs/common';
import * as webPush from 'web-push';
import { NotificationsRepository } from '../infrastructure/repositories/notifications.repository';
import { NotificationsRealtimeGateway } from '../interfaces/gateways/notifications-realtime.gateway';
import { Environment } from '@shared/infrastructure/environment/environment.module';

export interface NotificationCreateDto {
  title: string;
  body?: string;
  url?: string;
  icon?: string;
}

const LIST_LIMIT = 100;

export interface PushSubscriptionDto {
  endpoint: string;
  keys: { p256dh: string; auth: string };
  expirationTime?: number | null;
}

@Injectable()
export class NotificationsService {
  private pushEnabled = false;

  constructor(
    private repository: NotificationsRepository,
    private env: Environment,
    private realtime: NotificationsRealtimeGateway,
  ) {
    if (this.env.vapidPublicKey && this.env.vapidPrivateKey) {
      const wp = (webPush as any).default ?? webPush;
      if (wp?.setVapidDetails) {
        wp.setVapidDetails('mailto:nossa-familia@local', this.env.vapidPublicKey, this.env.vapidPrivateKey);
        this.pushEnabled = true;
      }
    }
  }

  getVapidPublicKey(): string | null {
    return this.env.vapidPublicKey ?? null;
  }

  private toDto(r: { id: string; title: string; body: string; url: string; icon?: string | null; createdAt: Date }) {
    return {
      id: r.id,
      title: r.title,
      body: r.body,
      url: r.url,
      icon: r.icon,
      at: new Date(r.createdAt).getTime(),
    };
  }

  async list() {
    const rows = await this.repository.list(LIST_LIMIT);
    return rows.map((r) => this.toDto(r));
  }

  async findOne(id: string) {
    const row = await this.repository.findById(id);
    return row ? this.toDto(row) : null;
  }

  async create(data: NotificationCreateDto) {
    const row = await this.repository.create(data);
    const dto = this.toDto(row);
    this.realtime.emitNotificationCreated(dto);
    return dto;
  }

  async update(id: string, data: Partial<NotificationCreateDto>) {
    if (Object.keys(data).length === 0) return this.findOne(id);
    const row = await this.repository.update(id, data);
    const dto = row ? this.toDto(row) : null;
    if (dto) this.realtime.emitNotificationUpdated(dto);
    return dto;
  }

  async delete(id: string): Promise<boolean> {
    const ok = await this.repository.delete(id);
    if (ok) this.realtime.emitNotificationDeleted(id);
    return ok;
  }

  async clearAll() {
    await this.repository.clear();
    this.realtime.emitNotificationsCleared();
  }

  async pushSubscribe(subscription: PushSubscriptionDto, userAgent?: string) {
    await this.repository.upsertSubscription({ endpoint: subscription.endpoint, keys: subscription.keys, userAgent });
  }

  async pushUnsubscribe(endpoint: string) {
    await this.repository.removeSubscriptionByEndpoint(endpoint);
  }

  async send(title: string, body?: string, url?: string): Promise<{ sent: number }> {
    const row = await this.repository.create({
      title: title ?? 'Nossa Família',
      body: body ?? '',
      url: url ?? '/',
      icon: '/favicon-192.png',
    });
    this.realtime.emitNotificationCreated(this.toDto(row));
    if (!this.pushEnabled) return { sent: 0 };
    const wp = (webPush as any).default ?? webPush;
    const payload = JSON.stringify({
      title: title ?? 'Nossa Família',
      body: body ?? '',
      url: url ?? '/',
      icon: '/favicon-192.png',
    });
    const subs = await this.repository.listSubscriptions();
    let sent = 0;
    for (const sub of subs) {
      try {
        await wp.sendNotification(
          { endpoint: sub.endpoint, keys: sub.keys as { p256dh: string; auth: string } },
          payload,
          { TTL: 86400 },
        );
        sent++;
      } catch {
        try {
          await this.repository.deleteSubscription(sub.id);
        } catch {
          //
        }
      }
    }
    return { sent };
  }
}
