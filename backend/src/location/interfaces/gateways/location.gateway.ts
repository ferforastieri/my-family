import { ConnectedSocket, MessageBody, SubscribeMessage, WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/ws-session.service';
import { LocationService } from '../../application/location.service';
import type { LocationUpdateWrite } from '../../infrastructure/repositories/location.repository';

@WebSocketGateway({ cors: { origin: '*' } })
export class LocationGateway {
  @WebSocketServer()
  private server?: Server;

  constructor(
    private locations: LocationService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('location.update')
  async update(@ConnectedSocket() client: Socket, @MessageBody() data: LocationUpdateWrite) {
    const user = await this.session.getUser(client);
    const row = await this.locations.update(data, user);
    this.server?.emit('location.updated', row);
    return { ok: true, id: row.id };
  }

  @SubscribeMessage('location.latest')
  async latest(@ConnectedSocket() client: Socket) {
    await this.session.requireRole(client, ['admin']);
    return this.locations.latest();
  }
}

