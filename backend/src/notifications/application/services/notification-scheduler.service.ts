import { BadRequestException, Injectable, OnModuleInit } from '@nestjs/common';
import type { PaginationQuery } from '@shared/application/pagination';
import { JobsService } from '@shared/infrastructure/queue';
import { TenantContext } from '@tenancy/application/tenant-context';
import { TenantRepository } from '@tenancy/infrastructure/tenant.repository';
import { ScheduledNotificationsRepository } from '../../infrastructure/repositories/scheduled-notifications.repository';
import { NotificationsRealtimeGateway } from '../../interfaces/gateways/notifications-realtime.gateway';

@Injectable()
export class NotificationSchedulerService implements OnModuleInit {
  constructor(
    private readonly scheduled: ScheduledNotificationsRepository,
    private readonly jobs: JobsService,
    private readonly realtime: NotificationsRealtimeGateway,
    private readonly tenantContext: TenantContext,
    private readonly tenants: TenantRepository,
  ) {}

  async onModuleInit() {
    for (const tenant of await this.tenants.listAllTenants()) {
      await this.tenantContext.run({ tenantId: tenant.id }, async () => {
        for (const item of await this.scheduled.pending()) {
          await this.enqueue(item);
        }
      });
    }
  }

  async schedule(body: {
    title: string;
    body?: string;
    url?: string;
    scheduledAt: string | Date;
  }) {
    if (!body?.title?.trim()) {
      throw new BadRequestException('title é obrigatório');
    }
    const scheduledAt = new Date(body.scheduledAt);
    if (Number.isNaN(scheduledAt.getTime())) {
      throw new BadRequestException('scheduledAt inválido');
    }
    if (scheduledAt.getTime() <= Date.now()) {
      throw new BadRequestException('scheduledAt deve ser no futuro');
    }
    const row = await this.scheduled.create({
      title: body.title.trim(),
      body: body.body?.trim() ?? '',
      url: body.url?.trim() || '/home',
      scheduledAt,
    });
    try {
      await this.enqueue(row);
    } catch (error) {
      await this.scheduled.delete(row.id);
      throw error;
    }
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
    await this.jobs.removeScheduledNotification(
      this.tenantContext.tenantId,
      id,
    );
    const ok = await this.scheduled.delete(id);
    if (ok) {
      this.realtime.emitScheduledNotificationChanged({ id, deleted: true });
    }
    return ok;
  }

  private enqueue(row: {
    id: string;
    title: string;
    body?: string;
    url?: string;
    scheduledAt: Date;
  }) {
    return this.jobs.enqueueScheduledNotification(
      {
        scheduledId: row.id,
        title: row.title,
        body: row.body,
        url: row.url,
      },
      row.scheduledAt,
    );
  }
}
