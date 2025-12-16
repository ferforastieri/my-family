import { Module } from '@nestjs/common';
import { FotosController } from './fotos.controller';
import { FotosService } from './fotos.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';

@Module({
  imports: [DatabaseModule],
  controllers: [FotosController],
  providers: [FotosService],
  exports: [FotosService],
})
export class FotosModule {}


