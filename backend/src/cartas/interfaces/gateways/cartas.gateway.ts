import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import type { UserAccessKey } from '@auth/domain/entities/user.entity';
import { CartasService } from '../../application/services/cartas.service';
import type { CartaWriteDto } from '../dto/carta.dto';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

@WebSocketGateway({ cors: { origin: '*' } })
export class CartasGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private cartas: CartasService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('cartas.list')
  async list(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAccess(client, this.accessKeyForQuery(query));
    return this.cartas.findAll(query);
  }

  @SubscribeMessage('cartas.create')
  async create(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: CartaWriteDto,
  ) {
    await this.session.requireAccess(client, this.accessKeyForCarta(data));
    const row = await this.cartas.create(data);
    this.server.emit('cartas.created', row);
    return { message: 'Texto salvo.', ...row };
  }

  @SubscribeMessage('cartas.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<CartaWriteDto> },
  ) {
    await this.session.requireAccess(client, this.accessKeyForCarta(body.data));
    const row = await this.cartas.update(body.id, body.data);
    if (row) this.server.emit('cartas.updated', row);
    return row ? { message: 'Texto atualizado.', ...row } : row;
  }

  @SubscribeMessage('cartas.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAccess(client, 'cartas');
    const ok = await this.cartas.delete(body.id);
    if (ok) this.server.emit('cartas.deleted', { id: body.id });
    return { ok, message: 'Texto removido.' };
  }

  private accessKeyForQuery(query?: PaginationQuery): UserAccessKey {
    const titlePrefix = (query as { titlePrefix?: string } | undefined)
      ?.titlePrefix;
    return titlePrefix?.startsWith('journey:') ? 'nossaHistoria' : 'cartas';
  }

  private accessKeyForCarta(data?: Partial<CartaWriteDto>): UserAccessKey {
    return data?.titulo?.startsWith('journey:') ? 'nossaHistoria' : 'cartas';
  }
}
