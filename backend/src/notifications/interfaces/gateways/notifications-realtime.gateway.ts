import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';
import { emitToTenant } from '@tenancy/application/tenant-context';

@WebSocketGateway({ cors: { origin: '*' } })
export class NotificationsRealtimeGateway {
  @WebSocketServer()
  private server?: Server;

  emitNotificationCreated(notification: unknown) {
    emitToTenant(this.server, 'notifications.created', notification);
  }

  emitNotificationUpdated(notification: unknown) {
    emitToTenant(this.server, 'notifications.updated', notification);
  }

  emitNotificationDeleted(id: string) {
    emitToTenant(this.server, 'notifications.deleted', { id });
  }

  emitNotificationsCleared() {
    emitToTenant(this.server, 'notifications.cleared');
  }

  emitScheduledNotificationChanged(notification: unknown) {
    emitToTenant(this.server, 'notifications.scheduled.changed', notification);
  }
}
