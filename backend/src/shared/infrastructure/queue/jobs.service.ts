import { InjectQueue } from '@nestjs/bullmq';
import { Injectable, OnApplicationBootstrap } from '@nestjs/common';
import { Queue } from 'bullmq';
import { QUEUE_NAMES } from './queue.constants';

export type NotificationJob = {
  title: string;
  body?: string;
  url?: string;
};

export type MediaJob = {
  relativePath: string;
  context?: string;
  mediaType?: 'image' | 'video' | 'unknown';
};

export type LowBatteryJob = {
  userId?: string | null;
  name: string;
  batteryLevel: number;
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
  ) {}

  async onApplicationBootstrap() {
    await this.cleanup.add(
      'upload-orphans',
      {},
      {
        jobId: 'repeat-upload-orphans',
        repeat: { pattern: '0 */6 * * *' },
        removeOnComplete: true,
        removeOnFail: 20,
      },
    );
  }

  enqueueNotification(data: NotificationJob) {
    return this.notifications.add('send', data, {
      attempts: 5,
      backoff: { type: 'exponential', delay: 30_000 },
      removeOnComplete: true,
      removeOnFail: 50,
    });
  }

  enqueueMediaProcessing(data: MediaJob) {
    return this.media.add('process', data, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 15_000 },
      removeOnComplete: true,
      removeOnFail: 50,
    });
  }

  enqueueLowBatteryAlert(data: LowBatteryJob) {
    return this.location.add('low-battery', data, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 20_000 },
      removeOnComplete: true,
      removeOnFail: 50,
    });
  }
}
