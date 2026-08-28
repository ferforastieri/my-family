import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QUEUE_NAMES } from '@shared/infrastructure/queue';
import { DemoService } from './demo.service';
@Processor(QUEUE_NAMES.maintenance, {
  autorun: process.env.PROCESS_ROLE === 'worker',
})
export class DemoCleanupProcessor extends WorkerHost {
  constructor(private demo: DemoService) {
    super();
  }
  process(job: Job) {
    return job.name === 'cleanup-demos' ? this.demo.cleanupExpired() : null;
  }
}
