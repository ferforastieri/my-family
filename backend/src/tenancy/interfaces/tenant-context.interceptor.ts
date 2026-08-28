import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';
import type { TenantPrincipal } from '../domain/tenant.entity';

@Injectable()
export class TenantContextInterceptor implements NestInterceptor {
  constructor(private context: TenantContextService) {}
  intercept(host: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = host.switchToHttp().getRequest<{
      user?: TenantPrincipal;
    }>();
    const tenantId = request?.user?.tenantId;
    if (!tenantId) return next.handle();
    return new Observable((subscriber) =>
      this.context.run(tenantId, () => next.handle().subscribe(subscriber)),
    );
  }
}
