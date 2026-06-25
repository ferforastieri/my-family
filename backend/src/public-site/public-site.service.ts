import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  FotoDocument,
  FotoMongoDocument,
  HomeSettingsDocument,
  HomeSettingsMongoDocument,
  MusicaDocument,
  MusicaMongoDocument,
} from '@shared/infrastructure/database/schemas';
import { CartasService } from '@cartas/application/services/cartas.service';
import { TenantContext } from '@tenancy/application/tenant-context';
import { TenantService } from '@tenancy/application/tenant.service';
import { TenantRepository } from '@tenancy/infrastructure/tenant.repository';
import { SiteConfigService } from '../site-config/application/site-config.service';

@Injectable()
export class PublicSiteService {
  constructor(
    private context: TenantContext,
    private tenants: TenantService,
    private tenantRepository: TenantRepository,
    private cartas: CartasService,
    private siteConfigs: SiteConfigService,
    @InjectModel(HomeSettingsDocument.name)
    private homeSettings: Model<HomeSettingsMongoDocument>,
    @InjectModel(FotoDocument.name)
    private photos: Model<FotoMongoDocument>,
    @InjectModel(MusicaDocument.name)
    private songs: Model<MusicaMongoDocument>,
  ) {}

  async bySlug(slug: string) {
    const tenant = await this.tenants.publicBySlug(slug);
    return this.load(tenant);
  }

  async demo() {
    const tenant = await this.tenantRepository.findDemoTenant();
    if (!tenant) throw new NotFoundException('Demonstração não configurada.');
    return this.load(tenant);
  }

  async publishedSlugs(): Promise<string[]> {
    const tenants = await this.tenantRepository.listAllTenants();
    return tenants
      .filter((tenant) => tenant.isPublished && tenant.status === 'active')
      .map((tenant) => tenant.slug);
  }

  private async load(tenant: {
    id: string;
    name: string;
    slug: string;
    defaultLocale: string;
    theme: Record<string, unknown>;
    isDemo: boolean;
  }) {
    return this.context.run(
      {
        tenantId: tenant.id,
        tenantSlug: tenant.slug,
        isDemo: tenant.isDemo,
        isPublic: true,
      },
      async () => {
        const siteConfig = await this.siteConfigs.publishedForTenant(tenant.id);
        const sections = new Map(
          siteConfig.value.sections.map((section) => [section.key, section]),
        );
        const photoIds = selectedIds(sections, 'gallery');
        const songIds = selectedIds(sections, 'songs');
        const letterIds = selectedIds(sections, 'letters');
        const journeyIds = selectedIds(sections, 'journey');
        const [home, photos, songs, allLetters, allJourney] = await Promise.all([
          this.homeSettings.findOne({ key: 'home' }).lean().exec(),
          this.photos
            .find(photoIds.length ? { _id: { $in: photoIds } } : { _id: null })
            .sort({ data: -1, createdAt: -1 })
            .limit(100)
            .lean()
            .exec(),
          this.songs
            .find(songIds.length ? { _id: { $in: songIds } } : { _id: null })
            .sort({ data: -1, createdAt: -1 })
            .limit(100)
            .lean()
            .exec(),
          this.cartas.listForPublic('letter', 100, -1),
          this.cartas.listForPublic('journey', 100, 1),
        ]);
        const letters = orderSelected(allLetters, letterIds);
        const journey = orderSelected(allJourney, journeyIds);
        return {
          tenant: {
            name: tenant.name,
            slug: tenant.slug,
            locale: tenant.defaultLocale,
            theme: tenant.theme,
            isDemo: tenant.isDemo,
          },
          site: siteConfig.value,
          publishedAt: siteConfig.publishedAt,
          home: home
            ? {
                events: home.events,
                galleryImages: home.galleryImages,
                galleryOrder: home.galleryOrder,
              }
            : { events: [], galleryImages: [], galleryOrder: null },
          photos: orderSelected(photos.map(stripDocument), photoIds),
          songs: orderSelected(songs.map(stripDocument), songIds),
          letters,
          journey,
        };
      },
    );
  }

  async canReadPublicMedia(tenantId: string, relativePath: string) {
    return this.context.run({ tenantId, isPublic: true }, async () => {
      const settings = await this.homeSettings
        .findOne({ key: 'home', galleryImages: relativePath })
        .select({ _id: 1 })
        .lean()
        .exec();
      if (settings) return true;
      const config = await this.siteConfigs.publishedForTenant(tenantId);
      const directPaths = [
        config.value.brand.logoPath,
        config.value.brand.coverPath,
        config.value.seo.socialImagePath,
      ].filter(Boolean);
      if (directPaths.includes(relativePath)) return true;
      const photoIds = selectedIds(
        new Map(
          config.value.sections.map((section) => [section.key, section]),
        ),
        'gallery',
      );
      if (!photoIds.length) return false;
      return !!(await this.photos
        .findOne({ _id: { $in: photoIds }, url: relativePath })
        .select({ _id: 1 })
        .lean()
        .exec());
    });
  }
}

function stripDocument(document: Record<string, any>) {
  const { _id, tenantId: _tenantId, __v: _version, ...data } = document;
  return { id: String(_id), ...data };
}

function selectedIds(
  sections: Map<
    string,
    { visible: boolean; selectedIds: string[] }
  >,
  key: string,
): string[] {
  const section = sections.get(key);
  return section?.visible ? section.selectedIds : [];
}

function orderSelected<T extends { id: string }>(
  items: T[],
  ids: string[],
): T[] {
  const byId = new Map(items.map((item) => [item.id, item]));
  return ids.flatMap((id) => {
    const item = byId.get(id);
    return item ? [item] : [];
  });
}
