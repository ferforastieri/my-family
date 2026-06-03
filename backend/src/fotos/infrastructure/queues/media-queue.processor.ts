import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QUEUE_NAMES, type MediaJob } from '@shared/infrastructure/queue';
import { UploadService } from '@shared/infrastructure/upload';

@Processor(QUEUE_NAMES.media)
export class MediaQueueProcessor extends WorkerHost {
  constructor(private upload: UploadService) {
    super();
  }

  async process(job: Job<MediaJob>) {
    if (job.name !== 'process') return null;
    return this.upload.processMedia(job.data.relativePath);
  }
}
