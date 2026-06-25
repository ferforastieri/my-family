import { UsePipes, ValidationPipe } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UserService } from '../../application/services/user.service';
import { WsSessionService } from '../../application/services/ws-session.service';
import { UpdateUserMessageDto } from '../dto/user.dto';
import { emitToTenant } from '@tenancy/application/tenant-context';
import {
  IdMessageDto,
  PaginationMessageDto,
} from '@shared/interfaces/websocket/websocket.dto';

@WebSocketGateway()
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
export class UsersGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private users: UserService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('users.list')
  async listUsers(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationMessageDto,
  ) {
    await this.session.requireAdmin(client);
    return this.users.list(query);
  }

  @SubscribeMessage('users.update')
  async updateUser(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: UpdateUserMessageDto,
  ) {
    await this.session.requireAdmin(client);
    const row = await this.users.update(body.id, {
      name: body.name,
      role: body.role,
      access: body.access,
      password: body.password,
    });
    if (row) emitToTenant(this.server, 'users.updated', row);
    return row ? { message: 'Usuário atualizado.', ...row } : row;
  }

  @SubscribeMessage('users.delete')
  async deleteUser(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: IdMessageDto,
  ) {
    await this.session.requireAdmin(client);
    const ok = await this.users.delete(body.id);
    if (ok) emitToTenant(this.server, 'users.deleted', { id: body.id });
    return { ok, message: 'Usuário removido.' };
  }
}
