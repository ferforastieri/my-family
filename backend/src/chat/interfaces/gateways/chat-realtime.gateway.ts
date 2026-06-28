import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';
import { emitToTenant } from '@tenancy/application/tenant-context';

@WebSocketGateway()
export class ChatRealtimeGateway {
  @WebSocketServer()
  private server?: Server;

  emitToTenant(event: string, payload?: unknown) {
    emitToTenant(this.server, event, payload);
  }

  to(room: string, event: string, payload?: unknown) {
    this.server?.to(room).emit(event, payload);
  }
}
