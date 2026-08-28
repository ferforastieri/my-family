import { Observable, firstValueFrom } from 'rxjs';
import { TenantContextInterceptor } from './tenant-context.interceptor';
import { TenantContextService } from '@shared/infrastructure/database/tenant-context';

describe('TenantContextInterceptor', () => {
  it('keeps the authenticated tenant through async observable work', async () => {
    const context = new TenantContextService();
    const interceptor = new TenantContextInterceptor(context);
    const host = {
      switchToHttp: () => ({
        getRequest: () => ({ user: { tenantId: 'tenant-a' } }),
      }),
    } as never;
    let observedTenant: string | undefined;
    const result = await firstValueFrom(
      interceptor.intercept(host, {
        handle: () =>
          new Observable((subscriber) => {
            observedTenant = context.tenantId;
            subscriber.next(null);
            subscriber.complete();
          }),
      } as never),
    );
    expect(result).toBeNull();
    expect(observedTenant).toBe('tenant-a');
    expect(context.tenantId).toBeUndefined();
  });
});
