import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { from, mergeMap, Observable } from 'rxjs';
import type { Socket } from 'socket.io';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { TenantContext } from '@tenancy/application/tenant-context';
import type { TenantContextValue } from '@tenancy/domain/tenant.entity';
import { WsSessionService } from './ws-session.service';

@Injectable()
export class TenantContextInterceptor implements NestInterceptor {
  constructor(
    private tenantContext: TenantContext,
    private wsSession: WsSessionService,
  ) {}

  intercept(
    executionContext: ExecutionContext,
    next: CallHandler,
  ): Observable<unknown> {
    return from(this.resolve(executionContext)).pipe(
      mergeMap((context) => {
        if (!context) return next.handle();
        return new Observable((subscriber) =>
          this.tenantContext.run(context, () =>
            next.handle().subscribe(subscriber),
          ),
        );
      }),
    );
  }

  private async resolve(
    executionContext: ExecutionContext,
  ): Promise<TenantContextValue | null> {
    if (executionContext.getType() === 'http') {
      const request = executionContext.switchToHttp().getRequest<{
        user?: UserEntity;
      }>();
      return request.user?.tenantId ? this.fromUser(request.user) : null;
    }

    if (executionContext.getType() === 'ws') {
      const client = executionContext.switchToWs().getClient<Socket>();
      const user = await this.wsSession.getUser(client);
      return user?.tenantId ? this.fromUser(user) : null;
    }

    return null;
  }

  private fromUser(user: UserEntity): TenantContextValue {
    return {
      tenantId: user.tenantId,
      tenantSlug: user.tenantSlug ?? undefined,
      userId: user.id,
      membershipId: user.membershipId,
      role: user.role,
      access: user.access,
    };
  }
}
