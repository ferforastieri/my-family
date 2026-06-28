import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { NotasService } from './application/services/notas.service';
import { NotasRepository } from './infrastructure/repositories/notas.repository';
import { NotasController } from './interfaces/controllers/notas.controller';
import {
  NotaDocument,
  NotaSchema,
} from './infrastructure/persistence/nota.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: NotaDocument.name, schema: NotaSchema },
    ]),
    AuthModule,
  ],
  controllers: [NotasController],
  providers: [NotasService, NotasRepository],
  exports: [NotasService],
})
export class NotasModule {}
