import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  AuthSessionDocument,
  AuthSessionMongoDocument,
  InvitationDocument,
  InvitationMongoDocument,
  MembershipDocument,
  MembershipMongoDocument,
  TenantDocument,
  TenantMongoDocument,
} from '@shared/infrastructure/database/schemas';
import { toId } from '@shared/infrastructure/database/mongo.utils';
import type {
  MembershipRole,
  TenantEntity,
  TenantFont,
} from '../domain/tenant.entity';
import type {
  UserAccessKey,
  UserRole,
} from '@auth/domain/entities/user.entity';

@Injectable()
export class TenancyRepository {
  constructor(
    @InjectModel(TenantDocument.name)
    private tenants: Model<TenantMongoDocument>,
    @InjectModel(MembershipDocument.name)
    private memberships: Model<MembershipMongoDocument>,
    @InjectModel(InvitationDocument.name)
    private invitations: Model<InvitationMongoDocument>,
    @InjectModel(AuthSessionDocument.name)
    private sessions: Model<AuthSessionMongoDocument>,
  ) {}

  toTenant(doc: TenantMongoDocument | null): TenantEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      name: doc.name,
      slug: doc.slug,
      status: doc.status as TenantEntity['status'],
      planCode: doc.planCode,
      subscriptionStatus:
        doc.subscriptionStatus as TenantEntity['subscriptionStatus'],
      theme: {
        primaryColor: doc.theme?.primaryColor ?? '#9F4D4D',
        fontFamily: (doc.theme?.fontFamily ?? 'nunitoSans') as TenantFont,
      },
      isDemo: doc.isDemo === true,
      expiresAt: doc.expiresAt ?? null,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  findTenantById(id: string) {
    return this.tenants
      .findById(id)
      .exec()
      .then((doc) => this.toTenant(doc));
  }
  findTenantBySlug(slug: string) {
    return this.tenants
      .findOne({ slug: slug.toLowerCase() })
      .exec()
      .then((doc) => this.toTenant(doc));
  }
  async createTenant(data: {
    name: string;
    slug: string;
    isDemo?: boolean;
    expiresAt?: Date;
  }) {
    return this.toTenant(
      await this.tenants.create({
        ...data,
        planCode: data.isDemo ? 'demo' : 'early_access',
      }),
    );
  }
  async updateTenant(id: string, data: Record<string, unknown>) {
    return this.toTenant(
      await this.tenants
        .findByIdAndUpdate(id, { $set: data }, { new: true })
        .exec(),
    );
  }
  async deleteTenant(id: string) {
    await Promise.all([
      this.memberships.deleteMany({ tenantId: id }),
      this.invitations.deleteMany({ tenantId: id }),
      this.sessions.deleteMany({ tenantId: id }),
    ]);
    return this.tenants.findByIdAndDelete(id).exec();
  }

  createMembership(data: {
    tenantId: string;
    userId: string;
    role: MembershipRole;
    relationship?: UserRole;
    access?: UserAccessKey[];
  }) {
    return this.memberships.create({
      ...data,
      relationship: data.relationship ?? 'friends',
      access: data.access ?? [],
    });
  }
  findMembership(tenantId: string, userId: string) {
    return this.memberships.findOne({ tenantId, userId }).exec();
  }
  listMembershipsForUser(userId: string) {
    return this.memberships
      .find({ userId })
      .sort({ createdAt: 1 })
      .lean()
      .exec();
  }
  listMembershipsForTenant(tenantId: string) {
    return this.memberships
      .find({ tenantId })
      .sort({ createdAt: 1 })
      .lean()
      .exec();
  }
  updateMembership(
    tenantId: string,
    userId: string,
    data: Record<string, unknown>,
  ) {
    return this.memberships
      .findOneAndUpdate({ tenantId, userId }, { $set: data }, { new: true })
      .lean()
      .exec();
  }
  deleteMembership(tenantId: string, userId: string) {
    return this.memberships.deleteOne({ tenantId, userId }).exec();
  }

  createInvitation(data: Record<string, unknown>) {
    return this.invitations.create(data);
  }
  listInvitations(tenantId: string) {
    return this.invitations
      .find(
        { tenantId, status: 'pending', expiresAt: { $gt: new Date() } },
        { tokenHash: 0 },
      )
      .sort({ createdAt: -1 })
      .lean()
      .exec();
  }
  findInvitationByHash(tokenHash: string) {
    return this.invitations
      .findOne({ tokenHash, status: 'pending', expiresAt: { $gt: new Date() } })
      .exec();
  }
  revokeInvitation(id: string, tenantId: string) {
    return this.invitations
      .findOneAndUpdate(
        { _id: id, tenantId },
        { $set: { status: 'revoked' } },
        { new: true },
      )
      .exec();
  }
  acceptInvitation(id: string) {
    return this.invitations
      .findByIdAndUpdate(
        id,
        { $set: { status: 'accepted', acceptedAt: new Date() } },
        { new: true },
      )
      .exec();
  }

  createSession(data: {
    userId: string;
    tokenHash: string;
    tenantId?: string;
    userAgent?: string;
    expiresAt: Date;
  }) {
    return this.sessions.create(data);
  }
  consumeSession(tokenHash: string) {
    return this.sessions
      .findOneAndUpdate(
        {
          tokenHash,
          revokedAt: { $exists: false },
          expiresAt: { $gt: new Date() },
        },
        { $set: { revokedAt: new Date() } },
        { new: false },
      )
      .exec();
  }
  revokeSession(tokenHash: string) {
    return this.sessions
      .updateOne({ tokenHash }, { $set: { revokedAt: new Date() } })
      .exec();
  }

  async listTenants(page: number, limit: number) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.tenants
        .find({ status: { $ne: 'deleted' } })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean()
        .exec(),
      this.tenants.countDocuments({ status: { $ne: 'deleted' } }).exec(),
    ]);
    return {
      items: items.map((item) => ({
        id: toId(item),
        name: item.name,
        slug: item.slug,
        status: item.status,
        planCode: item.planCode,
        subscriptionStatus: item.subscriptionStatus,
        isDemo: item.isDemo,
        expiresAt: item.expiresAt,
        createdAt: item.createdAt,
      })),
      page,
      limit,
      total,
      pages: Math.max(1, Math.ceil(total / limit)),
    };
  }
  expiredDemos() {
    return this.tenants
      .find({ isDemo: true, expiresAt: { $lte: new Date() } })
      .lean()
      .exec();
  }
}
