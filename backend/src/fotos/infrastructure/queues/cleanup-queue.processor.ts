import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QUEUE_NAMES } from '@shared/infrastructure/queue';
import { FotosService } from '../../application/services/fotos.service';
import { TenantContext } from '@tenancy/application/tenant-context';

@Processor(QUEUE_NAMES.cleanup)
export class CleanupQueueProcessor extends WorkerHost {
  constructor(
    private fotos: FotosService,
    private tenantContext: TenantContext,
  ) {
    super();
  }

  async process(job: Job) {
    if (job.name !== 'upload-orphans') return null;
    const tenantId = String(job.data?.tenantId ?? '');
    if (!tenantId) throw new Error('Job de limpeza sem tenantId.');
    return this.tenantContext.run({ tenantId }, async () => ({
      removed: await this.fotos.cleanupOrphanUploads(),
    }));
  }
}
