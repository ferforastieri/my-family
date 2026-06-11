import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QUEUE_NAMES, type LowBatteryJob } from '@shared/infrastructure/queue';
import { NotificationsService } from '../../../notifications/application/services/notifications.service';

@Processor(QUEUE_NAMES.location)
export class LocationQueueProcessor extends WorkerHost {
  constructor(private notifications: NotificationsService) {
    super();
  }

  async process(job: Job<LowBatteryJob>) {
    if (job.name !== 'low-battery') return null;
    return this.notifications.send(
      'Bateria baixa',
      `${job.data.name} está com ${job.data.batteryLevel}% de bateria.`,
      '/localizacao',
      {
        type: 'location',
        excludeUserIds: job.data.userId ? [job.data.userId] : [],
      },
    );
  }
}
