import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { FotosController } from './interfaces/controllers/fotos.controller';
import { FotosService } from './application/services/fotos.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { UploadModule } from '@shared/infrastructure/upload';
import { AuthModule } from '@auth/auth.module';
import { FotosRepository } from './infrastructure/repositories/fotos.repository';
import { MediaQueueProcessor } from './infrastructure/queues/media-queue.processor';
import { CleanupQueueProcessor } from './infrastructure/queues/cleanup-queue.processor';
import {
  FotoDocument,
  FotoSchema,
} from './infrastructure/persistence/foto.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: FotoDocument.name, schema: FotoSchema },
    ]),
    UploadModule,
    AuthModule,
  ],
  controllers: [FotosController],
  providers: [
    FotosService,
    FotosRepository,
    MediaQueueProcessor,
    CleanupQueueProcessor,
  ],
  exports: [FotosService],
})
export class FotosModule {}
