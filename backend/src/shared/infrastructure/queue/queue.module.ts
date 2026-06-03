import { Global, Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import {
  Environment,
  EnvironmentModule,
} from '@shared/infrastructure/environment/environment.module';
import { QUEUE_NAMES } from './queue.constants';
import { JobsService } from './jobs.service';

@Global()
@Module({
  imports: [
    BullModule.forRootAsync({
      imports: [EnvironmentModule],
      inject: [Environment],
      useFactory: (env: Environment) => {
        if (!env.redis?.url)
          throw new Error('REDIS_URL é obrigatório para filas BullMQ');
        const url = new URL(env.redis.url);
        return {
          connection: {
            host: url.hostname,
            port: Number(url.port || 6379),
            username: url.username || undefined,
            password: url.password || undefined,
          },
        };
      },
    }),
    BullModule.registerQueue(
      { name: QUEUE_NAMES.notifications },
      { name: QUEUE_NAMES.media },
      { name: QUEUE_NAMES.location },
      { name: QUEUE_NAMES.cleanup },
    ),
  ],
  providers: [JobsService],
  exports: [BullModule, JobsService],
})
export class QueueModule {}
