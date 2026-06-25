import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';
import { emitToTenant } from '@tenancy/application/tenant-context';

@WebSocketGateway()
export class ListsRealtimeGateway {
  @WebSocketServer()
  private server?: Server;

  emitListCreated(row: unknown) {
    emitToTenant(this.server, 'lists.created', row);
  }

  emitListUpdated(row: unknown) {
    emitToTenant(this.server, 'lists.updated', row);
  }

  emitListDeleted(id: string) {
    emitToTenant(this.server, 'lists.deleted', { id });
  }

  emitItemCreated(row: unknown) {
    emitToTenant(this.server, 'lists.items.created', row);
  }

  emitItemUpdated(row: unknown) {
    emitToTenant(this.server, 'lists.items.updated', row);
  }

  emitItemDeleted(id: string, listId?: string) {
    emitToTenant(this.server, 'lists.items.deleted', { id, listId });
  }
}
