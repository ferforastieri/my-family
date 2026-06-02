import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
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

@Module({
  imports: [
    DatabaseModule,
    MongoModelsModule,
    EnvironmentModule,
    AuthModule,
    BullModule.registerQueue({ name: NOTIFICATION_QUEUE_NAME }),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationsRepository, NotificationsGateway, NotificationsRealtimeGateway, NotificationQueueProcessor],
  exports: [NotificationsService, BullModule],
})
export class NotificationsModule {}
