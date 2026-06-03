import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import {
  QUEUE_NAMES,
  type NotificationJob,
} from '@shared/infrastructure/queue';
import { NotificationsService } from '../../application/notifications.service';

@Processor(QUEUE_NAMES.notifications)
export class NotificationQueueProcessor extends WorkerHost {
  constructor(private notifications: NotificationsService) {
    super();
  }

  process(job: Job<NotificationJob>) {
    return this.notifications.sendNow(
      job.data.title,
      job.data.body,
      job.data.url,
    );
  }
}
