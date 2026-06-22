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
import { emitToTenant } from '@tenancy/application/tenant-context';

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
    await this.session.requireAccess(client, 'cartas');
    return this.cartas.findAll('letter', query);
  }

  @SubscribeMessage('cartas.create')
  async create(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: CartaWriteDto,
  ) {
    const user = await this.session.requireAccess(client, 'cartas');
    const row = await this.cartas.create('letter', data, user);
    emitToTenant(this.server, 'cartas.created', row);
    return { message: 'Texto salvo.', ...row };
  }

  @SubscribeMessage('cartas.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<CartaWriteDto> },
  ) {
    await this.session.requireAccess(client, 'cartas');
    const row = await this.cartas.update(body.id, 'letter', body.data);
    if (row) emitToTenant(this.server, 'cartas.updated', row);
    return row ? { message: 'Texto atualizado.', ...row } : row;
  }

  @SubscribeMessage('cartas.delete')
  async delete(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAccess(client, 'cartas');
    const ok = await this.cartas.delete(body.id, 'letter');
    if (ok) emitToTenant(this.server, 'cartas.deleted', { id: body.id });
    return { ok, message: 'Texto removido.' };
  }

  @SubscribeMessage('journey.list')
  async listJourney(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAccess(client, 'nossaHistoria');
    return this.cartas.findAll('journey', query);
  }

  @SubscribeMessage('journey.create')
  async createJourney(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: CartaWriteDto,
  ) {
    const user = await this.session.requireAccess(client, 'nossaHistoria');
    const row = await this.cartas.create('journey', data, user);
    emitToTenant(this.server, 'journey.created', row);
    return { message: 'Capítulo salvo.', ...row };
  }

  @SubscribeMessage('journey.update')
  async updateJourney(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<CartaWriteDto> },
  ) {
    await this.session.requireAccess(client, 'nossaHistoria');
    const row = await this.cartas.update(body.id, 'journey', body.data);
    if (row) emitToTenant(this.server, 'journey.updated', row);
    return row ? { message: 'Capítulo atualizado.', ...row } : row;
  }

  @SubscribeMessage('journey.delete')
  async deleteJourney(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAccess(client, 'nossaHistoria');
    const ok = await this.cartas.delete(body.id, 'journey');
    if (ok) emitToTenant(this.server, 'journey.deleted', { id: body.id });
    return { ok, message: 'Capítulo removido.' };
  }
}
