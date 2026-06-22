import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { AuthService } from '../application/services/auth.service';

type AccessTokenPayload = {
  sub: string;
  tenantId: string;
  membershipId: string;
  type?: 'refresh';
};

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly auth: AuthService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (context.getType() !== 'http') return true;
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractToken(request);
    if (!token) throw new UnauthorizedException('Token de acesso ausente.');

    try {
      const payload = await this.jwt.verifyAsync<AccessTokenPayload>(token);
      if (payload.type === 'refresh' || !payload.sub || !payload.tenantId) {
        throw new UnauthorizedException('Token de acesso inválido.');
      }
      const user = await this.auth.findAuthenticatedUser(
        payload.sub,
        payload.tenantId,
      );
      if (!user) throw new UnauthorizedException('Sessão inválida.');
      (request as Request & { user: typeof user }).user = user;
      return true;
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      throw new UnauthorizedException('Token inválido ou expirado.');
    }
  }

  private extractToken(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type?.toLowerCase() === 'bearer' ? token : undefined;
  }
}
