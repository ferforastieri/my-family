import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import type { TenantPrincipal } from '../domain/tenant.entity';
@Injectable()
export class DemoRestrictedGuard implements CanActivate {
  canActivate(context: ExecutionContext) {
    const user = context
      .switchToHttp()
      .getRequest<{ user?: TenantPrincipal }>().user;
    if (user?.isDemo)
      throw new ForbiddenException(
        'Este recurso não está disponível na demonstração.',
      );
    return true;
  }
}
