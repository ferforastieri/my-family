import { Module } from '@nestjs/common';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { NotasService } from './application/services/notas.service';
import { NotasRepository } from './infrastructure/repositories/notas.repository';
import { NotasController } from './interfaces/controllers/notas.controller';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  controllers: [NotasController],
  providers: [NotasService, NotasRepository],
  exports: [NotasService],
})
export class NotasModule {}
