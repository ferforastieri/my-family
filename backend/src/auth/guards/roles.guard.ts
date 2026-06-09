import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { isAdminRole, type UserRole } from '@auth/domain/entities/user.entity';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!requiredRoles?.length) return true;

    const req =
      context.getType<'http' | 'ws'>() === 'ws'
        ? { user: context.switchToWs().getClient()?.data?.user }
        : context.switchToHttp().getRequest();
    const user = req.user as { role?: string } | undefined;
    const role = user?.role as UserRole | undefined;

    const adminAllowed = requiredRoles.some((role) => isAdminRole(role));
    if (
      !role ||
      (!requiredRoles.includes(role) && !(adminAllowed && isAdminRole(role)))
    ) {
      throw new ForbiddenException('Acesso não autorizado para sua role.');
    }
    return true;
  }
}
