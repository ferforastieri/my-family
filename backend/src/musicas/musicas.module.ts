import { Module } from '@nestjs/common';
import { MusicasController } from './musicas.controller';
import { MusicasService } from './musicas.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { MusicasRepository } from './infrastructure/musicas.repository';
import { AuthModule } from '@auth/auth.module';
import { MusicasGateway } from './musicas.gateway';

@Module({
  imports: [DatabaseModule, MongoModelsModule, AuthModule],
  controllers: [MusicasController],
  providers: [MusicasService, MusicasRepository, MusicasGateway],
  exports: [MusicasService],
})
export class MusicasModule {}
