import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import {
  QUEUE_NAMES,
  type NotificationJob,
} from '@shared/infrastructure/queue';
import { NotificationsService } from '../../application/services/notifications.service';
import { TenantContext } from '@tenancy/application/tenant-context';

@Processor(QUEUE_NAMES.notifications)
export class NotificationQueueProcessor extends WorkerHost {
  constructor(
    private notifications: NotificationsService,
    private tenantContext: TenantContext,
  ) {
    super();
  }

  process(job: Job<NotificationJob>) {
    return this.tenantContext.run(
      { tenantId: job.data.tenantId },
      () =>
        this.notifications.sendNow(
          job.data.title,
          job.data.body,
          job.data.url,
        ),
    );
  }
}
