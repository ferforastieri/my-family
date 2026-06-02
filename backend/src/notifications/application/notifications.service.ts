import { Injectable } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import * as admin from 'firebase-admin';
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

export interface FcmSubscriptionDto {
  token: string;
  platform?: 'web' | 'android' | 'ios' | 'unknown';
}

@Injectable()
export class NotificationsService {
  private fcmEnabled = false;

  constructor(
    private repository: NotificationsRepository,
    private env: Environment,
    private realtime: NotificationsRealtimeGateway,
  ) {
    const serviceAccount = this.loadFirebaseServiceAccount();
    if (serviceAccount && admin.apps.length === 0) {
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      this.fcmEnabled = true;
    } else if (admin.apps.length > 0) {
      this.fcmEnabled = true;
    }
  }

  private loadFirebaseServiceAccount(): admin.ServiceAccount | null {
    const rawJson = this.env.firebase?.serviceAccountJson;
    if (rawJson) return JSON.parse(rawJson) as admin.ServiceAccount;

    const path = this.env.firebase?.serviceAccountPath;
    if (!path) return null;
    return JSON.parse(readFileSync(path, 'utf8')) as admin.ServiceAccount;
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

  async pushSubscribe(subscription: FcmSubscriptionDto, userAgent?: string) {
    await this.repository.upsertFcmToken({
      fcmToken: subscription.token,
      platform: subscription.platform ?? 'unknown',
      userAgent,
    });
  }

  async pushUnsubscribe(token: string) {
    await this.repository.removeSubscriptionByFcmToken(token);
  }

  async send(title: string, body?: string, url?: string): Promise<{ sent: number }> {
    const row = await this.repository.create({
      title: title ?? 'Nossa Família',
      body: body ?? '',
      url: url ?? '/',
      icon: '/favicon-192.png',
    });
    this.realtime.emitNotificationCreated(this.toDto(row));
    if (!this.fcmEnabled) return { sent: 0 };

    const subs = await this.repository.listSubscriptions();
    let sent = 0;
    for (const sub of subs) {
      if (!sub.fcmToken) continue;
      try {
        await admin.messaging().send({
          token: sub.fcmToken,
          notification: {
            title: title ?? 'Nossa Família',
            body: body ?? '',
          },
          data: {
            url: url ?? '/',
          },
          webpush: {
            notification: {
              icon: '/icons/Icon-192.png',
            },
            fcmOptions: {
              link: url ?? '/',
            },
          },
          android: {
            notification: {
              icon: 'ic_launcher',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        });
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
