import {
  BadRequestException,
  Controller,
  Get,
  Param,
  Query,
  StreamableFile,
  NotFoundException,
} from '@nestjs/common';
import { createReadStream } from 'node:fs';
import { UploadService } from '@shared/infrastructure/upload';
import { TenantService } from '@tenancy/application/tenant.service';
import { PublicSiteService } from './public-site.service';

@Controller('public/sites')
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

  @Get(':slug')
  bySlug(@Param('slug') slug: string) {
    return this.sites.bySlug(slug);
  }

  @Get(':slug/media')
  async media(@Param('slug') slug: string, @Query('path') relativePath: string) {
    if (!relativePath) throw new BadRequestException('Caminho obrigatório.');
    const tenant = await this.tenants.publicBySlug(slug);
    if (!(await this.sites.canReadPublicMedia(tenant.id, relativePath))) {
      throw new NotFoundException('Mídia não encontrada.');
    }
    const fullPath = this.uploads.resolveTenantPath(tenant.id, relativePath);
    return new StreamableFile(createReadStream(fullPath), {
      type: mediaType(relativePath),
    });
  }
}

function mediaType(path: string) {
  const extension = path.split('.').pop()?.toLowerCase();
  if (extension === 'png') return 'image/png';
  if (extension === 'gif') return 'image/gif';
  if (extension === 'webp') return 'image/webp';
  if (extension === 'mp4') return 'video/mp4';
  if (extension === 'webm') return 'video/webm';
  return 'image/jpeg';
}
