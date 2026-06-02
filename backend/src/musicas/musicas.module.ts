import { Module } from '@nestjs/common';
import { MusicasController } from './interfaces/controllers/musicas.controller';
import { MusicasService } from './application/musicas.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { MusicasRepository } from './infrastructure/repositories/musicas.repository';
import { AuthModule } from '@auth/auth.module';
import { MusicasGateway } from './interfaces/gateways/musicas.gateway';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  controllers: [MusicasController],
  providers: [MusicasService, MusicasRepository, MusicasGateway],
  exports: [MusicasService],
})
export class MusicasModule {}
