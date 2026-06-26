import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { applyTenantScope } from '@tenancy/infrastructure/tenant-scope.plugin';

@Schema({ timestamps: true, collection: 'family_lists' })
export class FamilyListDocument {
  @Prop({ required: true, trim: true })
  title: string;

  @Prop()
  description?: string;

  @Prop()
  createdBy?: string;

  createdAt: Date;
  updatedAt: Date;
}

export type FamilyListMongoDocument = HydratedDocument<FamilyListDocument>;
export const FamilyListSchema =
  SchemaFactory.createForClass(FamilyListDocument);
applyTenantScope(FamilyListSchema);
