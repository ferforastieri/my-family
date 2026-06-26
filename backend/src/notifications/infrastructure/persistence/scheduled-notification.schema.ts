import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { applyTenantScope } from '@tenancy/infrastructure/tenant-scope.plugin';

@Schema({ timestamps: true, collection: 'scheduled_notifications' })
export class ScheduledNotificationDocument {
  tenantId: string;

  @Prop({ required: true })
  title: string;

  @Prop({ default: '' })
  body?: string;

  @Prop({ default: '/' })
  url?: string;

  @Prop({ required: true })
  scheduledAt: Date;

  @Prop({
    required: true,
    default: 'pending',
    enum: ['pending', 'sent', 'failed', 'cancelled'],
  })
  status: 'pending' | 'sent' | 'failed' | 'cancelled';

  @Prop()
  sentAt?: Date;

  @Prop()
  error?: string;

  createdAt: Date;
  updatedAt: Date;
}

export type ScheduledNotificationMongoDocument =
  HydratedDocument<ScheduledNotificationDocument>;
export const ScheduledNotificationSchema = SchemaFactory.createForClass(
  ScheduledNotificationDocument,
);
applyTenantScope(ScheduledNotificationSchema);
