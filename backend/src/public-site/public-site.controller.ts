import {
  BadRequestException,
  Controller,
  Get,
  Param,
  Query,
  StreamableFile,
  NotFoundException,
} from '@nestjs/common';
import { mediaType, UploadService } from '@shared/infrastructure/upload';
import { TenantService } from '@tenancy/application/tenant.service';
import { PublicSiteService } from './public-site.service';
import { Public } from '@auth/decorators/public.decorator';

@Controller('public/sites')
@Public()
export class PublicSiteController {
  constructor(
    private sites: PublicSiteService,
    private tenants: TenantService,
    private uploads: UploadService,
  ) {}

  @Get('demo')
  demo() {
    return this.sites.demo();
  }

  @Get('published-slugs')
  async publishedSlugs() {
    return { slugs: await this.sites.publishedSlugs() };
  }

  @Get(':slug')
  bySlug(@Param('slug') slug: string) {
    return this.sites.bySlug(slug);
  }

  @Get(':slug/media')
  async media(
    @Param('slug') slug: string,
    @Query('path') relativePath: string,
  ) {
    if (!relativePath) throw new BadRequestException('Caminho obrigatório.');
    const tenant = await this.tenants.publicBySlug(slug);
    if (!(await this.sites.canReadPublicMedia(tenant.id, relativePath))) {
      throw new NotFoundException('Mídia não encontrada.');
    }
    const file = await this.uploads.openTenantFile(tenant.id, relativePath);
    return new StreamableFile(file.stream, {
      type: file.contentType || mediaType(relativePath),
      length: file.contentLength,
    });
  }
}
