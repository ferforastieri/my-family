import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';

@WebSocketGateway()
export class NotificationsRealtimeGateway {
  @WebSocketServer()
  private server?: Server;
  constructor(private context: TenantContextService) {}
  private room() {
    const id = this.context.tenantId;
    return id ? this.server?.to(`tenant:${id}`) : undefined;
  }

  emitNotificationCreated(notification: unknown) {
    this.room()?.emit('notifications.created', notification);
  }

  emitNotificationUpdated(notification: unknown) {
    this.room()?.emit('notifications.updated', notification);
  }

  emitNotificationDeleted(id: string) {
    this.room()?.emit('notifications.deleted', { id });
  }

  emitNotificationsCleared() {
    this.room()?.emit('notifications.cleared');
  }

  emitScheduledNotificationChanged(notification: unknown) {
    this.room()?.emit('notifications.scheduled.changed', notification);
  }
}
