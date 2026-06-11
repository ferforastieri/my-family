import { Module } from '@nestjs/common';
import { CartasController } from './interfaces/controllers/cartas.controller';
import { CartasService } from './application/services/cartas.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { CartasRepository } from './infrastructure/repositories/cartas.repository';
import { AuthModule } from '@auth/auth.module';
import { CartasGateway } from './interfaces/gateways/cartas.gateway';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule, NotificationsModule],
  controllers: [CartasController],
  providers: [CartasService, CartasRepository, CartasGateway],
  exports: [CartasService],
})
export class CartasModule {}
