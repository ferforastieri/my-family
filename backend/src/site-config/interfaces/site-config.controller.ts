import { Body, Controller, Get, Post, Put, UseGuards } from '@nestjs/common';
import { Roles } from '@auth/decorators/roles.decorator';
import { RolesGuard } from '@auth/guards/roles.guard';
import { SiteConfigService } from '../application/site-config.service';
import { UpdateSiteConfigDto } from './site-config.dto';

@Controller('site-config')
export class SiteConfigController {
  constructor(private readonly sites: SiteConfigService) {}

  @Get()
  get() {
    return this.sites.get();
  }

  @Put()
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async update(@Body() dto: UpdateSiteConfigDto) {
    const config = await this.sites.update(dto);
    return { message: 'Configuração salva.', ...config };
  }

  @Post('publish')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async publish() {
    const config = await this.sites.publish();
    return { message: 'Site publicado.', ...config };
  }

  @Post('unpublish')
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async unpublish() {
    const config = await this.sites.unpublish();
    return { message: 'Site retirado do ar.', ...config };
  }
}
