import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '@auth/auth.module';
import { ClientPanelGateway } from './client-panel.gateway';
import { ClientPanelService } from './client-panel.service';
import {
  FotoDocument,
  FotoSchema,
} from '../fotos/infrastructure/persistence/foto.schema';
import {
  MembershipDocument,
  MembershipSchema,
} from '../tenancy/infrastructure/persistence/membership.schema';
import {
  MusicaDocument,
  MusicaSchema,
} from '../musicas/infrastructure/persistence/musica.schema';
import {
  NotificationDocument,
  NotificationSchema,
} from '../notifications/infrastructure/persistence/notification.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: MembershipDocument.name, schema: MembershipSchema },
      { name: FotoDocument.name, schema: FotoSchema },
      { name: MusicaDocument.name, schema: MusicaSchema },
      { name: NotificationDocument.name, schema: NotificationSchema },
    ]),
    AuthModule,
  ],
  providers: [ClientPanelService, ClientPanelGateway],
})
export class ClientPanelModule {}
