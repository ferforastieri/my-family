import { Module } from '@nestjs/common';
import { FotosController } from './interfaces/controllers/fotos.controller';
import { FotosService } from './application/fotos.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { UploadModule } from '@shared/infrastructure/upload';
import { AuthModule } from '@auth/auth.module';
import { FotosRepository } from './infrastructure/repositories/fotos.repository';
import { FotosGateway } from './interfaces/gateways/fotos.gateway';
import { MediaQueueProcessor } from './infrastructure/queues/media-queue.processor';
import { CleanupQueueProcessor } from './infrastructure/queues/cleanup-queue.processor';

@Module({
  imports: [DatabaseModule, MongoModelsModule, UploadModule, AuthModule],
  controllers: [FotosController],
  providers: [
    FotosService,
    FotosRepository,
    FotosGateway,
    MediaQueueProcessor,
    CleanupQueueProcessor,
  ],
  exports: [FotosService],
})
export class FotosModule {}
