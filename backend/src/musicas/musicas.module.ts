import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { MusicasController } from './interfaces/controllers/musicas.controller';
import { MusicasService } from './application/services/musicas.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MusicasRepository } from './infrastructure/repositories/musicas.repository';
import { AuthModule } from '@auth/auth.module';
import {
  MusicaDocument,
  MusicaSchema,
} from './infrastructure/persistence/musica.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: MusicaDocument.name, schema: MusicaSchema },
    ]),
    AuthModule,
  ],
  controllers: [MusicasController],
  providers: [MusicasService, MusicasRepository],
  exports: [MusicasService],
})
export class MusicasModule {}
