import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { HomeSettingsService } from '../application/home-settings.service';
import { emitToTenant } from '@tenancy/application/tenant-context';

@WebSocketGateway()
export class HomeSettingsGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private settings: HomeSettingsService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('home.settings.get')
  async get(@ConnectedSocket() client: Socket) {
    await this.session.requireTenant(client);
    return this.settings.get();
  }

  @SubscribeMessage('home.settings.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    body: {
      events: Array<{
        title: string;
        icon: string;
        date: string;
        message: string;
        countDirection?: string;
        hidden?: boolean;
      }>;
      galleryImages?: string[];
      galleryOrder?: number;
    },
  ) {
    await this.session.requireAdmin(client);
    const settings = await this.settings.update(body);
    emitToTenant(this.server, 'home.settings.changed', settings);
    return { message: 'Datas da Home atualizadas.', ...settings };
  }
}
