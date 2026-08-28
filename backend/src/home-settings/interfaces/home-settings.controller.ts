import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { TenantAdminGuard } from '@tenancy/interfaces/tenant-admin.guard';
import { HomeSettingsService } from '../application/home-settings.service';

type HomeSettingsWrite = Parameters<HomeSettingsService['update']>[0];

@Controller('home/settings')
@UseGuards(JwtAuthGuard)
export class HomeSettingsController {
  constructor(private readonly settings: HomeSettingsService) {}

  @Get()
  get() {
    return this.settings.get();
  }

  @Put()
  @UseGuards(TenantAdminGuard)
  async update(@Body() data: HomeSettingsWrite) {
    const row = await this.settings.update(data);
    return { message: 'Datas da Home atualizadas.', ...row };
  }
}
