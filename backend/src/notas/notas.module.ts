import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { NotasService } from './application/services/notas.service';
import { NotasRepository } from './infrastructure/repositories/notas.repository';
import { NotasGateway } from './interfaces/gateways/notas.gateway';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  providers: [NotasService, NotasRepository, NotasGateway],
  exports: [NotasService],
})
export class NotasModule {}
