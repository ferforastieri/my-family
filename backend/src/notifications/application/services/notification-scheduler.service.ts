import { BadRequestException, Injectable } from '@nestjs/common';
import { ScheduledNotificationsRepository } from '../../infrastructure/repositories/scheduled-notifications.repository';
import { NotificationsRealtimeGateway } from '../../interfaces/gateways/notifications-realtime.gateway';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { JobsService } from '@shared/infrastructure/queue/jobs.service';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';

@Injectable()
export class NotificationSchedulerService {
  constructor(
    private scheduled: ScheduledNotificationsRepository,
    private realtime: NotificationsRealtimeGateway,
    private jobs: JobsService,
    private context: TenantContextService,
  ) {}

  async schedule(body: {
    title: string;
    body?: string;
    url?: string;
    scheduledAt: string | Date;
  }) {
    if (!body?.title?.trim())
      throw new BadRequestException('title é obrigatório');
    const scheduledAt = new Date(body.scheduledAt);
    if (Number.isNaN(scheduledAt.getTime()))
      throw new BadRequestException('scheduledAt inválido');
    if (scheduledAt.getTime() <= Date.now())
      throw new BadRequestException('scheduledAt deve ser no futuro');
    const row = await this.scheduled.create({
      title: body.title.trim(),
      body: body.body?.trim() ?? '',
      url: body.url?.trim() || '/',
      scheduledAt,
    });
    await this.registerJob(row);
    this.realtime.emitScheduledNotificationChanged(row);
    return {
      id: row.id,
      scheduledAt: row.scheduledAt.toISOString(),
      delayMs: row.scheduledAt.getTime() - Date.now(),
    };
  }

  list(query?: PaginationQuery & { status?: string }) {
    return this.scheduled.list(query);
  }

  async delete(id: string) {
    const tenantId = this.context.tenantId;
    if (tenantId) await this.jobs.removeScheduledNotification(tenantId, id);
    const ok = await this.scheduled.delete(id);
    if (ok)
      this.realtime.emitScheduledNotificationChanged({ id, deleted: true });
    return ok;
  }

  private registerJob(row: {
    id: string;
    title: string;
    body?: string;
    url?: string;
    scheduledAt: Date;
  }) {
    return this.jobs.scheduleNotification(
      {
        scheduledNotificationId: row.id,
        title: row.title,
        body: row.body,
        url: row.url,
      },
      new Date(row.scheduledAt),
    );
  }
}
