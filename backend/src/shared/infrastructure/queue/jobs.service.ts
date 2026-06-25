import { InjectQueue } from '@nestjs/bullmq';
import { Injectable, OnApplicationBootstrap } from '@nestjs/common';
import { Queue } from 'bullmq';
import { QUEUE_NAMES } from './queue.constants';
import { TenantContext } from '@tenancy/application/tenant-context';

export type NotificationJob = {
  tenantId: string;
  scheduledId?: string;
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

export type PaymentJob = {
  eventId: string;
  eventType: string;
  payload: Record<string, unknown>;
};

@Injectable()
export class JobsService implements OnApplicationBootstrap {
  constructor(
    @InjectQueue(QUEUE_NAMES.notifications)
    private notifications: Queue<NotificationJob>,
    @InjectQueue(QUEUE_NAMES.media)
    private media: Queue<MediaJob>,
    @InjectQueue(QUEUE_NAMES.location)
    private location: Queue<LowBatteryJob>,
    @InjectQueue(QUEUE_NAMES.cleanup)
    private cleanup: Queue,
    @InjectQueue(QUEUE_NAMES.payments)
    private payments: Queue<PaymentJob>,
    private tenantContext: TenantContext,
  ) {}

  async onApplicationBootstrap() {
    const obsoleteSchedulers = (await this.cleanup.getJobSchedulers()).filter(
      (scheduler) => scheduler.name === 'upload-orphans',
    );
    await Promise.all(
      obsoleteSchedulers.map((scheduler) =>
        this.cleanup.removeJobScheduler(scheduler.key),
      ),
    );
    await this.cleanup.add(
      'upload-orphans-all-tenants',
      {},
      {
        jobId: 'repeat-upload-orphans-all-tenants',
        repeat: { pattern: '0 */6 * * *' },
        removeOnComplete: true,
        removeOnFail: 20,
      },
    );
  }

  enqueueNotification(data: Omit<NotificationJob, 'tenantId'>) {
    return this.notifications.add('send', this.withTenant(data), {
      attempts: 5,
      backoff: { type: 'exponential', delay: 30_000 },
      removeOnComplete: true,
      removeOnFail: 50,
    });
  }

  enqueueScheduledNotification(
    data: Omit<NotificationJob, 'tenantId'> & { scheduledId: string },
    scheduledAt: Date,
  ) {
    const payload = this.withTenant(data);
    return this.notifications.add('scheduled-send', payload, {
      jobId: this.scheduledNotificationJobId(
        payload.tenantId,
        payload.scheduledId,
      ),
      delay: Math.max(0, scheduledAt.getTime() - Date.now()),
      attempts: 5,
      backoff: { type: 'exponential', delay: 30_000 },
      removeOnComplete: true,
      removeOnFail: 50,
    });
  }

  async removeScheduledNotification(tenantId: string, scheduledId: string) {
    const job = await this.notifications.getJob(
      this.scheduledNotificationJobId(tenantId, scheduledId),
    );
    if (job) await job.remove();
  }

  enqueueMediaProcessing(data: Omit<MediaJob, 'tenantId'>) {
    return this.media.add('process', this.withTenant(data), {
      attempts: 3,
      backoff: { type: 'exponential', delay: 15_000 },
      removeOnComplete: true,
      removeOnFail: 50,
    });
  }

  enqueueLowBatteryAlert(data: Omit<LowBatteryJob, 'tenantId'>) {
    return this.location.add('low-battery', this.withTenant(data), {
      attempts: 3,
      backoff: { type: 'exponential', delay: 20_000 },
      removeOnComplete: true,
      removeOnFail: 50,
    });
  }

  enqueuePaymentEvent(data: PaymentJob) {
    return this.payments.add('stripe-event', data, {
      jobId: `stripe-${data.eventId.replace(/[^a-zA-Z0-9_-]/g, '-')}`,
      attempts: 8,
      backoff: { type: 'exponential', delay: 5_000 },
      removeOnComplete: { age: 86_400, count: 1_000 },
      removeOnFail: { age: 604_800, count: 1_000 },
    });
  }

  private withTenant<T extends object>(data: T): T & { tenantId: string } {
    return { ...data, tenantId: this.tenantContext.tenantId };
  }

  private scheduledNotificationJobId(tenantId: string, scheduledId: string) {
    return `scheduled-notification-${tenantId}-${scheduledId}`.replace(
      /[^a-zA-Z0-9_-]/g,
      '-',
    );
  }
}
