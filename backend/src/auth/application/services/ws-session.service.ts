import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Socket } from 'socket.io';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { AuthService } from './auth.service';
import {
  isAdminRole,
  type AuthJwtPayload,
  type UserAccessKey,
  type UserEntity,
  type UserRole,
} from '@auth/domain/entities/user.entity';
import { tenantRoom } from '@tenancy/application/tenant-context';
import { TenantService } from '@tenancy/application/tenant.service';

@Injectable()
export class WsSessionService {
  constructor(
    private readonly jwt: JwtService,
    private readonly env: Environment,
    private readonly auth: AuthService,
    private readonly tenants: TenantService,
  ) {}

  async getUser(client: Socket): Promise<UserEntity | null> {
    const token = this.tokenFromClient(client);
    const cached = client.data.user as UserEntity | undefined;
    const cachedToken = client.data.authToken as string | undefined;
    if (cached && cachedToken === token) return cached;
    if (!token) return null;
    try {
      const payload = this.jwt.verify<AuthJwtPayload>(token, {
        secret: this.env.jwt.secret,
      });
      const user = await this.auth.resolvePayload(payload);
      if (user) {
        client.data.user = user;
        client.data.authToken = token;
        if (user.tenantId) await client.join(tenantRoom(user.tenantId));
      }
      return user;
    } catch {
      client.data.user = undefined;
      client.data.authToken = undefined;
      return null;
    }
  }

  async requireUser(client: Socket): Promise<UserEntity> {
    const user = await this.getUser(client);
    if (!user) throw new UnauthorizedException('Autenticação obrigatória');
    return user;
  }

  async requireTenant(client: Socket): Promise<UserEntity> {
    const user = await this.requireUser(client);
    if (
      !user.tenantId ||
      !user.membershipId ||
      !['tenant', 'support'].includes(user.sessionScope)
    ) {
      throw new ForbiddenException('Selecione uma família para continuar.');
    }
    return user;
  }

  async requirePlatform(client: Socket): Promise<UserEntity> {
    const user = await this.requireUser(client);
    if (user.sessionScope !== 'platform' || user.platformRole !== 'admin') {
      throw new ForbiddenException(
        'Acesso restrito ao administrador da plataforma.',
      );
    }
    return user;
  }

  async requireRole(client: Socket, roles: UserRole[]): Promise<UserEntity> {
    const user = await this.requireTenant(client);
    if (!roles.includes(user.role)) {
      throw new ForbiddenException('Acesso não autorizado para sua role.');
    }
    return user;
  }

  async requireAdmin(client: Socket): Promise<UserEntity> {
    const user = await this.requireTenant(client);
    if (!isAdminRole(user.role)) {
      throw new ForbiddenException('Acesso administrativo obrigatório.');
    }
    await this.tenants.assertEntitled(user.tenantId!);
    return user;
  }

  async requireAccess(client: Socket, accessKey: UserAccessKey) {
    const user = await this.requireTenant(client);
    if (isAdminRole(user.role) || user.access.includes(accessKey)) {
      await this.tenants.assertEntitled(user.tenantId!);
      return user;
    }
    throw new ForbiddenException('Acesso não liberado para este recurso.');
  }

  private tokenFromClient(client: Socket): string | null {
    const authToken = client.handshake.auth?.token;
    const bearer = client.handshake.headers.authorization;
    if (typeof authToken === 'string' && authToken) return authToken;
    if (typeof bearer === 'string' && bearer.startsWith('Bearer ')) {
      return bearer.slice(7);
    }
    return null;
  }
}
