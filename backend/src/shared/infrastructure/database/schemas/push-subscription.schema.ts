import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema({ timestamps: { createdAt: true, updatedAt: false }, collection: 'push_subscriptions' })
export class PushSubscriptionDocument {
  @Prop({ required: true, unique: true })
  endpoint: string;

  @Prop({ type: Object, required: true })
  keys: { p256dh: string; auth: string };

  @Prop()
  userAgent?: string;

  createdAt: Date;
}

export type PushSubscriptionMongoDocument = HydratedDocument<PushSubscriptionDocument>;
export const PushSubscriptionSchema = SchemaFactory.createForClass(PushSubscriptionDocument);

