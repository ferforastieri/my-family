import { Module } from '@nestjs/common';
import { CartasController } from './cartas.controller';
import { CartasService } from './cartas.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { CartasRepository } from './infrastructure/cartas.repository';
import { AuthModule } from '@auth/auth.module';
import { CartasGateway } from './cartas.gateway';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  controllers: [CartasController],
  providers: [CartasService, CartasRepository, CartasGateway],
  exports: [CartasService],
})
export class CartasModule {}
