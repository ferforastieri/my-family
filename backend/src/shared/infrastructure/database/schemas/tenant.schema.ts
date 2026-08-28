import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'tenants' })
export class TenantDocument {
  @Prop({ required: true, trim: true }) name: string;
  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  slug: string;
  @Prop({
    required: true,
    enum: ['active', 'suspended', 'deleted'],
    default: 'active',
    index: true,
  })
  status: string;
  @Prop({ required: true, default: 'early_access' }) planCode: string;
  @Prop({
    required: true,
    enum: ['active', 'past_due', 'cancelled'],
    default: 'active',
  })
  subscriptionStatus: string;
  @Prop({
    type: Object,
    default: { primaryColor: '#9F4D4D', fontFamily: 'nunitoSans' },
  })
  theme: { primaryColor: string; fontFamily: string };
  @Prop({ default: false, index: true }) isDemo: boolean;
  @Prop({ index: true }) expiresAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
export type TenantMongoDocument = HydratedDocument<TenantDocument>;
export const TenantSchema = SchemaFactory.createForClass(TenantDocument);
TenantSchema.index({ isDemo: 1, expiresAt: 1 });
