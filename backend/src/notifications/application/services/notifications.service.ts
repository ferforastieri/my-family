import { Injectable } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import * as admin from 'firebase-admin';
import { NotificationsRepository } from '../../infrastructure/repositories/notifications.repository';
import { NotificationsRealtimeGateway } from '../../interfaces/gateways/notifications-realtime.gateway';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { JobsService } from '@shared/infrastructure/queue';
import {
  FcmSubscriptionDto,
  NotificationCreateDto,
  NotificationSendDto,
} from '../../interfaces/dto/notification.dto';
import { notificationFactory } from '../factories/notification.factory';
import { notificationMapper } from '../mappers/notification.mapper';

@Injectable()
export class NotificationsService {
  private fcmEnabled = false;

  constructor(
    private repository: NotificationsRepository,
    private env: Environment,
    private realtime: NotificationsRealtimeGateway,
    private jobs: JobsService,
  ) {
    const serviceAccount = this.loadFirebaseServiceAccount();
    if (serviceAccount && admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
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

  async list(query?: PaginationQuery) {
    const page = await this.repository.list(query);
    return {
      ...page,
      items: page.items.map((r) => notificationMapper.toDto(r)),
    };
  }

  async findOne(id: string) {
    const row = await this.repository.findById(id);
    return row ? notificationMapper.toDto(row) : null;
  }

  async create(data: NotificationCreateDto) {
    const row = await this.repository.create(notificationFactory.create(data));
    const dto = notificationMapper.toDto(row);
    this.realtime.emitNotificationCreated(dto);
    return dto;
  }

  async update(id: string, data: Partial<NotificationCreateDto>) {
    if (Object.keys(data).length === 0) return this.findOne(id);
    const row = await this.repository.update(id, data);
    const dto = row ? notificationMapper.toDto(row) : null;
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

  async send(
    title: string,
    body?: string,
    url?: string,
  ): Promise<{ sent: number }> {
    const dto: NotificationSendDto = { title, body, url };
    const row = await this.repository.create(
      notificationFactory.createPush(dto),
    );
    this.realtime.emitNotificationCreated(notificationMapper.toDto(row));
    await this.jobs.enqueueNotification({ title, body, url });
    return { sent: 0 };
  }

  async sendNow(
    title: string,
    body?: string,
    url?: string,
  ): Promise<{ sent: number }> {
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
