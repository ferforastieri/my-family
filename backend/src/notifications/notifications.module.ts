import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ScheduleModule } from '@nestjs/schedule';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { AuthModule } from '@auth/auth.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { NotificationsService } from './application/notifications.service';
import { NotificationsController } from './interfaces/controllers/notifications.controller';
import { NotificationQueueProcessor, NOTIFICATION_QUEUE_NAME } from './infrastructure/queues/notification-queue.processor';
import { NotificationsRepository } from './infrastructure/repositories/notifications.repository';
import { NotificationsGateway } from './interfaces/gateways/notifications.gateway';
import { NotificationsRealtimeGateway } from './interfaces/gateways/notifications-realtime.gateway';
import { NotificationSchedulerService } from './application/notification-scheduler.service';
import { ScheduledNotificationsRepository } from './infrastructure/repositories/scheduled-notifications.repository';

@Module({
  imports: [
    DatabaseModule,
    MongoModelsModule,
    EnvironmentModule,
    AuthModule,
    ScheduleModule.forRoot(),
    BullModule.registerQueue({ name: NOTIFICATION_QUEUE_NAME }),
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NotificationSchedulerService,
    NotificationsRepository,
    ScheduledNotificationsRepository,
    NotificationsGateway,
    NotificationsRealtimeGateway,
    NotificationQueueProcessor,
  ],
  exports: [NotificationsService, NotificationSchedulerService, BullModule],
})
export class NotificationsModule {}
