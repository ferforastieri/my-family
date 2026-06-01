import { Module } from '@nestjs/common';
import { FotosController } from './fotos.controller';
import { FotosService } from './fotos.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { UploadModule } from '@shared/infrastructure/upload';
import { AuthModule } from '@auth/auth.module';
import { FotosRepository } from './infrastructure/fotos.repository';
import { FotosGateway } from './fotos.gateway';

@Module({
  imports: [DatabaseModule, MongoModelsModule, UploadModule, AuthModule],
  controllers: [FotosController],
  providers: [FotosService, FotosRepository, FotosGateway],
  exports: [FotosService],
})
export class FotosModule {}
