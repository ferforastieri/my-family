import { ConnectedSocket, MessageBody, SubscribeMessage, WebSocketGateway } from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/ws-session.service';
import { MusicasService } from '../../application/musicas.service';
import type { MusicaWrite } from '../../infrastructure/repositories/musicas.repository';

@WebSocketGateway({ cors: { origin: '*' } })
export class MusicasGateway {
  constructor(
    private musicas: MusicasService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('musicas.list')
  list() {
    return this.musicas.findAll();
  }

  @SubscribeMessage('musicas.create')
  async create(@ConnectedSocket() client: Socket, @MessageBody() data: MusicaWrite) {
    await this.session.requireUser(client);
    return this.musicas.create(data);
  }

  @SubscribeMessage('musicas.update')
  async update(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string; data: Partial<MusicaWrite> }) {
    await this.session.requireUser(client);
    return this.musicas.update(body.id, body.data);
  }

  @SubscribeMessage('musicas.delete')
  async delete(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string }) {
    await this.session.requireUser(client);
    return { ok: await this.musicas.delete(body.id) };
  }
}
