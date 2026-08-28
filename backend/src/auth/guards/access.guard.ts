import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ACCESS_KEY } from '@auth/decorators/access.decorator';
import { type UserAccessKey } from '@auth/domain/entities/user.entity';
import {
  isTenantAdmin,
  type TenantPrincipal,
} from '@tenancy/domain/tenant.entity';

@Injectable()
export class AccessGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const accessKey = this.reflector.getAllAndOverride<UserAccessKey>(
      ACCESS_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!accessKey) return true;

    const req = context.switchToHttp().getRequest<{ user?: TenantPrincipal }>();
    const user = req.user;
    if (user && (isTenantAdmin(user) || user.access.includes(accessKey))) {
      return true;
    }
    throw new ForbiddenException('Acesso não liberado para este recurso.');
  }
}
