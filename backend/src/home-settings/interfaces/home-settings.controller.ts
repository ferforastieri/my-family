import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { Roles } from '@auth/decorators/roles.decorator';
import { RolesGuard } from '@auth/guards/roles.guard';
import { HomeSettingsService } from '../application/home-settings.service';

@Controller('home-settings')
export class HomeSettingsController {
  constructor(private readonly settings: HomeSettingsService) {}

  @Get()
  get() {
    return this.settings.get();
  }

  @Put()
  @UseGuards(RolesGuard)
  @Roles('owner', 'admin')
  async update(@Body() body: Parameters<HomeSettingsService['update']>[0]) {
    const settings = await this.settings.update(body);
    return { message: 'Datas da Home atualizadas.', ...settings };
  }
}
