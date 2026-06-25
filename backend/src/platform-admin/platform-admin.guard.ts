import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import type { Request } from 'express';
import type { UserEntity } from '@auth/domain/entities/user.entity';

@Injectable()
export class PlatformAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context
      .switchToHttp()
      .getRequest<Request & { user?: UserEntity }>();
    if (request.user?.platformRole !== 'admin') {
      throw new ForbiddenException(
        'Acesso restrito ao administrador da plataforma.',
      );
    }
    return true;
  }
}
