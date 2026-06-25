import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'audit_logs',
})
export class AuditLogDocument {
  @Prop({ required: true, index: true })
  action: string;

  @Prop({ required: true, index: true })
  resource: string;

  @Prop({ required: true, enum: ['http', 'websocket', 'system'], index: true })
  source: 'http' | 'websocket' | 'system';

  @Prop({ index: true })
  actorUserId?: string;

  @Prop({ index: true, lowercase: true })
  actorEmail?: string;

  @Prop({ index: true })
  tenantId?: string;

  @Prop()
  method?: string;

  @Prop()
  path?: string;

  @Prop()
  statusCode?: number;

  @Prop({ required: true, index: true })
  success: boolean;

  @Prop()
  ip?: string;

  @Prop()
  userAgent?: string;

  @Prop()
  durationMs?: number;

  @Prop({ type: Object, default: {} })
  metadata: Record<string, unknown>;

  createdAt: Date;
}

export type AuditLogMongoDocument = HydratedDocument<AuditLogDocument>;
export const AuditLogSchema = SchemaFactory.createForClass(AuditLogDocument);
AuditLogSchema.index({ createdAt: -1 });
AuditLogSchema.index({ tenantId: 1, createdAt: -1 });
AuditLogSchema.index({ actorUserId: 1, createdAt: -1 });
AuditLogSchema.index(
  { createdAt: 1 },
  { expireAfterSeconds: 60 * 60 * 24 * 180 },
);
