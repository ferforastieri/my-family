import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import {
  SubscriptionPlanInterval,
  subscriptionPlanIntervals,
} from './subscription-plan.schema';

@Schema({ timestamps: true, collection: 'subscriptions' })
export class SubscriptionDocument {
  @Prop({ type: String, required: true, unique: true, index: true })
  tenantId: string;

  @Prop({ type: String, required: true, default: 'stripe' })
  provider: 'stripe';

  @Prop({ type: String, enum: subscriptionPlanIntervals })
  planInterval?: SubscriptionPlanInterval;

  @Prop({ type: String })
  planName?: string;

  @Prop({ type: Number })
  priceCents?: number;

  @Prop({ type: String })
  currency?: string;

  @Prop({ type: String, index: true })
  customerId?: string;

  @Prop({ type: String, index: true })
  subscriptionId?: string;

  @Prop({ type: String, index: true })
  checkoutSessionId?: string;

  @Prop({ type: String })
  priceId?: string;

  @Prop({ type: String, required: true, default: 'pending' })
  status: string;

  @Prop({ type: Date })
  currentPeriodEnd?: Date;

  @Prop({ type: Boolean })
  cancelAtPeriodEnd?: boolean;

  createdAt: Date;
  updatedAt: Date;
}

export type SubscriptionMongoDocument = HydratedDocument<SubscriptionDocument>;
export const SubscriptionSchema =
  SchemaFactory.createForClass(SubscriptionDocument);

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'billing_events',
})
export class BillingEventDocument {
  @Prop({ type: String, required: true, unique: true })
  providerEventId: string;

  @Prop({ type: String, required: true })
  type: string;

  createdAt: Date;
}

export type BillingEventMongoDocument = HydratedDocument<BillingEventDocument>;
export const BillingEventSchema =
  SchemaFactory.createForClass(BillingEventDocument);
