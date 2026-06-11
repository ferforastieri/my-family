import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'notifications',
})
export class NotificationDocument {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true, default: '' })
  body: string;

  @Prop({ required: true, default: '/' })
  url: string;

  @Prop()
  icon?: string;

  @Prop({
    required: true,
    default: 'manual',
    enum: ['manual', 'push', 'chat', 'location', 'letter', 'system'],
  })
  type: 'manual' | 'push' | 'chat' | 'location' | 'letter' | 'system';

  @Prop({ type: [String], default: [] })
  readBy: string[];

  createdAt: Date;
}

export type NotificationMongoDocument = HydratedDocument<NotificationDocument>;
export const NotificationSchema =
  SchemaFactory.createForClass(NotificationDocument);
NotificationSchema.index(
  { title: 1, body: 1, url: 1, type: 1 },
  { unique: true },
);
