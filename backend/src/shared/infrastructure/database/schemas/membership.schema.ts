import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import type { UserAccessKey } from '@shared/domain/access';
import type { MembershipRole } from '@tenancy/domain/tenant.entity';

@Schema({ timestamps: true, collection: 'memberships' })
export class MembershipDocument {
  @Prop({ required: true, index: true })
  tenantId: string;

  @Prop({ required: true, index: true })
  userId: string;

  @Prop({ type: String, required: true, enum: ['owner', 'admin', 'member'] })
  role: MembershipRole;

  @Prop({ type: [String], required: true, default: [] })
  access: UserAccessKey[];

  @Prop({ trim: true })
  relationLabel?: string;

  createdAt: Date;
  updatedAt: Date;
}

export type MembershipMongoDocument = HydratedDocument<MembershipDocument>;
export const MembershipSchema =
  SchemaFactory.createForClass(MembershipDocument);
MembershipSchema.index({ tenantId: 1, userId: 1 }, { unique: true });
