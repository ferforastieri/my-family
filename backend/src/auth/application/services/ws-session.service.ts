import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Socket } from 'socket.io';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { AuthService } from './auth.service';
import {
  isAdminRole,
  type UserAccessKey,
  type UserEntity,
  type UserRole,
} from '@auth/domain/entities/user.entity';

@Injectable()
export class WsSessionService {
  constructor(
    private jwt: JwtService,
    private env: Environment,
    private auth: AuthService,
  ) {}

  private tokenFromClient(client: Socket): string | null {
    const authToken = client.handshake.auth?.token;
    const bearer = client.handshake.headers.authorization;
    if (typeof authToken === 'string' && authToken) return authToken;
    if (typeof bearer === 'string' && bearer.startsWith('Bearer '))
      return bearer.slice(7);
    return null;
  }

  async getUser(client: Socket): Promise<UserEntity | null> {
    if (client.data.user) return client.data.user as UserEntity;
    const token = this.tokenFromClient(client);
    if (!token) return null;
    try {
      const payload = this.jwt.verify<{ sub: string }>(token, {
        secret: this.env.jwt.secret,
      });
      const user = await this.auth.findById(payload.sub);
      if (user) client.data.user = user;
      return user;
    } catch {
      return null;
    }
  }

  async requireUser(client: Socket): Promise<UserEntity> {
    const user = await this.getUser(client);
    if (!user) throw new UnauthorizedException('Autenticação obrigatória');
    return user;
  }

  async requireRole(client: Socket, roles: UserRole[]): Promise<UserEntity> {
    const user = await this.requireUser(client);
    if (!roles.includes(user.role))
      throw new ForbiddenException('Acesso não autorizado para sua role.');
    return user;
  }

  async requireAdmin(client: Socket): Promise<UserEntity> {
    const user = await this.requireUser(client);
    if (!isAdminRole(user.role))
      throw new ForbiddenException('Acesso administrativo obrigatório.');
    return user;
  }

  async requireAccess(
    client: Socket,
    accessKey: UserAccessKey,
  ): Promise<UserEntity> {
    const user = await this.requireUser(client);
    if (isAdminRole(user.role) || user.access.includes(accessKey)) return user;
    throw new ForbiddenException('Acesso não liberado para este recurso.');
  }
}
