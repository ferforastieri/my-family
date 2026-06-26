import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  MembershipDocument,
  MembershipMongoDocument,
} from './persistence/membership.schema';
import {
  TenantDocument,
  TenantMongoDocument,
} from './persistence/tenant.schema';
import {
  cleanUndefined,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import { normalizeAccessKeys } from '@auth/domain/entities/user.entity';
import type {
  MembershipEntity,
  MembershipRole,
  TenantEntity,
  TenantLocale,
  TenantStatus,
} from '../domain/tenant.entity';
import type { UserAccessKey } from '@shared/domain/access';

@Injectable()
export class TenantRepository {
  constructor(
    @InjectModel(TenantDocument.name)
    private tenants: Model<TenantMongoDocument>,
    @InjectModel(MembershipDocument.name)
    private memberships: Model<MembershipMongoDocument>,
  ) {}

  toTenant(document: TenantMongoDocument | null): TenantEntity | null {
    if (!document) return null;
    return {
      id: toId(document),
      name: document.name,
      slug: document.slug,
      ownerUserId: document.ownerUserId,
      defaultLocale: document.defaultLocale,
      status: document.status,
      isDemo: document.isDemo,
      isPublished: document.isPublished,
      theme: document.theme ?? {},
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
    };
  }

  toMembership(
    document: MembershipMongoDocument | null,
  ): MembershipEntity | null {
    if (!document) return null;
    return {
      id: toId(document),
      tenantId: document.tenantId,
      userId: document.userId,
      role: document.role,
      access: normalizeAccessKeys(document.access),
      relationLabel: document.relationLabel ?? null,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
    };
  }

  async createTenant(data: {
    name: string;
    slug: string;
    ownerUserId: string;
    defaultLocale: TenantLocale;
    status?: TenantStatus;
    isDemo?: boolean;
    isPublished?: boolean;
    theme?: Record<string, unknown>;
  }): Promise<TenantEntity> {
    return this.toTenant(await this.tenants.create(data))!;
  }

  async findTenantById(id: string): Promise<TenantEntity | null> {
    return this.toTenant(await this.tenants.findById(id).exec());
  }

  async findTenantBySlug(slug: string): Promise<TenantEntity | null> {
    return this.toTenant(
      await this.tenants.findOne({ slug: slug.toLowerCase() }).exec(),
    );
  }

  async listAllTenants(): Promise<TenantEntity[]> {
    const documents = await this.tenants.find().sort({ createdAt: 1 }).exec();
    return documents.map((document) => this.toTenant(document)!);
  }

  async findDemoTenant(): Promise<TenantEntity | null> {
    return this.toTenant(
      await this.tenants
        .findOne({ isDemo: true, isPublished: true })
        .sort({ createdAt: 1 })
        .exec(),
    );
  }

  async updateTenant(
    id: string,
    data: Partial<{
      name: string;
      slug: string;
      defaultLocale: TenantLocale;
      status: TenantStatus;
      isDemo: boolean;
      isPublished: boolean;
      theme: Record<string, unknown>;
    }>,
  ): Promise<TenantEntity | null> {
    return this.toTenant(
      await this.tenants
        .findByIdAndUpdate(id, { $set: cleanUndefined(data) }, { new: true })
        .exec(),
    );
  }

  async deleteTenant(id: string): Promise<void> {
    await Promise.all([
      this.tenants.findByIdAndDelete(id).exec(),
      this.memberships.deleteMany({ tenantId: id }).exec(),
    ]);
  }

  async createMembership(data: {
    tenantId: string;
    userId: string;
    role: MembershipRole;
    access?: UserAccessKey[];
    relationLabel?: string;
  }): Promise<MembershipEntity> {
    return this.toMembership(await this.memberships.create(data))!;
  }

  async findMembership(
    tenantId: string,
    userId: string,
  ): Promise<MembershipEntity | null> {
    return this.toMembership(
      await this.memberships.findOne({ tenantId, userId }).exec(),
    );
  }

  async findMembershipById(id: string): Promise<MembershipEntity | null> {
    return this.toMembership(await this.memberships.findById(id).exec());
  }

  async listMembershipsForUser(userId: string): Promise<MembershipEntity[]> {
    const rows = await this.memberships
      .find({ userId })
      .sort({ createdAt: 1 })
      .exec();
    return rows.map((row) => this.toMembership(row)!);
  }

  async listMembershipsForTenant(
    tenantId: string,
  ): Promise<MembershipEntity[]> {
    const rows = await this.memberships
      .find({ tenantId })
      .sort({ createdAt: 1 })
      .exec();
    return rows.map((row) => this.toMembership(row)!);
  }

  async updateMembership(
    tenantId: string,
    userId: string,
    data: Partial<{
      role: MembershipRole;
      access: UserAccessKey[];
      relationLabel: string;
    }>,
  ): Promise<MembershipEntity | null> {
    return this.toMembership(
      await this.memberships
        .findOneAndUpdate(
          { tenantId, userId },
          { $set: cleanUndefined(data) },
          { new: true },
        )
        .exec(),
    );
  }

  async deleteMembership(tenantId: string, userId: string): Promise<boolean> {
    return !!(await this.memberships
      .findOneAndDelete({ tenantId, userId })
      .exec());
  }
}
