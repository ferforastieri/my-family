import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import {
  QUEUE_NAMES,
  type NotificationJob,
} from '@shared/infrastructure/queue';
import { NotificationsService } from '../../application/services/notifications.service';
import { TenantContext } from '@tenancy/application/tenant-context';
import { ScheduledNotificationsRepository } from '../repositories/scheduled-notifications.repository';
import { NotificationsRealtimeGateway } from '../../interfaces/gateways/notifications-realtime.gateway';

@Processor(QUEUE_NAMES.notifications)
export class NotificationQueueProcessor extends WorkerHost {
  constructor(
    private notifications: NotificationsService,
    private tenantContext: TenantContext,
    private scheduled: ScheduledNotificationsRepository,
    private realtime: NotificationsRealtimeGateway,
  ) {
    super();
  }

  process(job: Job<NotificationJob>) {
    return this.tenantContext.run({ tenantId: job.data.tenantId }, async () => {
      try {
        const result = await this.notifications.sendNow(
          job.data.title,
          job.data.body,
          job.data.url,
        );
        if (job.name === 'scheduled-send' && job.data.scheduledId) {
          const row = await this.scheduled.markSent(job.data.scheduledId);
          if (row) this.realtime.emitScheduledNotificationChanged(row);
        }
        return result;
      } catch (error) {
        const attempts = Number(job.opts.attempts ?? 1);
        const finalAttempt = job.attemptsMade + 1 >= attempts;
        if (
          finalAttempt &&
          job.name === 'scheduled-send' &&
          job.data.scheduledId
        ) {
          const row = await this.scheduled.markFailed(
            job.data.scheduledId,
            error instanceof Error ? error.message : String(error),
          );
          if (row) this.realtime.emitScheduledNotificationChanged(row);
        }
        throw error;
      }
    });
  }
}
