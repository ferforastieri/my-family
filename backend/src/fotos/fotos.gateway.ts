import { ConnectedSocket, MessageBody, SubscribeMessage, WebSocketGateway } from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { WsSessionService } from '@auth/ws-session.service';
import { FotosService } from './fotos.service';
import type { FotoWrite } from './infrastructure/fotos.repository';

@WebSocketGateway({ cors: { origin: '*' } })
export class FotosGateway {
  constructor(
    private fotos: FotosService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('fotos.list')
  list() {
    return this.fotos.findAll();
  }

  @SubscribeMessage('fotos.create')
  async create(@ConnectedSocket() client: Socket, @MessageBody() data: FotoWrite) {
    await this.session.requireUser(client);
    return this.fotos.create(data);
  }

  @SubscribeMessage('fotos.update')
  async update(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string; data: Partial<FotoWrite> }) {
    await this.session.requireUser(client);
    return this.fotos.update(body.id, body.data);
  }

  @SubscribeMessage('fotos.delete')
  async delete(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string }) {
    await this.session.requireUser(client);
    return { ok: await this.fotos.delete(body.id) };
  }
}
