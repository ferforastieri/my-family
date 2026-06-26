import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PublicSiteController } from './public-site.controller';
import { PublicSiteService } from './public-site.service';
import { CartasModule } from '@cartas/cartas.module';
import { SiteConfigModule } from '../site-config/site-config.module';
import {
  FotoDocument,
  FotoSchema,
} from '../fotos/infrastructure/persistence/foto.schema';
import {
  HomeSettingsDocument,
  HomeSettingsSchema,
} from '../home-settings/infrastructure/persistence/home-settings.schema';
import {
  MusicaDocument,
  MusicaSchema,
} from '../musicas/infrastructure/persistence/musica.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: HomeSettingsDocument.name, schema: HomeSettingsSchema },
      { name: FotoDocument.name, schema: FotoSchema },
      { name: MusicaDocument.name, schema: MusicaSchema },
    ]),
    CartasModule,
    SiteConfigModule,
  ],
  controllers: [PublicSiteController],
  providers: [PublicSiteService],
  exports: [PublicSiteService],
})
export class PublicSiteModule {}
