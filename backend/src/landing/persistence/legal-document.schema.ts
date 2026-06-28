import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export const landingLocales = ['pt', 'en', 'es'] as const;
export type LandingLocale = (typeof landingLocales)[number];

export const legalDocumentKinds = ['privacy-policy'] as const;
export type LegalDocumentKind = (typeof legalDocumentKinds)[number];

export const legalDocumentFormats = ['plain', 'markdown'] as const;
export type LegalDocumentFormat = (typeof legalDocumentFormats)[number];

@Schema({ timestamps: true, collection: 'public_legal_documents' })
export class LegalDocument {
  @Prop({
    type: String,
    required: true,
    enum: legalDocumentKinds,
    index: true,
  })
  kind: LegalDocumentKind;

  @Prop({ type: String, required: true, enum: landingLocales, index: true })
  locale: LandingLocale;

  @Prop({ type: String, required: true })
  title: string;

  @Prop({ type: String, required: true })
  body: string;

  @Prop({
    type: String,
    required: true,
    enum: legalDocumentFormats,
    default: 'markdown',
  })
  format: LegalDocumentFormat;

  @Prop({ type: Boolean, required: true, default: true, index: true })
  published: boolean;

  @Prop({ type: Date })
  effectiveDate?: Date | null;

  createdAt: Date;
  updatedAt: Date;
}

export type LegalDocumentMongoDocument = HydratedDocument<LegalDocument>;
export const LegalDocumentSchema = SchemaFactory.createForClass(LegalDocument);

LegalDocumentSchema.index(
  { kind: 1, locale: 1 },
  { name: 'legal_document_kind_locale_unique', unique: true },
);
LegalDocumentSchema.index(
  { kind: 1, locale: 1, published: 1, updatedAt: -1 },
  { name: 'legal_document_public_lookup' },
);
