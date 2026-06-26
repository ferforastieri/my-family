import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import {
  SubscriptionPlanInterval,
  subscriptionPlanIntervals,
} from './subscription-plan.schema';

@Schema({ timestamps: true, collection: 'subscriptions' })
export class SubscriptionDocument {
  @Prop({ required: true, unique: true, index: true })
  tenantId: string;

  @Prop({ required: true, default: 'stripe' })
  provider: 'stripe';

  @Prop({ enum: subscriptionPlanIntervals })
  planInterval?: SubscriptionPlanInterval;

  @Prop()
  planName?: string;

  @Prop()
  priceCents?: number;

  @Prop()
  currency?: string;

  @Prop({ index: true })
  customerId?: string;

  @Prop({ index: true })
  subscriptionId?: string;

  @Prop({ index: true })
  checkoutSessionId?: string;

  @Prop()
  priceId?: string;

  @Prop({ required: true, default: 'pending' })
  status: string;

  @Prop()
  currentPeriodEnd?: Date;

  @Prop()
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
  @Prop({ required: true, unique: true })
  providerEventId: string;

  @Prop({ required: true })
  type: string;

  createdAt: Date;
}

export type BillingEventMongoDocument = HydratedDocument<BillingEventDocument>;
export const BillingEventSchema =
  SchemaFactory.createForClass(BillingEventDocument);
