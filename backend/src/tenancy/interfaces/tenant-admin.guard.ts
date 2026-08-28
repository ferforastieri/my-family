import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { isTenantAdmin, type TenantPrincipal } from '../domain/tenant.entity';
@Injectable()
export class TenantAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext) {
    const user = context
      .switchToHttp()
      .getRequest<{ user?: TenantPrincipal }>().user;
    if (!isTenantAdmin(user))
      throw new ForbiddenException('Administração da família obrigatória.');
    return true;
  }
}
