import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { LocationService } from '../../application/services/location.service';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { LocationPlaceWriteDto, LocationUpdateDto } from '../dto/location.dto';

@WebSocketGateway({ cors: { origin: '*' } })
export class LocationGateway {
  @WebSocketServer()
  private server?: Server;

  constructor(
    private locations: LocationService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('location.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: LocationUpdateDto,
  ) {
    const user = await this.session.requireAccess(client, 'localizacao');
    const row = await this.locations.update(data, user);
    this.server?.emit('location.updated', row);
    return { ok: true, id: row.id, message: 'Localização atualizada.' };
  }

  @SubscribeMessage('location.latest')
  async latest(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAccess(client, 'localizacao');
    return this.locations.latest(query);
  }

  @SubscribeMessage('location.places')
  async places(@ConnectedSocket() client: Socket) {
    await this.session.requireAccess(client, 'localizacao');
    return this.locations.listPlaces();
  }

  @SubscribeMessage('location.places.create')
  async createPlace(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: LocationPlaceWriteDto,
  ) {
    await this.session.requireAccess(client, 'localizacao');
    const row = await this.locations.createPlace(data);
    this.server?.emit('location.places.changed', row);
    return { message: 'Local salvo.', ...row };
  }

  @SubscribeMessage('location.places.update')
  async updatePlace(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: LocationPlaceWriteDto },
  ) {
    await this.session.requireAccess(client, 'localizacao');
    const row = await this.locations.updatePlace(body.id, body.data);
    if (row) this.server?.emit('location.places.changed', row);
    return row ? { message: 'Local atualizado.', ...row } : row;
  }

  @SubscribeMessage('location.places.delete')
  async deletePlace(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAccess(client, 'localizacao');
    const ok = await this.locations.deletePlace(body.id);
    if (ok) this.server?.emit('location.places.changed', { id: body.id });
    return { ok, message: 'Local removido.' };
  }
}
