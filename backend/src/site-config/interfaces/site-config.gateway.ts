import { UsePipes, ValidationPipe } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { emitToTenant } from '@tenancy/application/tenant-context';
import { SiteConfigService } from '../application/site-config.service';
import { UpdateSiteConfigDto } from './site-config.dto';

@WebSocketGateway()
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
export class SiteConfigGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly sites: SiteConfigService,
    private readonly sessions: WsSessionService,
  ) {}

  @SubscribeMessage('site.config.get')
  async get(@ConnectedSocket() client: Socket) {
    await this.sessions.requireTenant(client);
    return this.sites.get();
  }

  @SubscribeMessage('site.config.update')
  async update(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: UpdateSiteConfigDto,
  ) {
    await this.sessions.requireAdmin(client);
    const config = await this.sites.update(dto);
    emitToTenant(this.server, 'site.config.changed', config);
    return { message: 'Configuração salva.', ...config };
  }

  @SubscribeMessage('site.config.publish')
  async publish(@ConnectedSocket() client: Socket) {
    await this.sessions.requireAdmin(client);
    const config = await this.sites.publish();
    emitToTenant(this.server, 'site.config.published', config);
    return { message: 'Site publicado.', ...config };
  }

  @SubscribeMessage('site.config.unpublish')
  async unpublish(@ConnectedSocket() client: Socket) {
    await this.sessions.requireAdmin(client);
    const config = await this.sites.unpublish();
    emitToTenant(this.server, 'site.config.unpublished', config);
    return { message: 'Site retirado do ar.', ...config };
  }
}
