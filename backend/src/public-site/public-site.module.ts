import { Module } from '@nestjs/common';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { PublicSiteController } from './public-site.controller';
import { PublicSiteService } from './public-site.service';
import { CartasModule } from '@cartas/cartas.module';

@Module({
  imports: [MongoModelsModule, CartasModule],
  controllers: [PublicSiteController],
  providers: [PublicSiteService],
  exports: [PublicSiteService],
})
export class PublicSiteModule {}
