import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';

@WebSocketGateway()
export class LocationGateway {
  @WebSocketServer()
  private server?: Server;
  constructor(private context: TenantContextService) {}
  private room() {
    const id = this.context.tenantId;
    return id ? this.server?.to(`tenant:${id}`) : undefined;
  }

  emitLocationUpdated(row: unknown) {
    this.room()?.emit('location.updated', row);
  }

  emitPlacesChanged(row: unknown) {
    this.room()?.emit('location.places.changed', row);
  }
}
