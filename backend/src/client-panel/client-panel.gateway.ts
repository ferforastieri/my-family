import {
  ConnectedSocket,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { ClientPanelService } from './client-panel.service';

@WebSocketGateway()
export class ClientPanelGateway {
  constructor(
    private readonly panel: ClientPanelService,
    private readonly sessions: WsSessionService,
  ) {}

  @SubscribeMessage('client.dashboard.get')
  async dashboard(@ConnectedSocket() client: Socket) {
    await this.sessions.requireTenant(client);
    return this.panel.dashboard();
  }
}
