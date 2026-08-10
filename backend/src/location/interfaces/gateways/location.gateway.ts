import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';

@WebSocketGateway({ cors: { origin: '*' } })
export class LocationGateway {
  @WebSocketServer()
  private server?: Server;

  emitLocationUpdated(row: unknown) {
    this.server?.emit('location.updated', row);
  }

  emitPlacesChanged(row: unknown) {
    this.server?.emit('location.places.changed', row);
  }
}
