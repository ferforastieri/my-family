import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';

@WebSocketGateway({ cors: { origin: '*' } })
export class ListsRealtimeGateway {
  @WebSocketServer()
  private server?: Server;

  emitListCreated(row: unknown) {
    this.server?.emit('lists.created', row);
  }

  emitListUpdated(row: unknown) {
    this.server?.emit('lists.updated', row);
  }

  emitListDeleted(id: string) {
    this.server?.emit('lists.deleted', { id });
  }

  emitItemCreated(row: unknown) {
    this.server?.emit('lists.items.created', row);
  }

  emitItemUpdated(row: unknown) {
    this.server?.emit('lists.items.updated', row);
  }

  emitItemDeleted(id: string, listId?: string) {
    this.server?.emit('lists.items.deleted', { id, listId });
  }
}
