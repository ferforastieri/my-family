import { Module } from '@nestjs/common';
import { CartasController } from './cartas.controller';
import { CartasService } from './cartas.service';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';

@Module({
  imports: [DatabaseModule],
  controllers: [CartasController],
  providers: [CartasService],
  exports: [CartasService],
})
export class CartasModule {}


