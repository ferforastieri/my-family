import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QUEUE_NAMES, type MediaJob } from '@shared/infrastructure/queue';
import { UploadService } from '@shared/infrastructure/upload';
import { TenantContext } from '@tenancy/application/tenant-context';

@Processor(QUEUE_NAMES.media)
export class MediaQueueProcessor extends WorkerHost {
  constructor(
    private upload: UploadService,
    private tenantContext: TenantContext,
  ) {
    super();
  }

  async process(job: Job<MediaJob>) {
    if (job.name !== 'process') return null;
    return this.tenantContext.run({ tenantId: job.data.tenantId }, () =>
      this.upload.processMedia(job.data.relativePath),
    );
  }
}
