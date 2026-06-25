import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QUEUE_NAMES } from '@shared/infrastructure/queue';
import { FotosService } from '../../application/services/fotos.service';
import { TenantContext } from '@tenancy/application/tenant-context';
import { TenantRepository } from '@tenancy/infrastructure/tenant.repository';

@Processor(QUEUE_NAMES.cleanup)
export class CleanupQueueProcessor extends WorkerHost {
  constructor(
    private fotos: FotosService,
    private tenantContext: TenantContext,
    private tenants: TenantRepository,
  ) {
    super();
  }

  async process(job: Job) {
    if (job.name !== 'upload-orphans-all-tenants') return null;
    const result: Array<{ tenantId: string; removed: string[] }> = [];
    for (const tenant of await this.tenants.listAllTenants()) {
      const removed = await this.tenantContext.run(
        { tenantId: tenant.id },
        () => this.fotos.cleanupOrphanUploads(),
      );
      result.push({ tenantId: tenant.id, removed });
    }
    return result;
  }
}
