import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  FotoDocument,
  FotoMongoDocument,
  MembershipDocument,
  MembershipMongoDocument,
  MusicaDocument,
  MusicaMongoDocument,
  NotificationDocument,
  NotificationMongoDocument,
} from '@shared/infrastructure/database/schemas';
import { TenantService } from '@tenancy/application/tenant.service';
import { TenantContext } from '@tenancy/application/tenant-context';

@Injectable()
export class ClientPanelService {
  constructor(
    private readonly tenants: TenantService,
    private readonly context: TenantContext,
    @InjectModel(MembershipDocument.name)
    private readonly memberships: Model<MembershipMongoDocument>,
    @InjectModel(FotoDocument.name)
    private readonly photos: Model<FotoMongoDocument>,
    @InjectModel(MusicaDocument.name)
    private readonly songs: Model<MusicaMongoDocument>,
    @InjectModel(NotificationDocument.name)
    private readonly notifications: Model<NotificationMongoDocument>,
  ) {}

  async dashboard() {
    const tenant = await this.tenants.current();
    const [members, photos, songs, unreadNotifications] = await Promise.all([
      this.memberships.countDocuments({ tenantId: tenant.id }).exec(),
      this.photos.countDocuments().exec(),
      this.songs.countDocuments().exec(),
      this.notifications
        .countDocuments({
          readBy: { $ne: this.context.current.userId ?? '' },
        })
        .exec(),
    ]);
    return {
      tenant,
      metrics: {
        members,
        photos,
        songs,
        unreadNotifications,
      },
    };
  }
}
