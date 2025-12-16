import { Module } from '@nestjs/common';
import { MusicasController } from './musicas.controller';
import { MusicasService } from './musicas.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';

@Module({
  imports: [DatabaseModule],
  controllers: [MusicasController],
  providers: [MusicasService],
  exports: [MusicasService],
})
export class MusicasModule {}


