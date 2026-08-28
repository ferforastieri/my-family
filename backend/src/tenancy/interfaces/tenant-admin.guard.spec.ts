import type { ExecutionContext } from '@nestjs/common';
import { ForbiddenException } from '@nestjs/common';
import { TenantAdminGuard } from './tenant-admin.guard';

describe('TenantAdminGuard', () => {
  const contextFor = (user: Record<string, unknown>) =>
    ({
      switchToHttp: () => ({ getRequest: () => ({ user }) }),
    }) as ExecutionContext;

  it('does not grant administration from family relationship', () => {
    expect(() =>
      new TenantAdminGuard().canActivate(
        contextFor({ role: 'husband', membershipRole: 'member' }),
      ),
    ).toThrow(ForbiddenException);
  });

  it('grants administration only from membership role', () => {
    expect(
      new TenantAdminGuard().canActivate(
        contextFor({ role: 'friends', membershipRole: 'admin' }),
      ),
    ).toBe(true);
  });
});
