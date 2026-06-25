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

@Injectable()
export class PublicSiteService {
  constructor(
    private context: TenantContext,
    private tenants: TenantService,
    private tenantRepository: TenantRepository,
    private cartas: CartasService,
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
        const [home, photos, songs, letters, journey] = await Promise.all([
          this.homeSettings.findOne({ key: 'home' }).lean().exec(),
          this.photos
            .find()
            .sort({ data: -1, createdAt: -1 })
            .limit(24)
            .lean()
            .exec(),
          this.songs
            .find()
            .sort({ data: -1, createdAt: -1 })
            .limit(24)
            .lean()
            .exec(),
          this.cartas.listForPublic('letter', 12, -1),
          this.cartas.listForPublic('journey', 30, 1),
        ]);
        const publicGallery = home?.galleryImages ?? [];
        const isDemo = tenant.isDemo;
        return {
          tenant: {
            name: tenant.name,
            slug: tenant.slug,
            locale: tenant.defaultLocale,
            theme: tenant.theme,
            isDemo: tenant.isDemo,
          },
          home: home
            ? {
                events: home.events,
                galleryImages: home.galleryImages,
                galleryOrder: home.galleryOrder,
              }
            : { events: [], galleryImages: [], galleryOrder: null },
          photos: isDemo
            ? photos.map(stripDocument)
            : publicGallery.map((url, index) => ({
                id: `gallery-${index}`,
                url,
                album: tenant.name,
              })),
          songs: isDemo ? songs.map(stripDocument) : [],
          letters: isDemo ? letters : [],
          journey: isDemo ? journey : [],
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
      return !!settings;
    });
  }
}

function stripDocument(document: Record<string, any>) {
  const { _id, tenantId: _tenantId, __v: _version, ...data } = document;
  return { id: String(_id), ...data };
}
