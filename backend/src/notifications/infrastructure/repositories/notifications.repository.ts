import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  NotificationDocument,
  NotificationMongoDocument,
  PushSubscriptionDocument,
  PushSubscriptionMongoDocument,
} from '@shared/infrastructure/database/schemas';
import { cleanUndefined, normalizePagination, paginated, PaginationQuery, toId } from '@shared/infrastructure/database/mongo.utils';
import type { NotificationEntity, PushSubscriptionEntity } from '@shared/domain/entities';

export type NotificationWrite = {
  title: string;
  body?: string;
  url?: string;
  icon?: string | null;
};

@Injectable()
export class NotificationsRepository {
  constructor(
    @InjectModel(NotificationDocument.name) private notifications: Model<NotificationMongoDocument>,
    @InjectModel(PushSubscriptionDocument.name) private subscriptions: Model<PushSubscriptionMongoDocument>,
  ) {}

  private toNotification(doc: NotificationMongoDocument | null): NotificationEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      title: doc.title,
      body: doc.body ?? '',
      url: doc.url ?? '/',
      icon: doc.icon ?? null,
      createdAt: doc.createdAt,
    };
  }

  private toSubscription(doc: PushSubscriptionMongoDocument | null): PushSubscriptionEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      fcmToken: doc.fcmToken ?? null,
      platform: doc.platform ?? 'unknown',
      userAgent: doc.userAgent ?? null,
      createdAt: doc.createdAt,
    };
  }

  async list(query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query, { page: 1, limit: 30, maxLimit: 100 });
    const [docs, total] = await Promise.all([
      this.notifications.find().sort({ createdAt: -1 }).skip(skip).limit(limit).exec(),
      this.notifications.countDocuments().exec(),
    ]);
    return paginated(docs.map((doc) => this.toNotification(doc)!), total, page, limit);
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
      }),
    )!;
  }

  async update(id: string, data: Partial<NotificationWrite>) {
    return this.toNotification(
      await this.notifications.findByIdAndUpdate(id, { $set: cleanUndefined(data) }, { new: true }).exec(),
    );
  }

  async delete(id: string) {
    return !!(await this.notifications.findByIdAndDelete(id).exec());
  }

  async clear() {
    await this.notifications.deleteMany({}).exec();
  }

  async upsertFcmToken(data: { fcmToken: string; platform?: 'web' | 'android' | 'ios' | 'unknown'; userAgent?: string }) {
    await this.subscriptions
      .findOneAndUpdate({ fcmToken: data.fcmToken }, { $set: data, $setOnInsert: { createdAt: new Date() } }, { upsert: true })
      .exec();
  }

  async removeSubscriptionByFcmToken(fcmToken: string) {
    await this.subscriptions.deleteOne({ fcmToken }).exec();
  }

  async listSubscriptions() {
    return (await this.subscriptions.find().exec()).map((doc) => this.toSubscription(doc)!);
  }

  async deleteSubscription(id: string) {
    await this.subscriptions.findByIdAndDelete(id).exec();
  }
}
