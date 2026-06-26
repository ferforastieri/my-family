import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { NotasService } from './application/services/notas.service';
import { NotasRepository } from './infrastructure/repositories/notas.repository';
import { NotasGateway } from './interfaces/gateways/notas.gateway';
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
  providers: [NotasService, NotasRepository, NotasGateway],
  exports: [NotasService],
})
export class NotasModule {}
