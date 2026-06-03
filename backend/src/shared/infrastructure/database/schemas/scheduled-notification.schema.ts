import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: true, collection: 'scheduled_notifications' })
export class ScheduledNotificationDocument {
  @Prop({ required: true })
  title: string;

  @Prop({ default: '' })
  body?: string;

  @Prop({ default: '/' })
  url?: string;

  @Prop({ required: true })
  scheduledAt: Date;

  @Prop({ required: true, default: 'pending', enum: ['pending', 'sent', 'failed', 'cancelled'] })
  status: 'pending' | 'sent' | 'failed' | 'cancelled';

  @Prop()
  sentAt?: Date;

  @Prop()
  error?: string;

  createdAt: Date;
  updatedAt: Date;
}

export type ScheduledNotificationMongoDocument = HydratedDocument<ScheduledNotificationDocument>;
export const ScheduledNotificationSchema = SchemaFactory.createForClass(ScheduledNotificationDocument);

