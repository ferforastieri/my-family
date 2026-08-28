import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Socket } from 'socket.io';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { AuthService } from './auth.service';
import { type UserAccessKey } from '@auth/domain/entities/user.entity';
import {
  isTenantAdmin,
  type TenantPrincipal,
} from '@tenancy/domain/tenant.entity';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';
import {
  ACCESS_COOKIE,
  cookieValue,
} from '@shared/infrastructure/security/auth-cookies';

@Injectable()
export class WsSessionService {
  constructor(
    private jwt: JwtService,
    private env: Environment,
    private auth: AuthService,
    private context: TenantContextService,
  ) {}

  private tokenFromClient(client: Socket): string | null {
    return cookieValue(client.handshake, ACCESS_COOKIE);
  }

  async getUser(client: Socket): Promise<TenantPrincipal | null> {
    const token = this.tokenFromClient(client);
    if (!token) return null;
    try {
      const payload = this.jwt.verify<{ sub: string; tenantId?: string }>(
        token,
        {
          secret: this.env.jwt.secret,
          algorithms: ['HS256'],
          issuer: 'nossa-familia-api',
          audience: 'nossa-familia-app',
        },
      );
      if (!payload.tenantId) return null;
      const user = await this.auth.tenantPrincipal(
        payload.sub,
        payload.tenantId,
      );
      if (user) {
        client.data.user = user;
        await client.join(`tenant:${user.tenantId}`);
        this.context.enter(user.tenantId);
      }
      return user;
    } catch {
      return null;
    }
  }

  async requireUser(client: Socket): Promise<TenantPrincipal> {
    const user = await this.getUser(client);
    if (!user) throw new UnauthorizedException('Autenticação obrigatória');
    return user;
  }

  async requireAccess(
    client: Socket,
    accessKey: UserAccessKey,
  ): Promise<TenantPrincipal> {
    const user = await this.requireUser(client);
    if (isTenantAdmin(user) || user.access.includes(accessKey)) return user;
    throw new ForbiddenException('Acesso não liberado para este recurso.');
  }
}
