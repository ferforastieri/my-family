import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'push_subscriptions',
})
export class PushSubscriptionDocument {
  @Prop({ required: true })
  fcmToken?: string;

  @Prop({ index: true })
  userId?: string;

  @Prop({ default: 'unknown' })
  platform?: 'web' | 'android' | 'ios' | 'unknown';

  @Prop()
  userAgent?: string;

  createdAt: Date;
}

export type PushSubscriptionMongoDocument =
  HydratedDocument<PushSubscriptionDocument>;
export const PushSubscriptionSchema = SchemaFactory.createForClass(
  PushSubscriptionDocument,
);

PushSubscriptionSchema.index(
  { fcmToken: 1 },
  {
    name: 'fcmToken_unique_string',
    unique: true,
    partialFilterExpression: { fcmToken: { $type: 'string' } },
  },
);
