import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { BillingService } from '../billing/application/billing.service';
import type { SubscriptionPlanRecord } from '../billing/infrastructure/billing.repository';
import {
  LandingLocale,
  LegalDocument,
  LegalDocumentKind,
  LegalDocumentMongoDocument,
  landingLocales,
} from './persistence/legal-document.schema';

export type PublicLegalDocument = {
  id: string;
  kind: LegalDocumentKind;
  locale: LandingLocale;
  title: string;
  body: string;
  format: 'plain' | 'markdown';
  effectiveDate: Date | null;
  updatedAt: Date;
};

@Injectable()
export class LandingService {
  constructor(
    private readonly billing: BillingService,
    @InjectModel(LegalDocument.name)
    private readonly legalDocuments: Model<LegalDocumentMongoDocument>,
  ) {}

  async landing(locale?: string) {
    const resolvedLocale = normalizeLandingLocale(locale);
    const [plans, privacyPolicy] = await Promise.all([
      this.billing.listPlans({ activeOnly: true }),
      this.privacyPolicy(resolvedLocale),
    ]);
    return {
      locale: resolvedLocale,
      plans: plans.map(publicPlan),
      privacyPolicy,
    };
  }

  async privacyPolicy(locale?: string): Promise<PublicLegalDocument | null> {
    const resolvedLocale = normalizeLandingLocale(locale);
    const document = await this.legalDocuments
      .findOne({
        kind: 'privacy-policy',
        locale: resolvedLocale,
        published: true,
      })
      .sort({ updatedAt: -1 })
      .exec();
    return toPublicLegalDocument(document);
  }
}

export function normalizeLandingLocale(locale?: string): LandingLocale {
  const candidate = locale?.trim().toLowerCase().split('-')[0];
  return landingLocales.includes(candidate as LandingLocale)
    ? (candidate as LandingLocale)
    : 'pt';
}

export function toPublicLegalDocument(
  document: LegalDocumentMongoDocument | null,
): PublicLegalDocument | null {
  if (!document) return null;
  return {
    id: String(document._id),
    kind: document.kind,
    locale: document.locale,
    title: document.title,
    body: document.body,
    format: document.format,
    effectiveDate: document.effectiveDate ?? null,
    updatedAt: document.updatedAt,
  };
}

function publicPlan(plan: SubscriptionPlanRecord) {
  return {
    id: plan.id,
    interval: plan.interval,
    name: plan.name,
    description: plan.description,
    priceCents: plan.priceCents,
    currency: plan.currency,
    highlighted: plan.highlighted,
    sortOrder: plan.sortOrder,
    updatedAt: plan.updatedAt,
  };
}
