import { Module } from '@nestjs/common';
import { FotosController } from './interfaces/controllers/fotos.controller';
import { FotosService } from './application/fotos.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { UploadModule } from '@shared/infrastructure/upload';
import { AuthModule } from '@auth/auth.module';
import { FotosRepository } from './infrastructure/repositories/fotos.repository';
import { FotosGateway } from './interfaces/gateways/fotos.gateway';

@Module({
  imports: [DatabaseModule, MongoModelsModule, UploadModule, AuthModule],
  controllers: [FotosController],
  providers: [FotosService, FotosRepository, FotosGateway],
  exports: [FotosService],
})
export class FotosModule {}
