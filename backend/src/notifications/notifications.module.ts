import { Module } from '@nestjs/common';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { AuthModule } from '@auth/auth.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { NotificationsService } from './application/services/notifications.service';
import { NotificationsController } from './interfaces/controllers/notifications.controller';
import { NotificationsRepository } from './infrastructure/repositories/notifications.repository';
import { NotificationsGateway } from './interfaces/gateways/notifications.gateway';
import { NotificationsRealtimeGateway } from './interfaces/gateways/notifications-realtime.gateway';
import { NotificationSchedulerService } from './application/services/notification-scheduler.service';
import { ScheduledNotificationsRepository } from './infrastructure/repositories/scheduled-notifications.repository';
import { NotificationQueueProcessor } from './infrastructure/queues/notification-queue.processor';

@Module({
  imports: [DatabaseModule, MongoModelsModule, EnvironmentModule, AuthModule],
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
  exports: [NotificationsService, NotificationSchedulerService],
})
export class NotificationsModule {}
