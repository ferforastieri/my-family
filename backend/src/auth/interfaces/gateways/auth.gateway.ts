import {
  Body,
  UnauthorizedException,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { AuthService } from '../../application/services/auth.service';
import { UserService } from '../../application/services/user.service';
import { LoginDto, RegisterDto } from '../dto/auth.dto';
import { WsSessionService } from '../../application/services/ws-session.service';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { UpdateUserDto } from '../dto/user.dto';

@WebSocketGateway({ cors: { origin: '*' } })
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
export class AuthGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private auth: AuthService,
    private users: UserService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('auth.login')
  async login(@MessageBody() dto: LoginDto) {
    const user = await this.auth.validateUser(dto.email, dto.password);
    if (!user) throw new UnauthorizedException('Email ou senha inválidos');
    return {
      message: 'Login realizado com sucesso.',
      ...this.auth.tokenResponse(user),
    };
  }

  @SubscribeMessage('auth.register')
  async register(@MessageBody() dto: RegisterDto) {
    const response = await this.auth.register(
      dto.email,
      dto.password,
      dto.name,
      dto.role,
    );
    this.server.emit('users.created', response.user);
    return { message: 'Cadastro realizado com sucesso.', ...response };
  }

  @SubscribeMessage('auth.me')
  async me(@ConnectedSocket() client: Socket) {
    const user = await this.session.requireUser(client);
    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        access: user.access,
        avatarPath: user.avatarPath,
      },
    };
  }

  @SubscribeMessage('auth.updateMe')
  async updateMe(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: UpdateUserDto,
  ) {
    const user = await this.session.requireUser(client);
    const updated = await this.users.update(user.id, {
      name: body.name,
      avatarPath: body.avatarPath,
    });
    if (updated) this.server.emit('users.updated', updated);
    return {
      message: 'Perfil atualizado.',
      user: updated
        ? {
            id: updated.id,
            email: updated.email,
            name: updated.name,
            role: updated.role,
            access: updated.access,
            avatarPath: updated.avatarPath,
          }
        : null,
    };
  }

  @SubscribeMessage('auth.forgotPassword')
  async forgotPassword(@MessageBody() body: { email: string }) {
    await this.auth.requestPasswordReset(body.email);
    return {
      message:
        'Se o email existir, você receberá um token de recuperação por email.',
    };
  }

  @SubscribeMessage('auth.resetPassword')
  async resetPassword(
    @MessageBody() body: { token: string; newPassword: string },
  ) {
    await this.auth.resetPassword(body.token, body.newPassword);
    return { message: 'Senha redefinida com sucesso.' };
  }

  @SubscribeMessage('users.list')
  async listUsers(
    @ConnectedSocket() client: Socket,
    @MessageBody() query?: PaginationQuery,
  ) {
    await this.session.requireAdmin(client);
    return this.users.list(query);
  }

  @SubscribeMessage('users.update')
  async updateUser(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string } & UpdateUserDto,
  ) {
    await this.session.requireAdmin(client);
    const row = await this.users.update(body.id, {
      name: body.name,
      role: body.role,
      access: body.access,
    });
    if (row) this.server.emit('users.updated', row);
    return row ? { message: 'Usuário atualizado.', ...row } : row;
  }

  @SubscribeMessage('users.delete')
  async deleteUser(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { id: string },
  ) {
    await this.session.requireAdmin(client);
    const ok = await this.users.delete(body.id);
    if (ok) this.server.emit('users.deleted', { id: body.id });
    return { ok, message: 'Usuário removido.' };
  }
}
