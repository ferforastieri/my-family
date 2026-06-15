import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { SchedulerRegistry } from '@nestjs/schedule';
import { CronJob } from 'cron';
import { NotificationsService } from './notifications.service';
import { ScheduledNotificationsRepository } from '../../infrastructure/repositories/scheduled-notifications.repository';
import { NotificationsRealtimeGateway } from '../../interfaces/gateways/notifications-realtime.gateway';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

@Injectable()
export class NotificationSchedulerService implements OnModuleInit {
  private readonly logger = new Logger(NotificationSchedulerService.name);

  constructor(
    private scheduled: ScheduledNotificationsRepository,
    private notifications: NotificationsService,
    private schedulerRegistry: SchedulerRegistry,
    private realtime: NotificationsRealtimeGateway,
  ) {}

  async onModuleInit() {
    const pending = await this.scheduled.pending();
    for (const item of pending) {
      this.registerJob(item);
    }
  }

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
    this.registerJob(row);
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

  private registerJob(row: {
    id: string;
    title: string;
    body?: string;
    url?: string;
    scheduledAt: Date;
  }) {
    const name = this.jobName(row.id);
    if (this.schedulerRegistry.doesExist('cron', name)) {
      this.schedulerRegistry.deleteCronJob(name);
    }
    const scheduledAt = new Date(row.scheduledAt);
    if (scheduledAt.getTime() <= Date.now()) {
      void this.runJob(row.id, row.title, row.body, row.url);
      return;
    }
    const job = new CronJob(scheduledAt, () => {
      void this.runJob(row.id, row.title, row.body, row.url);
    });
    this.schedulerRegistry.addCronJob(name, job);
    job.start();
  }

  private async runJob(id: string, title: string, body?: string, url?: string) {
    const name = this.jobName(id);
    try {
      await this.notifications.send(title, body, url);
      const row = await this.scheduled.markSent(id);
      if (row) this.realtime.emitScheduledNotificationChanged(row);
    } catch (error) {
      const row = await this.scheduled.markFailed(
        id,
        error instanceof Error ? error.message : String(error),
      );
      if (row) this.realtime.emitScheduledNotificationChanged(row);
      this.logger.error(
        `Falha ao enviar notificação agendada ${id}`,
        error instanceof Error ? error.stack : undefined,
      );
    } finally {
      if (this.schedulerRegistry.doesExist('cron', name)) {
        this.schedulerRegistry.deleteCronJob(name);
      }
    }
  }

  private jobName(id: string) {
    return `notification:${id}`;
  }
}
