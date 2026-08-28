import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'memberships' })
export class MembershipDocument {
  @Prop({ required: true, index: true }) tenantId: string;
  @Prop({ required: true, index: true }) userId: string;
  @Prop({
    required: true,
    enum: ['owner', 'admin', 'member'],
    default: 'member',
  })
  role: string;
  @Prop({
    required: true,
    enum: ['husband', 'wife', 'children', 'friends'],
    default: 'friends',
  })
  relationship: string;
  @Prop({ type: [String], default: [] }) access: string[];
  createdAt: Date;
  updatedAt: Date;
}
export type MembershipMongoDocument = HydratedDocument<MembershipDocument>;
export const MembershipSchema =
  SchemaFactory.createForClass(MembershipDocument);
MembershipSchema.index({ tenantId: 1, userId: 1 }, { unique: true });
