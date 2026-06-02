import { ConnectedSocket, MessageBody, SubscribeMessage, WebSocketGateway } from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/ws-session.service';
import { CartasService } from '../../application/cartas.service';
import type { CartaWrite } from '../../infrastructure/repositories/cartas.repository';

@WebSocketGateway({ cors: { origin: '*' } })
export class CartasGateway {
  constructor(
    private cartas: CartasService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('cartas.list')
  list() {
    return this.cartas.findAll();
  }

  @SubscribeMessage('cartas.create')
  async create(@ConnectedSocket() client: Socket, @MessageBody() data: CartaWrite) {
    await this.session.requireUser(client);
    return this.cartas.create(data);
  }

  @SubscribeMessage('cartas.update')
  async update(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string; data: Partial<CartaWrite> }) {
    await this.session.requireUser(client);
    return this.cartas.update(body.id, body.data);
  }

  @SubscribeMessage('cartas.delete')
  async delete(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string }) {
    await this.session.requireUser(client);
    return { ok: await this.cartas.delete(body.id) };
  }
}
