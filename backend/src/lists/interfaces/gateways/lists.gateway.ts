import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { ListsService } from '../../application/services/lists.service';
import type {
  FamilyListItemWriteDto,
  FamilyListWriteDto,
} from '../dto/list.dto';
import { ListsRealtimeGateway } from './lists-realtime.gateway';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';

@WebSocketGateway({ cors: { origin: '*' } })
export class ListsGateway {
  constructor(
    private lists: ListsService,
    private realtime: ListsRealtimeGateway,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('lists.list')
  listLists(@MessageBody() query?: PaginationQuery) {
    return this.lists.listLists(query);
  }

  @SubscribeMessage('lists.create')
  async createList(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: FamilyListWriteDto,
  ) {
    const user = await this.session.requireUser(client);
    const row = await this.lists.createList(data, user);
    this.realtime.emitListCreated(row);
    return { message: 'Lista criada.', ...row };
  }

  @SubscribeMessage('lists.update')
  async updateList(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<FamilyListWriteDto> },
  ) {
    await this.session.requireUser(client);
    const row = await this.lists.updateList(body.id, body.data);
    if (row) this.realtime.emitListUpdated(row);
    return row ? { message: 'Lista atualizada.', ...row } : row;
  }

  @SubscribeMessage('lists.delete')
  async deleteList(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireUser(client);
    const ok = await this.lists.deleteList(body.id);
    if (ok) this.realtime.emitListDeleted(body.id);
    return { ok, message: 'Lista removida.' };
  }

  @SubscribeMessage('lists.items')
  listItems(@MessageBody() body: { listId: string } & PaginationQuery) {
    return this.lists.listItems(body.listId, body);
  }

  @SubscribeMessage('lists.items.create')
  async createItem(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: FamilyListItemWriteDto,
  ) {
    const user = await this.session.requireUser(client);
    const row = await this.lists.createItem(data, user);
    this.realtime.emitItemCreated(row);
    return { message: 'Item adicionado.', ...row };
  }

  @SubscribeMessage('lists.items.update')
  async updateItem(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string; data: Partial<FamilyListItemWriteDto> },
  ) {
    await this.session.requireUser(client);
    const row = await this.lists.updateItem(body.id, body.data);
    if (row) this.realtime.emitItemUpdated(row);
    return row ? { message: 'Item atualizado.', ...row } : row;
  }

  @SubscribeMessage('lists.items.delete')
  async deleteItem(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireUser(client);
    const result = await this.lists.deleteItem(body.id);
    if (result.ok) this.realtime.emitItemDeleted(body.id, result.listId);
    return { ok: result.ok, message: 'Item removido.' };
  }
}
