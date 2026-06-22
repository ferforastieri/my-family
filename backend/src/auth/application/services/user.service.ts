import { BadRequestException, Injectable } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { UserRepository } from '../../infrastructure/repositories/user.repository';
import type {
  PaginatedResult,
  PaginationQuery,
} from '@shared/infrastructure/database/mongo.utils';
import { normalizePagination } from '@shared/infrastructure/database/mongo.utils';
import { TenantContext } from '@tenancy/application/tenant-context';
import { TenantRepository } from '@tenancy/infrastructure/tenant.repository';
import type { MembershipEntity, TenantEntity } from '@tenancy/domain/tenant.entity';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { userMapper } from '../mappers/user.mapper';
import { UpdateUserDto, UserResponseDto } from '../../interfaces/dto/user.dto';

@Injectable()
export class UserService {
  constructor(
    private users: UserRepository,
    private tenants: TenantRepository,
    private context: TenantContext,
  ) {}

  async list(
    query?: PaginationQuery,
  ): Promise<PaginatedResult<UserResponseDto>> {
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 20,
      maxLimit: 100,
    });
    const [tenant, memberships] = await Promise.all([
      this.tenants.findTenantById(this.context.tenantId),
      this.tenants.listMembershipsForTenant(this.context.tenantId),
    ]);
    if (!tenant) return { items: [], total: 0, page, limit, pages: 0 };
    const selected = memberships.slice(skip, skip + limit);
    const accounts = await this.users.findManyByIds(
      selected.map((membership) => membership.userId),
    );
    const accountById = new Map(accounts.map((account) => [account.id, account]));
    const items = selected
      .map((membership) => {
        const account = accountById.get(membership.userId);
        return account
          ? userMapper.toDto(this.withMembership(account, membership, tenant))
          : null;
      })
      .filter((item): item is UserResponseDto => item !== null);
    return {
      items,
      total: memberships.length,
      page,
      limit,
      pages: Math.ceil(memberships.length / limit),
    };
  }

  async findOne(id: string): Promise<UserResponseDto | null> {
    const [account, membership, tenant] = await Promise.all([
      this.users.findById(id),
      this.tenants.findMembership(this.context.tenantId, id),
      this.tenants.findTenantById(this.context.tenantId),
    ]);
    if (!account || !membership || !tenant) return null;
    return userMapper.toDto(this.withMembership(account, membership, tenant));
  }

  async update(
    id: string,
    data: UpdateUserDto,
  ): Promise<UserResponseDto | null> {
    const membership = await this.tenants.findMembership(this.context.tenantId, id);
    if (!membership) return null;
    if (membership.role === 'owner' && data.role && data.role !== 'owner') {
      throw new BadRequestException('O proprietário não pode perder a propriedade.');
    }
    if (membership.role !== 'owner' && data.role === 'owner') {
      throw new BadRequestException('A transferência de propriedade usa um fluxo próprio.');
    }
    const accountUpdate: { name?: string; avatarPath?: string; passwordHash?: string } = {
      name: data.name?.trim(),
      avatarPath: data.avatarPath,
    };
    if (data.password?.trim()) {
      accountUpdate.passwordHash = await bcrypt.hash(data.password.trim(), 12);
    }
    await Promise.all([
      this.users.update(id, accountUpdate),
      this.tenants.updateMembership(this.context.tenantId, id, {
        role: data.role,
        access: data.access,
      }),
    ]);
    return this.findOne(id);
  }

  async delete(id: string): Promise<boolean> {
    const membership = await this.tenants.findMembership(this.context.tenantId, id);
    if (!membership) return false;
    if (membership.role === 'owner') {
      throw new BadRequestException('O proprietário não pode ser removido.');
    }
    return this.tenants.deleteMembership(this.context.tenantId, id);
  }

  private withMembership(
    account: UserEntity,
    membership: MembershipEntity,
    tenant: TenantEntity,
  ): UserEntity {
    return {
      ...account,
      tenantId: tenant.id,
      tenantSlug: tenant.slug,
      membershipId: membership.id,
      role: membership.role,
      access: membership.access,
    };
  }
}

