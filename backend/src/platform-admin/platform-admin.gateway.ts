import { UsePipes, ValidationPipe } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { IsString, MinLength } from 'class-validator';
import { Socket } from 'socket.io';
import { AuthService } from '@auth/application/services/auth.service';
import { WsSessionService } from '@auth/application/services/ws-session.service';
import { AuditService } from '../audit/application/audit.service';
import { PaginationMessageDto } from '@shared/interfaces/websocket/websocket.dto';
import { PlatformAdminService } from './platform-admin.service';

class StartImpersonationDto {
  @IsString()
  tenantId: string;

  @IsString()
  @MinLength(10)
  reason: string;
}

class EndImpersonationDto {
  @IsString()
  supportSessionId: string;
}

@WebSocketGateway()
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
export class PlatformAdminGateway {
  constructor(
    private readonly platform: PlatformAdminService,
    private readonly auth: AuthService,
    private readonly sessions: WsSessionService,
    private readonly audit: AuditService,
  ) {}

  @SubscribeMessage('platform.dashboard.get')
  async dashboard(@ConnectedSocket() client: Socket) {
    await this.sessions.requirePlatform(client);
    return this.platform.overview();
  }

  @SubscribeMessage('platform.tenants.list')
  async tenants(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationMessageDto,
  ) {
    await this.sessions.requirePlatform(client);
    return this.platform.listTenants(query);
  }

  @SubscribeMessage('platform.users.list')
  async users(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationMessageDto,
  ) {
    await this.sessions.requirePlatform(client);
    return this.platform.listUsers(query);
  }

  @SubscribeMessage('platform.subscriptions.list')
  async subscriptions(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationMessageDto,
  ) {
    await this.sessions.requirePlatform(client);
    return this.platform.listSubscriptions(query);
  }

  @SubscribeMessage('platform.audit.list')
  async auditLogs(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationMessageDto,
  ) {
    await this.sessions.requirePlatform(client);
    return this.platform.auditLogs(query?.page ?? 1, query?.limit ?? 30);
  }

  @SubscribeMessage('platform.impersonation.start')
  async startImpersonation(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: StartImpersonationDto,
  ) {
    const actor = await this.sessions.requirePlatform(client);
    const response = await this.auth.supportSession({
      actorUserId: actor.id,
      tenantId: dto.tenantId,
      reason: dto.reason,
    });
    await this.audit.record({
      action: 'platform.impersonation.start',
      resource: 'support',
      source: 'websocket',
      success: true,
      actorUserId: actor.id,
      actorEmail: actor.email,
      effectiveUserId: response.user.id,
      effectiveUserEmail: response.user.email,
      tenantId: response.tenant.id,
      supportSessionId: response.supportSessionId,
      metadata: { reason: dto.reason },
    });
    return { message: 'Sessão de suporte iniciada.', ...response };
  }

  @SubscribeMessage('platform.impersonation.end')
  async endImpersonation(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: EndImpersonationDto,
  ) {
    const actor = await this.sessions.requireUser(client);
    const actorUserId = actor.actorUserId ?? actor.id;
    const response = await this.auth.endSupportSession(
      dto.supportSessionId,
      actorUserId,
    );
    await this.audit.record({
      action: 'platform.impersonation.end',
      resource: 'support',
      source: 'websocket',
      success: true,
      actorUserId,
      actorEmail: actor.actorEmail ?? actor.email,
      effectiveUserId: actor.actorUserId ? actor.id : undefined,
      effectiveUserEmail: actor.actorUserId ? actor.email : undefined,
      tenantId: actor.tenantId ?? undefined,
      supportSessionId: dto.supportSessionId,
    });
    return { message: 'Sessão de suporte encerrada.', ...response };
  }
}
