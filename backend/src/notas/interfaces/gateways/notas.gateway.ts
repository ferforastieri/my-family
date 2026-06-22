import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { NotasService } from '../../application/services/notas.service';
import type { NotaWriteDto } from '../dto/nota.dto';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { emitToTenant } from '@tenancy/application/tenant-context';

@WebSocketGateway({ cors: { origin: '*' } })
export class NotasGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private notas: NotasService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('notas.list')
  async list(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAccess(client, 'notas');
    return this.notas.findAll(query);
  }

  @SubscribeMessage('notas.create')
  async create(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: NotaWriteDto,
  ) {
    await this.session.requireAccess(client, 'notas');
    const row = await this.notas.create(data);
    emitToTenant(this.server, 'notas.created', row);
    return { message: 'Nota salva com sucesso.', ...row };
  }

  @SubscribeMessage('notas.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<NotaWriteDto> },
  ) {
    await this.session.requireAccess(client, 'notas');
    const row = await this.notas.update(body.id, body.data);
    if (row) emitToTenant(this.server, 'notas.updated', row);
    return row ? { message: 'Nota atualizada.', ...row } : row;
  }

  @SubscribeMessage('notas.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAccess(client, 'notas');
    const ok = await this.notas.delete(body.id);
    if (ok) emitToTenant(this.server, 'notas.deleted', { id: body.id });
    return { ok, message: 'Nota removida.' };
  }
}
