import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  ScheduledNotificationDocument,
  ScheduledNotificationMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  cleanUndefined,
  normalizePagination,
  paginated,
  type PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';

export type ScheduledNotificationWrite = {
  title: string;
  body?: string;
  url?: string;
  scheduledAt: Date;
};

@Injectable()
export class ScheduledNotificationsRepository {
  constructor(
    @InjectModel(ScheduledNotificationDocument.name)
    private model: Model<ScheduledNotificationMongoDocument>,
  ) {}

  private toDto(doc: ScheduledNotificationMongoDocument | null) {
    if (!doc) return null;
    return {
      id: toId(doc),
      tenantId: doc.tenantId,
      title: doc.title,
      body: doc.body ?? '',
      url: doc.url ?? '/',
      scheduledAt: doc.scheduledAt,
      status: doc.status,
      sentAt: doc.sentAt ?? null,
      error: doc.error ?? null,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  async create(data: ScheduledNotificationWrite) {
    return this.toDto(await this.model.create({ ...data, status: 'pending' }))!;
  }

  async list(query?: PaginationQuery & { status?: string }) {
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 30,
      maxLimit: 100,
    });
    const allowed = ['pending', 'sent', 'failed', 'cancelled'];
    const match =
      query?.status && allowed.includes(query.status)
        ? { status: query.status }
        : {};
    const [items, total] = await Promise.all([
      this.model
        .find(match)
        .sort({ scheduledAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.model.countDocuments(match).exec(),
    ]);
    return paginated(
      items.map((doc) => this.toDto(doc)!),
      total,
      page,
      limit,
    );
  }

  async pending() {
    return (
      await this.model
        .find({ status: 'pending' })
        .sort({ scheduledAt: 1 })
        .exec()
    ).map((doc) => this.toDto(doc)!);
  }

  async markSent(id: string) {
    return this.toDto(
      await this.model
        .findByIdAndUpdate(
          id,
          { $set: { status: 'sent', sentAt: new Date() } },
          { new: true },
        )
        .exec(),
    );
  }

  async markFailed(id: string, error: string) {
    return this.toDto(
      await this.model
        .findByIdAndUpdate(
          id,
          {
            $set: cleanUndefined({
              status: 'failed',
              error: error.slice(0, 500),
            }),
          },
          { new: true },
        )
        .exec(),
    );
  }

  async delete(id: string) {
    return !!(await this.model.findByIdAndDelete(id).exec());
  }
}
