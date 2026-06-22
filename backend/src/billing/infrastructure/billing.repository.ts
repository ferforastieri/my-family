import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  BillingEventDocument,
  BillingEventMongoDocument,
  SubscriptionDocument,
  SubscriptionMongoDocument,
} from '@shared/infrastructure/database/schemas';
import { cleanUndefined, toId } from '@shared/infrastructure/database/mongo.utils';

export type SubscriptionRecord = {
  id: string;
  tenantId: string;
  provider: 'stripe';
  customerId?: string | null;
  subscriptionId?: string | null;
  checkoutSessionId?: string | null;
  priceId?: string | null;
  status: string;
  currentPeriodEnd?: Date | null;
  cancelAtPeriodEnd: boolean;
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class BillingRepository {
  constructor(
    @InjectModel(SubscriptionDocument.name)
    private subscriptions: Model<SubscriptionMongoDocument>,
    @InjectModel(BillingEventDocument.name)
    private events: Model<BillingEventMongoDocument>,
  ) {}

  private toRecord(document: SubscriptionMongoDocument | null): SubscriptionRecord | null {
    if (!document) return null;
    return {
      id: toId(document),
      tenantId: document.tenantId,
      provider: 'stripe',
      customerId: document.customerId ?? null,
      subscriptionId: document.subscriptionId ?? null,
      checkoutSessionId: document.checkoutSessionId ?? null,
      priceId: document.priceId ?? null,
      status: document.status,
      currentPeriodEnd: document.currentPeriodEnd ?? null,
      cancelAtPeriodEnd: document.cancelAtPeriodEnd ?? false,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
    };
  }

  async findByTenant(tenantId: string) {
    return this.toRecord(await this.subscriptions.findOne({ tenantId }).exec());
  }

  async findBySubscriptionId(subscriptionId: string) {
    return this.toRecord(
      await this.subscriptions.findOne({ subscriptionId }).exec(),
    );
  }

  async upsert(
    tenantId: string,
    data: Partial<Omit<SubscriptionRecord, 'id' | 'tenantId' | 'createdAt' | 'updatedAt'>>,
  ) {
    return this.toRecord(
      await this.subscriptions
        .findOneAndUpdate(
          { tenantId },
          {
            $set: cleanUndefined(data as Record<string, unknown>),
            $setOnInsert: { tenantId, provider: 'stripe' },
          },
          { upsert: true, new: true, setDefaultsOnInsert: true },
        )
        .exec(),
    )!;
  }

  async reserveEvent(providerEventId: string, type: string): Promise<boolean> {
    try {
      await this.events.create({ providerEventId, type });
      return true;
    } catch (error) {
      if ((error as { code?: number })?.code === 11000) return false;
      throw error;
    }
  }

  async releaseEvent(providerEventId: string): Promise<void> {
    await this.events.deleteOne({ providerEventId }).exec();
  }
}

