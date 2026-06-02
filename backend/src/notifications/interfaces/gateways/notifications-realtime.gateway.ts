import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';

@WebSocketGateway({ cors: { origin: '*' } })
export class NotificationsRealtimeGateway {
  @WebSocketServer()
  private server?: Server;

  emitNotificationCreated(notification: unknown) {
    this.server?.emit('notifications.created', notification);
  }

  emitNotificationUpdated(notification: unknown) {
    this.server?.emit('notifications.updated', notification);
  }

  emitNotificationDeleted(id: string) {
    this.server?.emit('notifications.deleted', { id });
  }

  emitNotificationsCleared() {
    this.server?.emit('notifications.cleared');
  }
}
