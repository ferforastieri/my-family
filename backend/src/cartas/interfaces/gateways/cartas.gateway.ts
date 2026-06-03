import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
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
  list(@MessageBody() query?: PaginationQuery) {
    return this.cartas.findAll(query);
  }

  @SubscribeMessage('cartas.create')
  async create(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: CartaWriteDto,
  ) {
    await this.session.requireUser(client);
    const row = await this.cartas.create(data);
    this.server.emit('cartas.created', row);
    return row;
  }

  @SubscribeMessage('cartas.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<CartaWriteDto> },
  ) {
    await this.session.requireUser(client);
    const row = await this.cartas.update(body.id, body.data);
    if (row) this.server.emit('cartas.updated', row);
    return row;
  }

  @SubscribeMessage('cartas.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireUser(client);
    const ok = await this.cartas.delete(body.id);
    if (ok) this.server.emit('cartas.deleted', { id: body.id });
    return { ok };
  }
}
