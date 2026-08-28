import { InjectQueue } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { Queue } from 'bullmq';
import { QUEUE_NAMES } from './queue.constants';
import { TenantContextService } from '../database/tenant-context';
import { createHash } from 'node:crypto';

export type NotificationJob = {
  tenantId: string;
  scheduledNotificationId?: string;
  title: string;
  body?: string;
  url?: string;
};

export type MediaJob = {
  tenantId: string;
  relativePath: string;
  context?: string;
  mediaType?: 'image' | 'video' | 'unknown';
};

export type LowBatteryJob = {
  tenantId: string;
  userId?: string | null;
  name: string;
  batteryLevel: number;
};

@Injectable()
export class JobsService {
  constructor(
    @InjectQueue(QUEUE_NAMES.notifications)
    private notifications: Queue<NotificationJob>,
    @InjectQueue(QUEUE_NAMES.media)
    private media: Queue<MediaJob>,
    @InjectQueue(QUEUE_NAMES.location)
    private location: Queue<LowBatteryJob>,
    @InjectQueue(QUEUE_NAMES.maintenance)
    private maintenance: Queue,
    private tenantContext: TenantContextService,
  ) {}

  enqueueNotification(data: Omit<NotificationJob, 'tenantId'>) {
    return this.notifications.add(
      'send',
      { ...data, tenantId: this.requireTenant() },
      {
        attempts: 5,
        backoff: { type: 'exponential', delay: 30_000 },
        removeOnComplete: true,
        removeOnFail: 50,
      },
    );
  }

  scheduleNotification(
    data: Omit<NotificationJob, 'tenantId'>,
    scheduledAt: Date,
  ) {
    const tenantId = this.requireTenant();
    return this.notifications.add(
      'scheduled-send',
      { ...data, tenantId },
      {
        jobId: `notification-${tenantId}-${data.scheduledNotificationId}`,
        delay: Math.max(0, scheduledAt.getTime() - Date.now()),
        attempts: 5,
        backoff: { type: 'exponential', delay: 30_000 },
        removeOnComplete: true,
        removeOnFail: 100,
      },
    );
  }

  removeScheduledNotification(tenantId: string, id: string) {
    return this.notifications.remove(`notification-${tenantId}-${id}`);
  }

  enqueueMediaProcessing(data: Omit<MediaJob, 'tenantId'>) {
    const tenantId = this.requireTenant();
    return this.media.add(
      'process',
      { ...data, tenantId },
      {
        jobId: `media-${tenantId}-${createHash('sha256').update(data.relativePath).digest('hex')}`,
        attempts: 3,
        backoff: { type: 'exponential', delay: 15_000 },
        removeOnComplete: { age: 3600, count: 1000 },
        removeOnFail: 50,
      },
    );
  }

  async mediaStatus(jobId: string) {
    const job = await this.media.getJob(jobId);
    if (!job || job.data.tenantId !== this.requireTenant()) return null;
    const state = await job.getState();
    return {
      id: job.id,
      state,
      progress: job.progress,
      result: state === 'completed' ? job.returnvalue : undefined,
      error: state === 'failed' ? job.failedReason : undefined,
    };
  }

  enqueueLowBatteryAlert(data: Omit<LowBatteryJob, 'tenantId'>) {
    return this.location.add(
      'low-battery',
      { ...data, tenantId: this.requireTenant() },
      {
        attempts: 3,
        backoff: { type: 'exponential', delay: 20_000 },
        removeOnComplete: true,
        removeOnFail: 50,
      },
    );
  }

  scheduleDemoCleanup() {
    return this.maintenance.add(
      'cleanup-demos',
      {},
      {
        jobId: 'cleanup-demos',
        repeat: { every: 3_600_000 },
        removeOnComplete: true,
        removeOnFail: 100,
      },
    );
  }

  private requireTenant() {
    const tenantId = this.tenantContext.tenantId;
    if (!tenantId) throw new Error('Contexto de família obrigatório para job.');
    return tenantId;
  }
}
