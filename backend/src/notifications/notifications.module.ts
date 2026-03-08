import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { AuthModule } from '@auth/auth.module';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { NotificationQueueProcessor, NOTIFICATION_QUEUE_NAME } from './notification-queue.processor';

@Module({
  imports: [
    DatabaseModule,
    EnvironmentModule,
    AuthModule,
    BullModule.registerQueue({ name: NOTIFICATION_QUEUE_NAME }),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationQueueProcessor],
  exports: [NotificationsService, BullModule],
})
export class NotificationsModule {}
