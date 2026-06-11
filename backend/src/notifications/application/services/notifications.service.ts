import { Injectable, Logger } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import * as admin from 'firebase-admin';
import { NotificationsRepository } from '../../infrastructure/repositories/notifications.repository';
import { NotificationsRealtimeGateway } from '../../interfaces/gateways/notifications-realtime.gateway';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import {
  FcmSubscriptionDto,
  NotificationCreateDto,
  NotificationSendDto,
} from '../../interfaces/dto/notification.dto';
import { notificationFactory } from '../factories/notification.factory';
import { notificationMapper } from '../mappers/notification.mapper';
import type { UserEntity } from '@auth/domain/entities/user.entity';

export type ChatPush = {
  conversationId: string;
  conversationTitle: string;
  conversationType: 'global' | 'direct';
  senderId: string;
  senderName: string;
  recipientUserIds: string[];
  text?: string | null;
  mediaType?: 'image' | 'video' | 'sticker' | null;
};

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private fcmEnabled = false;

  constructor(
    private repository: NotificationsRepository,
    private env: Environment,
    private realtime: NotificationsRealtimeGateway,
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

  async list(query?: PaginationQuery, user?: UserEntity | null) {
    const page = await this.repository.list(query);
    return {
      ...page,
      items: page.items.map((r) => this.toDto(r, user)),
    };
  }

  async findOne(id: string, user?: UserEntity | null) {
    const row = await this.repository.findById(id);
    return row ? this.toDto(row, user) : null;
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

  async markRead(id: string, user: UserEntity) {
    const row = await this.repository.markRead(id, user.id);
    return row ? this.toDto(row, user) : null;
  }

  markAllRead(user: UserEntity) {
    return this.repository.markAllRead(user.id);
  }

  private toDto(
    row: Parameters<typeof notificationMapper.toDto>[0],
    user?: UserEntity | null,
  ) {
    return {
      ...notificationMapper.toDto(row),
      read: user ? row.readBy.includes(user.id) : false,
    };
  }

  async pushSubscribe(
    subscription: FcmSubscriptionDto,
    user: UserEntity,
    userAgent?: string,
  ) {
    await this.repository.upsertFcmToken({
      fcmToken: subscription.token,
      userId: user.id,
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
    const row = await this.repository.upsertByContent(
      notificationFactory.createPush(dto),
    );
    this.realtime.emitNotificationUpdated(notificationMapper.toDto(row));
    return this.sendNow(title, body, url);
  }

  async sendNow(
    title: string,
    body?: string,
    url?: string,
  ): Promise<{ sent: number }> {
    if (!this.fcmEnabled) {
      this.logger.warn(
        'FCM desativado. Configure FIREBASE_SERVICE_ACCOUNT_PATH ou FIREBASE_SERVICE_ACCOUNT_JSON.',
      );
      return { sent: 0 };
    }

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
              icon: 'ic_notification',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        });
        sent++;
      } catch (error) {
        const code =
          typeof error === 'object' && error !== null && 'code' in error
            ? String((error as { code?: unknown }).code)
            : '';
        this.logger.warn(
          `Falha ao enviar push para ${sub.platform}: ${code || String(error)}`,
        );
        if (
          code.includes('registration-token-not-registered') ||
          code.includes('invalid-registration-token')
        ) {
          try {
            await this.repository.deleteSubscription(sub.id);
          } catch {
            //
          }
        }
      }
    }
    return { sent };
  }

  async sendChatMessage(push: ChatPush): Promise<{ sent: number }> {
    const recipientIds = Array.from(
      new Set(push.recipientUserIds.filter((id) => id !== push.senderId)),
    );
    if (!this.fcmEnabled || recipientIds.length === 0) return { sent: 0 };

    const subscriptions =
      await this.repository.listSubscriptionsForUsers(recipientIds);
    const title =
      push.conversationType === 'global'
        ? `${push.senderName} em ${push.conversationTitle}`
        : push.senderName;
    const body = this.chatPreview(push);
    let sent = 0;

    for (const subscription of subscriptions) {
      if (!subscription.fcmToken) continue;
      try {
        await admin.messaging().send({
          token: subscription.fcmToken,
          notification: { title, body },
          data: {
            type: 'chat',
            url: `/chat?conversationId=${push.conversationId}`,
            conversationId: push.conversationId,
            senderId: push.senderId,
            senderName: push.senderName,
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'chat_messages',
              icon: 'ic_notification',
              sound: 'default',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
              tag: `chat-${push.conversationId}`,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                threadId: `chat-${push.conversationId}`,
              },
            },
          },
        });
        sent++;
      } catch (error) {
        await this.handlePushError(
          subscription.id,
          subscription.platform,
          error,
        );
      }
    }
    return { sent };
  }

  private chatPreview(push: ChatPush) {
    const text = push.text?.trim();
    if (text) return text.length > 120 ? `${text.slice(0, 117)}...` : text;
    if (push.mediaType === 'image') return 'Foto';
    if (push.mediaType === 'video') return 'Vídeo';
    if (push.mediaType === 'sticker') return 'Figurinha';
    return 'Nova mensagem';
  }

  private async handlePushError(
    subscriptionId: string,
    platform: string | null | undefined,
    error: unknown,
  ) {
    const code =
      typeof error === 'object' && error !== null && 'code' in error
        ? String((error as { code?: unknown }).code)
        : '';
    this.logger.warn(
      `Falha ao enviar push para ${platform}: ${code || String(error)}`,
    );
    if (
      code.includes('registration-token-not-registered') ||
      code.includes('invalid-registration-token')
    ) {
      await this.repository.deleteSubscription(subscriptionId);
    }
  }
}
