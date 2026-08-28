import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import {
  QUEUE_NAMES,
  type NotificationJob,
} from '@shared/infrastructure/queue';
import { NotificationsService } from '../../application/services/notifications.service';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';
import { ScheduledNotificationsRepository } from '../repositories/scheduled-notifications.repository';
import { NotificationsRealtimeGateway } from '../../interfaces/gateways/notifications-realtime.gateway';

@Processor(QUEUE_NAMES.notifications, {
  autorun: process.env.PROCESS_ROLE === 'worker',
})
export class NotificationQueueProcessor extends WorkerHost {
  constructor(
    private notifications: NotificationsService,
    private context: TenantContextService,
    private scheduled: ScheduledNotificationsRepository,
    private realtime: NotificationsRealtimeGateway,
  ) {
    super();
  }

  process(job: Job<NotificationJob>) {
    return this.context.run(job.data.tenantId, async () => {
      try {
        await this.notifications.sendNow(
          job.data.title,
          job.data.body,
          job.data.url,
        );
        if (job.data.scheduledNotificationId) {
          const row = await this.scheduled.markSent(
            job.data.scheduledNotificationId,
          );
          if (row) this.realtime.emitScheduledNotificationChanged(row);
        }
      } catch (error) {
        if (job.data.scheduledNotificationId)
          await this.scheduled.markFailed(
            job.data.scheduledNotificationId,
            error instanceof Error ? error.message : String(error),
          );
        throw error;
      }
    });
  }
}
