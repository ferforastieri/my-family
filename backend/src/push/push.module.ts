import { Module } from '@nestjs/common';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { PushService } from './push.service';
import { PushController } from './push.controller';

@Module({
  imports: [DatabaseModule, EnvironmentModule],
  controllers: [PushController],
  providers: [PushService],
  exports: [PushService],
})
export class PushModule {}
