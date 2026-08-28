import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';

@WebSocketGateway()
export class ListsRealtimeGateway {
  @WebSocketServer()
  private server?: Server;
  constructor(private context: TenantContextService) {}
  private room() {
    const id = this.context.tenantId;
    return id ? this.server?.to(`tenant:${id}`) : undefined;
  }

  emitListCreated(row: unknown) {
    this.room()?.emit('lists.created', row);
  }

  emitListUpdated(row: unknown) {
    this.room()?.emit('lists.updated', row);
  }

  emitListDeleted(id: string) {
    this.room()?.emit('lists.deleted', { id });
  }

  emitItemCreated(row: unknown) {
    this.room()?.emit('lists.items.created', row);
  }

  emitItemUpdated(row: unknown) {
    this.room()?.emit('lists.items.updated', row);
  }

  emitItemDeleted(id: string, listId?: string) {
    this.room()?.emit('lists.items.deleted', { id, listId });
  }
}
