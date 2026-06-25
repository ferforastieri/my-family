import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import type {
  AuthJwtPayload,
  UserEntity,
} from '@auth/domain/entities/user.entity';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { AuthService } from '../application/services/auth.service';

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
      const payload = await this.jwt.verifyAsync<AuthJwtPayload>(token);
      const user = await this.auth.resolvePayload(payload);
      if (!user) throw new UnauthorizedException('Sessão inválida.');
      (request as Request & { user: UserEntity }).user = user;
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
