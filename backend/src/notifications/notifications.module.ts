import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { AuthModule } from '@auth/auth.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { NotificationQueueProcessor, NOTIFICATION_QUEUE_NAME } from './notification-queue.processor';
import { NotificationsRepository } from './infrastructure/notifications.repository';
import { NotificationsGateway } from './notifications.gateway';
import { NotificationsRealtimeGateway } from './notifications-realtime.gateway';

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
