import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  NotificationDocument,
  NotificationMongoDocument,
  PushSubscriptionDocument,
  PushSubscriptionMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type {
  NotificationEntity,
  PushSubscriptionEntity,
} from '@notifications/domain/entities/notification.entity';
import type { NotificationType } from '../../interfaces/dto/notification.dto';

export type NotificationWrite = {
  title: string;
  body?: string;
  url?: string;
  icon?: string | null;
  type?: NotificationType;
};

@Injectable()
export class NotificationsRepository {
  constructor(
    @InjectModel(NotificationDocument.name)
    private notifications: Model<NotificationMongoDocument>,
    @InjectModel(PushSubscriptionDocument.name)
    private subscriptions: Model<PushSubscriptionMongoDocument>,
  ) {}

  private toNotification(
    doc: NotificationMongoDocument | null,
  ): NotificationEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      title: doc.title,
      body: doc.body ?? '',
      url: doc.url ?? '/',
      icon: doc.icon ?? null,
      type: doc.type ?? 'manual',
      readBy: doc.readBy ?? [],
      createdAt: doc.createdAt,
    };
  }

  private toSubscription(
    doc: PushSubscriptionMongoDocument | null,
  ): PushSubscriptionEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      fcmToken: doc.fcmToken ?? null,
      userId: doc.userId ?? null,
      platform: doc.platform ?? 'unknown',
      userAgent: doc.userAgent ?? null,
      createdAt: doc.createdAt,
    };
  }

  async list(query?: PaginationQuery & { type?: string }) {
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 30,
      maxLimit: 100,
    });
    const match =
      query?.type &&
      ['manual', 'push', 'chat', 'location', 'letter', 'system'].includes(
        query.type,
      )
        ? query.type === 'manual'
          ? { $or: [{ type: 'manual' }, { type: { $exists: false } }] }
          : { type: query.type }
        : {};
    const [result] = await this.notifications
      .aggregate<{
        items: NotificationMongoDocument[];
        total: Array<{ count: number }>;
      }>([
        { $match: match },
        { $sort: { createdAt: -1 } },
        {
          $group: {
            _id: {
              title: '$title',
              body: '$body',
              url: '$url',
              type: '$type',
            },
            row: { $first: '$$ROOT' },
          },
        },
        { $replaceRoot: { newRoot: '$row' } },
        { $sort: { createdAt: -1 } },
        {
          $facet: {
            items: [{ $skip: skip }, { $limit: limit }],
            total: [{ $count: 'count' }],
          },
        },
      ])
      .exec();
    const docs = result?.items ?? [];
    const total = result?.total?.[0]?.count ?? 0;
    return paginated(
      docs.map((doc) => this.toNotification(doc)!),
      total,
      page,
      limit,
    );
  }

  async findById(id: string) {
    return this.toNotification(await this.notifications.findById(id).exec());
  }

  async create(data: NotificationWrite) {
    return this.toNotification(
      await this.notifications.create({
        title: data.title,
        body: data.body ?? '',
        url: data.url ?? '/',
        icon: data.icon ?? null,
        type: data.type ?? 'manual',
      }),
    )!;
  }

  async upsertByContent(data: NotificationWrite) {
    const normalized = {
      title: data.title,
      body: data.body ?? '',
      url: data.url ?? '/',
      icon: data.icon ?? null,
      type: data.type ?? 'push',
    };
    return this.toNotification(
      await this.notifications
        .findOneAndUpdate(
          {
            title: normalized.title,
            body: normalized.body,
            url: normalized.url,
            type: normalized.type,
          },
          { $set: normalized, $setOnInsert: { createdAt: new Date() } },
          { upsert: true, new: true },
        )
        .exec(),
    )!;
  }

  async update(id: string, data: Partial<NotificationWrite>) {
    return this.toNotification(
      await this.notifications
        .findByIdAndUpdate(id, { $set: cleanUndefined(data) }, { new: true })
        .exec(),
    );
  }

  async delete(id: string) {
    return !!(await this.notifications.findByIdAndDelete(id).exec());
  }

  async markRead(id: string, userId: string) {
    return this.toNotification(
      await this.notifications
        .findByIdAndUpdate(id, { $addToSet: { readBy: userId } }, { new: true })
        .exec(),
    );
  }

  async markAllRead(userId: string) {
    const result = await this.notifications
      .updateMany(
        { readBy: { $ne: userId } },
        { $addToSet: { readBy: userId } },
      )
      .exec();
    return result.modifiedCount;
  }

  async clear() {
    await this.notifications.deleteMany({}).exec();
  }

  async upsertFcmToken(data: {
    fcmToken: string;
    userId: string;
    platform?: 'web' | 'android' | 'ios' | 'unknown';
    userAgent?: string;
  }) {
    await this.subscriptions
      .findOneAndUpdate(
        { fcmToken: data.fcmToken },
        { $set: data, $setOnInsert: { createdAt: new Date() } },
        { upsert: true },
      )
      .exec();
  }

  async removeSubscriptionByFcmToken(fcmToken: string) {
    await this.subscriptions.deleteOne({ fcmToken }).exec();
  }

  async listSubscriptions() {
    return (await this.subscriptions.find().exec()).map(
      (doc) => this.toSubscription(doc)!,
    );
  }

  async listSubscriptionsForUsers(userIds: string[]) {
    if (userIds.length === 0) return [];
    return (
      await this.subscriptions.find({ userId: { $in: userIds } }).exec()
    ).map((doc) => this.toSubscription(doc)!);
  }

  async deleteSubscription(id: string) {
    await this.subscriptions.findByIdAndDelete(id).exec();
  }
}
