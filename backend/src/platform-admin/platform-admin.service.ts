import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  SubscriptionDocument,
  SubscriptionMongoDocument,
  TenantDocument,
  TenantMongoDocument,
  UserDocument,
  UserMongoDocument,
} from '@shared/infrastructure/database/schemas';
import { AuditService } from '../audit/application/audit.service';

@Injectable()
export class PlatformAdminService {
  constructor(
    @InjectModel(UserDocument.name)
    private readonly users: Model<UserMongoDocument>,
    @InjectModel(TenantDocument.name)
    private readonly tenants: Model<TenantMongoDocument>,
    @InjectModel(SubscriptionDocument.name)
    private readonly subscriptions: Model<SubscriptionMongoDocument>,
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
        }>([{ $group: { _id: '$status', count: { $sum: 1 } } }, { $sort: { count: -1 } }])
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
}
