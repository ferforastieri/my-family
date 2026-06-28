import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { AuthModule } from '@auth/auth.module';
import { NotificationsService } from './application/services/notifications.service';
import { NotificationsController } from './interfaces/controllers/notifications.controller';
import { NotificationsRepository } from './infrastructure/repositories/notifications.repository';
import { NotificationsRealtimeGateway } from './interfaces/gateways/notifications-realtime.gateway';
import { NotificationSchedulerService } from './application/services/notification-scheduler.service';
import { ScheduledNotificationsRepository } from './infrastructure/repositories/scheduled-notifications.repository';
import { NotificationQueueProcessor } from './infrastructure/queues/notification-queue.processor';
import {
  NotificationDocument,
  NotificationSchema,
} from './infrastructure/persistence/notification.schema';
import {
  PushSubscriptionDocument,
  PushSubscriptionSchema,
} from './infrastructure/persistence/push-subscription.schema';
import {
  ScheduledNotificationDocument,
  ScheduledNotificationSchema,
} from './infrastructure/persistence/scheduled-notification.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: NotificationDocument.name, schema: NotificationSchema },
      { name: PushSubscriptionDocument.name, schema: PushSubscriptionSchema },
      {
        name: ScheduledNotificationDocument.name,
        schema: ScheduledNotificationSchema,
      },
    ]),
    EnvironmentModule,
    AuthModule,
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NotificationSchedulerService,
    NotificationsRepository,
    ScheduledNotificationsRepository,
    NotificationsRealtimeGateway,
    NotificationQueueProcessor,
  ],
  exports: [NotificationsService, NotificationSchedulerService],
})
export class NotificationsModule {}
