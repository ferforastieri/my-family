import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { NotificationsService } from './notifications.service';

export const NOTIFICATION_QUEUE_NAME = 'notifications';

export interface NotificationJobPayload {
  title: string;
  body?: string;
  url?: string;
}

@Processor(NOTIFICATION_QUEUE_NAME)
export class NotificationQueueProcessor extends WorkerHost {
  constructor(private notifications: NotificationsService) {
    super();
  }

  async process(job: Job<NotificationJobPayload>): Promise<unknown> {
    const { title, body, url } = job.data;
    return this.notifications.send(title, body, url);
  }
}
