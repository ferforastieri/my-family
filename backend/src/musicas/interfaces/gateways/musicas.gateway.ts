import { ConnectedSocket, MessageBody, SubscribeMessage, WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/ws-session.service';
import { MusicasService } from '../../application/musicas.service';
import type { MusicaWrite } from '../../infrastructure/repositories/musicas.repository';

@WebSocketGateway({ cors: { origin: '*' } })
export class MusicasGateway {
  @WebSocketServer()
  server!: Server;

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
    const row = await this.musicas.create(data);
    this.server.emit('musicas.created', row);
    return row;
  }

  @SubscribeMessage('musicas.update')
  async update(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string; data: Partial<MusicaWrite> }) {
    await this.session.requireUser(client);
    const row = await this.musicas.update(body.id, body.data);
    if (row) this.server.emit('musicas.updated', row);
    return row;
  }

  @SubscribeMessage('musicas.delete')
  async delete(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string }) {
    await this.session.requireUser(client);
    const ok = await this.musicas.delete(body.id);
    if (ok) this.server.emit('musicas.deleted', { id: body.id });
    return { ok };
  }
}
