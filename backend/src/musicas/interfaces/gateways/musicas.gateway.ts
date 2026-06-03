import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { MusicasService } from '../../application/services/musicas.service';
import type { MusicaWriteDto } from '../dto/musica.dto';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

@WebSocketGateway({ cors: { origin: '*' } })
export class MusicasGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private musicas: MusicasService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('musicas.list')
  list(@MessageBody() query?: PaginationQuery) {
    return this.musicas.findAll(query);
  }

  @SubscribeMessage('musicas.create')
  async create(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: MusicaWriteDto,
  ) {
    await this.session.requireUser(client);
    const row = await this.musicas.create(data);
    this.server.emit('musicas.created', row);
    return { message: 'Música salva com sucesso.', ...row };
  }

  @SubscribeMessage('musicas.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<MusicaWriteDto> },
  ) {
    await this.session.requireUser(client);
    const row = await this.musicas.update(body.id, body.data);
    if (row) this.server.emit('musicas.updated', row);
    return row ? { message: 'Música atualizada.', ...row } : row;
  }

  @SubscribeMessage('musicas.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireUser(client);
    const ok = await this.musicas.delete(body.id);
    if (ok) this.server.emit('musicas.deleted', { id: body.id });
    return { ok, message: 'Música removida.' };
  }
}
