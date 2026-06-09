import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { FotosService } from '../../application/services/fotos.service';
import type { FotoWriteDto } from '../dto/foto.dto';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

@WebSocketGateway({ cors: { origin: '*' } })
export class FotosGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private fotos: FotosService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('fotos.list')
  async list(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAccess(client, 'memorias');
    return this.fotos.findAll(query);
  }

  @SubscribeMessage('fotos.albums')
  async albums(@ConnectedSocket() client: Socket) {
    await this.session.requireAccess(client, 'memorias');
    return this.fotos.findAlbums();
  }

  @SubscribeMessage('fotos.create')
  async create(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: FotoWriteDto,
  ) {
    await this.session.requireAccess(client, 'memorias');
    const row = await this.fotos.create(data);
    this.server.emit('fotos.created', row);
    return { message: 'Memória salva com sucesso.', ...row };
  }

  @SubscribeMessage('fotos.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<FotoWriteDto> },
  ) {
    await this.session.requireAccess(client, 'memorias');
    const row = await this.fotos.update(body.id, body.data);
    if (row) this.server.emit('fotos.updated', row);
    return row ? { message: 'Memória atualizada.', ...row } : row;
  }

  @SubscribeMessage('fotos.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAccess(client, 'memorias');
    const ok = await this.fotos.delete(body.id);
    if (ok) this.server.emit('fotos.deleted', { id: body.id });
    return { ok, message: 'Memória removida.' };
  }
}
