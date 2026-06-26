import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  SubscriptionDocument,
  SubscriptionMongoDocument,
} from '../billing/infrastructure/persistence/subscription.schema';
import type { SubscriptionPlanInterval } from '../billing/infrastructure/persistence/subscription-plan.schema';
import {
  TenantDocument,
  TenantMongoDocument,
} from '../tenancy/infrastructure/persistence/tenant.schema';
import {
  UserDocument,
  UserMongoDocument,
} from '../auth/infrastructure/persistence/user.schema';
import { AuditService } from '../audit/application/audit.service';
import {
  normalizePagination,
  paginated,
  type PaginationQuery,
} from '@shared/infrastructure/database/mongo.utils';
import { BillingRepository } from '../billing/infrastructure/billing.repository';

@Injectable()
export class PlatformAdminService {
  constructor(
    @InjectModel(UserDocument.name)
    private readonly users: Model<UserMongoDocument>,
    @InjectModel(TenantDocument.name)
    private readonly tenants: Model<TenantMongoDocument>,
    @InjectModel(SubscriptionDocument.name)
    private readonly subscriptions: Model<SubscriptionMongoDocument>,
    private readonly billing: BillingRepository,
    private readonly audit: AuditService,
  ) {}

  async overview() {
    const now = new Date();
    const last24Hours = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const last30Days = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const [
      totalUsers,
      totalTenants,
      activeTenants,
      pendingTenants,
      activeSubscriptions,
      newUsers30d,
      newTenants30d,
      tenantStatuses,
      recentTenants,
      recentAudit,
      auditEvents24h,
      plans,
    ] = await Promise.all([
      this.users.countDocuments().exec(),
      this.tenants.countDocuments().exec(),
      this.tenants.countDocuments({ status: 'active' }).exec(),
      this.tenants.countDocuments({ status: 'pending_payment' }).exec(),
      this.subscriptions
        .countDocuments({ status: { $in: ['active', 'trialing'] } })
        .exec(),
      this.users.countDocuments({ createdAt: { $gte: last30Days } }).exec(),
      this.tenants.countDocuments({ createdAt: { $gte: last30Days } }).exec(),
      this.tenants
        .aggregate<{
          _id: string;
          count: number;
        }>([
          { $group: { _id: '$status', count: { $sum: 1 } } },
          { $sort: { count: -1 } },
        ])
        .exec(),
      this.tenants
        .find()
        .sort({ createdAt: -1 })
        .limit(8)
        .select('name slug status isPublished createdAt')
        .lean()
        .exec(),
      this.audit.list(1, 10),
      this.audit.countSince(last24Hours),
      this.listPlans(),
    ]);

    return {
      metrics: {
        totalUsers,
        totalTenants,
        activeTenants,
        pendingTenants,
        activeSubscriptions,
        newUsers30d,
        newTenants30d,
        auditEvents24h,
      },
      plans,
      tenantStatuses: Object.fromEntries(
        tenantStatuses.map((item) => [item._id, item.count]),
      ),
      recentTenants: recentTenants.map((tenant) => ({
        id: String(tenant._id),
        name: tenant.name,
        slug: tenant.slug,
        status: tenant.status,
        isPublished: tenant.isPublished,
        createdAt: tenant.createdAt,
      })),
      recentAudit: recentAudit.items,
    };
  }

  auditLogs(page: number, limit: number) {
    return this.audit.list(page, limit);
  }

  async listPlans() {
    return this.billing.listPlans({ activeOnly: false });
  }

  async updatePlan(
    interval: SubscriptionPlanInterval,
    data: Partial<{
      name: string;
      description: string;
      priceCents: number;
      currency: string;
      stripePriceId: string | null;
      active: boolean;
      highlighted: boolean;
      sortOrder: number;
    }>,
  ) {
    return this.billing.updatePlan(interval, {
      ...data,
      currency: data.currency?.toUpperCase(),
      stripePriceId: data.stripePriceId === '' ? null : data.stripePriceId,
    });
  }

  async listTenants(query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query);
    const [items, total] = await Promise.all([
      this.tenants
        .find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean()
        .exec(),
      this.tenants.countDocuments().exec(),
    ]);
    return paginated(
      items.map((tenant) => ({
        id: String(tenant._id),
        name: tenant.name,
        slug: tenant.slug,
        status: tenant.status,
        ownerUserId: tenant.ownerUserId,
        isPublished: tenant.isPublished,
        createdAt: tenant.createdAt,
      })),
      total,
      page,
      limit,
    );
  }

  async listUsers(query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query);
    const [items, total] = await Promise.all([
      this.users
        .find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .select('email name platformRole createdAt')
        .lean()
        .exec(),
      this.users.countDocuments().exec(),
    ]);
    return paginated(
      items.map((user) => ({
        id: String(user._id),
        email: user.email,
        name: user.name ?? null,
        platformRole: user.platformRole ?? null,
        createdAt: user.createdAt,
      })),
      total,
      page,
      limit,
    );
  }

  async listSubscriptions(query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query);
    const [items, total] = await Promise.all([
      this.subscriptions
        .find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean()
        .exec(),
      this.subscriptions.countDocuments().exec(),
    ]);
    return paginated(
      items.map((subscription) => ({
        id: String(subscription._id),
        tenantId: subscription.tenantId,
        provider: subscription.provider,
        status: subscription.status,
        priceId: subscription.priceId ?? null,
        currentPeriodEnd: subscription.currentPeriodEnd ?? null,
        cancelAtPeriodEnd: subscription.cancelAtPeriodEnd ?? false,
        createdAt: subscription.createdAt,
      })),
      total,
      page,
      limit,
    );
  }
}
