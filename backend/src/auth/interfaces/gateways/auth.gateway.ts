import { Body, UsePipes, ValidationPipe } from '@nestjs/common';
import { ConnectedSocket, MessageBody, SubscribeMessage, WebSocketGateway } from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { AuthService } from '../../application/auth.service';
import { UserService } from '../../application/user.service';
import { LoginDto, RegisterDto } from '../../auth.dto';
import { WsSessionService } from '../../application/ws-session.service';
import type { UserRole } from '@shared/domain/entities';

@WebSocketGateway({ cors: { origin: '*' } })
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class AuthGateway {
  constructor(
    private auth: AuthService,
    private users: UserService,
    private session: WsSessionService,
  ) {}

  @SubscribeMessage('auth.login')
  async login(@MessageBody() dto: LoginDto) {
    const user = await this.auth.validateUser(dto.email, dto.password);
    if (!user) throw new Error('Email ou senha inválidos');
    return this.auth.tokenResponse(user);
  }

  @SubscribeMessage('auth.register')
  register(@MessageBody() dto: RegisterDto) {
    return this.auth.register(dto.email, dto.password, dto.name, dto.role);
  }

  @SubscribeMessage('auth.me')
  async me(@ConnectedSocket() client: Socket) {
    const user = await this.session.requireUser(client);
    return { user: { id: user.id, email: user.email, name: user.name, role: user.role, avatarPath: user.avatarPath } };
  }

  @SubscribeMessage('auth.updateMe')
  async updateMe(@ConnectedSocket() client: Socket, @MessageBody() body: { name?: string; avatarPath?: string }) {
    const user = await this.session.requireUser(client);
    const updated = await this.users.update(user.id, { name: body.name, avatarPath: body.avatarPath });
    return { user: updated ? { id: updated.id, email: updated.email, name: updated.name, role: updated.role, avatarPath: updated.avatarPath } : null };
  }

  @SubscribeMessage('auth.forgotPassword')
  async forgotPassword(@MessageBody() body: { email: string }) {
    await this.auth.requestPasswordReset(body.email);
    return { success: true, message: 'Se o email existir, você receberá um token de recuperação por email.' };
  }

  @SubscribeMessage('auth.resetPassword')
  async resetPassword(@MessageBody() body: { token: string; newPassword: string }) {
    await this.auth.resetPassword(body.token, body.newPassword);
    return { success: true, message: 'Senha redefinida com sucesso.' };
  }

  @SubscribeMessage('users.list')
  async listUsers(@ConnectedSocket() client: Socket) {
    await this.session.requireRole(client, ['admin']);
    return this.users.list();
  }

  @SubscribeMessage('users.update')
  async updateUser(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string; name?: string; role?: UserRole }) {
    await this.session.requireRole(client, ['admin']);
    return this.users.update(body.id, { name: body.name, role: body.role });
  }

  @SubscribeMessage('users.delete')
  async deleteUser(@ConnectedSocket() client: Socket, @MessageBody() body: { id: string }) {
    await this.session.requireRole(client, ['admin']);
    return { ok: await this.users.delete(body.id) };
  }
}
