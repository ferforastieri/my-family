import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import type { TenantPrincipal } from '../domain/tenant.entity';
@Injectable()
export class PlatformAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext) {
    const user = context
      .switchToHttp()
      .getRequest<{ user?: TenantPrincipal }>().user;
    if (user?.platformRole !== 'super_admin')
      throw new ForbiddenException('Administração da plataforma obrigatória.');
    return true;
  }
}
