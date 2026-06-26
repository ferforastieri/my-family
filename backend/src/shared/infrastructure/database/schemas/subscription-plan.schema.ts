import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export const subscriptionPlanIntervals = [
  'monthly',
  'semiannual',
  'annual',
  'lifetime',
] as const;

export type SubscriptionPlanInterval =
  (typeof subscriptionPlanIntervals)[number];

@Schema({ timestamps: true, collection: 'subscription_plans' })
export class SubscriptionPlanDocument {
  @Prop({
    required: true,
    unique: true,
    index: true,
    enum: subscriptionPlanIntervals,
  })
  interval: SubscriptionPlanInterval;

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  description: string;

  @Prop({ required: true, min: 0 })
  priceCents: number;

  @Prop({ required: true, default: 'BRL' })
  currency: string;

  @Prop()
  stripePriceId?: string;

  @Prop({ required: true, default: true })
  active: boolean;

  @Prop({ required: true, default: false })
  highlighted: boolean;

  @Prop({ required: true, default: 0 })
  sortOrder: number;

  createdAt: Date;
  updatedAt: Date;
}

export type SubscriptionPlanMongoDocument =
  HydratedDocument<SubscriptionPlanDocument>;
export const SubscriptionPlanSchema = SchemaFactory.createForClass(
  SubscriptionPlanDocument,
);
