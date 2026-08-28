import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QUEUE_NAMES, type MediaJob } from '@shared/infrastructure/queue';
import { UploadService } from '@shared/infrastructure/upload';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';

@Processor(QUEUE_NAMES.media, {
  autorun: process.env.PROCESS_ROLE === 'worker',
})
export class MediaQueueProcessor extends WorkerHost {
  constructor(
    private upload: UploadService,
    private context: TenantContextService,
  ) {
    super();
  }

  async process(job: Job<MediaJob>) {
    if (job.name !== 'process') return null;
    return this.context.run(job.data.tenantId, () =>
      this.upload.processMedia(job.data.relativePath),
    );
  }
}
