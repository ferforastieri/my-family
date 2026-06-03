import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QUEUE_NAMES } from '@shared/infrastructure/queue';
import { FotosService } from '../../application/services/fotos.service';

@Processor(QUEUE_NAMES.cleanup)
export class CleanupQueueProcessor extends WorkerHost {
  constructor(private fotos: FotosService) {
    super();
  }

  async process(job: Job) {
    if (job.name !== 'upload-orphans') return null;
    const removed = await this.fotos.cleanupOrphanUploads();
    return { removed };
  }
}
