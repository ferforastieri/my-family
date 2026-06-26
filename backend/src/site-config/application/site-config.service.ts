import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  SiteConfigDocument,
  SiteConfigMongoDocument,
  SiteConfigValue,
  SiteSectionKey,
} from '../infrastructure/persistence/site-config.schema';
import { TenantContext } from '@tenancy/application/tenant-context';
import { TenantService } from '@tenancy/application/tenant.service';

const sectionKeys: SiteSectionKey[] = [
  'events',
  'gallery',
  'songs',
  'letters',
  'journey',
];

@Injectable()
export class SiteConfigService {
  constructor(
    @InjectModel(SiteConfigDocument.name)
    private readonly configs: Model<SiteConfigMongoDocument>,
    private readonly context: TenantContext,
    private readonly tenants: TenantService,
  ) {}

  async get() {
    const tenant = await this.tenants.current();
    let document = await this.configs.findOne({ key: 'main' }).exec();
    if (!document) {
      document = await this.configs.create({
        key: 'main',
        draft: defaultConfig(tenant.name),
      });
    }
    return serialize(document);
  }

  async update(value: SiteConfigValue) {
    const tenant = await this.tenants.current();
    const draft = normalizeConfig(value, tenant.name);
    const document = await this.configs
      .findOneAndUpdate(
        { key: 'main' },
        { $set: { draft }, $setOnInsert: { key: 'main' } },
        { upsert: true, new: true },
      )
      .exec();
    return serialize(document!);
  }

  async publish() {
    const tenant = await this.tenants.assertEntitled();
    const document = await this.configs.findOne({ key: 'main' }).exec();
    if (!document) throw new BadRequestException('Configure o site primeiro.');
    const published = normalizeConfig(document.draft, tenant.name);
    document.published = published;
    document.publishedAt = new Date();
    await document.save();
    await this.tenants.setPublished(true);
    return serialize(document);
  }

  async unpublish() {
    await this.tenants.setPublished(false);
    return this.get();
  }

  async publishedForTenant(tenantId: string) {
    return this.context.run({ tenantId, isPublic: true }, async () => {
      const document = await this.configs
        .findOne({ key: 'main' })
        .lean()
        .exec();
      if (!document?.published) {
        throw new NotFoundException('Site ainda não foi publicado.');
      }
      return {
        value: document.published,
        publishedAt: document.publishedAt ?? null,
      };
    });
  }
}

function defaultConfig(name: string): SiteConfigValue {
  return {
    brand: {
      primaryColor: '#ff69b4',
      secondaryColor: '#7c3aed',
      fontPreset: 'romantic',
    },
    seo: {
      title: name,
      description: `Conheça a história e as memórias de ${name}.`,
    },
    sections: sectionKeys.map((key, order) => ({
      key,
      visible: key === 'events' || key === 'gallery',
      order,
      selectedIds: [],
    })),
  };
}

function normalizeConfig(
  value: SiteConfigValue,
  name: string,
): SiteConfigValue {
  const defaults = defaultConfig(name);
  const sectionMap = new Map(
    value.sections.map((section) => [section.key, section]),
  );
  return {
    brand: {
      primaryColor: value.brand.primaryColor,
      secondaryColor: value.brand.secondaryColor,
      fontPreset: value.brand.fontPreset,
      ...(value.brand.logoPath?.trim()
        ? { logoPath: value.brand.logoPath.trim() }
        : {}),
      ...(value.brand.coverPath?.trim()
        ? { coverPath: value.brand.coverPath.trim() }
        : {}),
    },
    seo: {
      title: value.seo.title.trim(),
      description: value.seo.description.trim(),
      ...(value.seo.socialImagePath?.trim()
        ? { socialImagePath: value.seo.socialImagePath.trim() }
        : {}),
    },
    sections: sectionKeys
      .map(
        (key) =>
          sectionMap.get(key) ??
          defaults.sections.find((row) => row.key === key)!,
      )
      .map((section, index) => ({
        key: section.key,
        visible: section.visible,
        order: section.order ?? index,
        selectedIds: [...new Set(section.selectedIds.map(String))],
      }))
      .sort((left, right) => left.order - right.order),
  };
}

function serialize(document: SiteConfigMongoDocument) {
  return {
    id: String(document._id),
    draft: document.draft,
    published: document.published ?? null,
    publishedAt: document.publishedAt ?? null,
    updatedAt: document.updatedAt,
  };
}
