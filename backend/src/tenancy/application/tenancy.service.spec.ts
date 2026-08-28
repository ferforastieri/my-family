import { ForbiddenException } from '@nestjs/common';
import { TenancyService } from './tenancy.service';

describe('TenancyService membership administration', () => {
  it('prevents an admin from changing membership administration roles', async () => {
    const repo = {
      findMembership: jest.fn((_: string, userId: string) =>
        Promise.resolve({
          role: userId === 'actor-admin' ? 'admin' : 'member',
        }),
      ),
      updateMembership: jest.fn(),
    };
    const service = new TenancyService(repo as never, {} as never, {} as never);

    await expect(
      service.updateMember('tenant-1', 'actor-admin', 'member-1', {
        membershipRole: 'admin',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(repo.updateMembership).not.toHaveBeenCalled();
  });

  it('allows the owner to promote a member to admin', async () => {
    const repo = {
      findMembership: jest.fn((_: string, userId: string) =>
        Promise.resolve({ role: userId === 'owner-1' ? 'owner' : 'member' }),
      ),
      updateMembership: jest.fn().mockResolvedValue(null),
    };
    const service = new TenancyService(repo as never, {} as never, {} as never);
    jest
      .spyOn(service, 'member')
      .mockResolvedValue({ id: 'member-1' } as never);

    await service.updateMember('tenant-1', 'owner-1', 'member-1', {
      membershipRole: 'admin',
    });

    expect(repo.updateMembership).toHaveBeenCalledWith('tenant-1', 'member-1', {
      role: 'admin',
    });
  });
});
