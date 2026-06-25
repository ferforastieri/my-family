import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import type {
  TenantLocale,
  TenantStatus,
} from '@tenancy/domain/tenant.entity';

@Schema({ timestamps: true, collection: 'tenants' })
export class TenantDocument {
  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  slug: string;

  @Prop({ required: true, index: true })
  ownerUserId: string;

  @Prop({
    type: String,
    required: true,
    enum: ['pt-BR', 'en', 'es'],
    default: 'pt-BR',
  })
  defaultLocale: TenantLocale;

  @Prop({
    type: String,
    required: true,
    enum: [
      'draft',
      'pending_payment',
      'active',
      'past_due',
      'suspended',
      'canceled',
    ],
    default: 'draft',
    index: true,
  })
  status: TenantStatus;

  @Prop({ required: true, default: false })
  isDemo: boolean;

  @Prop({ required: true, default: false, index: true })
  isPublished: boolean;

  @Prop({ type: Object, required: true, default: {} })
  theme: Record<string, unknown>;

  createdAt: Date;
  updatedAt: Date;
}

export type TenantMongoDocument = HydratedDocument<TenantDocument>;
export const TenantSchema = SchemaFactory.createForClass(TenantDocument);
