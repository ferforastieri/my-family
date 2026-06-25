import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({
  timestamps: true,
  collection: 'support_sessions',
})
export class SupportSessionDocument {
  @Prop({ required: true, unique: true, index: true })
  sessionId: string;

  @Prop({ required: true, index: true })
  actorUserId: string;

  @Prop({ required: true, index: true })
  effectiveUserId: string;

  @Prop({ required: true, index: true })
  tenantId: string;

  @Prop({ required: true, trim: true })
  reason: string;

  @Prop({ required: true, index: true })
  expiresAt: Date;

  @Prop()
  endedAt?: Date;

  createdAt: Date;
  updatedAt: Date;
}

export type SupportSessionMongoDocument =
  HydratedDocument<SupportSessionDocument>;
export const SupportSessionSchema = SchemaFactory.createForClass(
  SupportSessionDocument,
);
SupportSessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 86400 });
