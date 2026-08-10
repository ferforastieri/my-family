import { Module } from '@nestjs/common';
import { MusicasController } from './interfaces/controllers/musicas.controller';
import { MusicasService } from './application/services/musicas.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { MusicasRepository } from './infrastructure/repositories/musicas.repository';
import { AuthModule } from '@auth/auth.module';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  controllers: [MusicasController],
  providers: [MusicasService, MusicasRepository],
  exports: [MusicasService],
})
export class MusicasModule {}
