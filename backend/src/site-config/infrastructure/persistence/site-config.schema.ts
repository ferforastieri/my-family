import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { applyTenantScope } from '@tenancy/infrastructure/tenant-scope.plugin';

export type SiteSectionKey =
  | 'events'
  | 'gallery'
  | 'songs'
  | 'letters'
  | 'journey';

export type SiteConfigValue = {
  brand: {
    logoPath?: string;
    coverPath?: string;
    primaryColor: string;
    secondaryColor: string;
    fontPreset: 'romantic' | 'classic' | 'modern';
  };
  seo: {
    title: string;
    description: string;
    socialImagePath?: string;
  };
  sections: Array<{
    key: SiteSectionKey;
    visible: boolean;
    order: number;
    selectedIds: string[];
  }>;
};

@Schema({ timestamps: true, collection: 'site_configs' })
export class SiteConfigDocument {
  @Prop({ required: true, default: 'main' })
  key: string;

  @Prop({ type: Object, required: true })
  draft: SiteConfigValue;

  @Prop({ type: Object })
  published?: SiteConfigValue;

  @Prop()
  publishedAt?: Date;

  createdAt: Date;
  updatedAt: Date;
}

export type SiteConfigMongoDocument = HydratedDocument<SiteConfigDocument>;
export const SiteConfigSchema = SchemaFactory.createForClass(SiteConfigDocument);
SiteConfigSchema.index({ tenantId: 1, key: 1 }, { unique: true });
applyTenantScope(SiteConfigSchema);
