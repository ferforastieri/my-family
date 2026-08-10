import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { Roles } from '@auth/decorators/roles.decorator';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { RolesGuard } from '@auth/guards/roles.guard';
import { HomeSettingsService } from '../application/home-settings.service';

type HomeSettingsWrite = Parameters<HomeSettingsService['update']>[0];

@Controller('home/settings')
export class HomeSettingsController {
  constructor(private readonly settings: HomeSettingsService) {}

  @Get()
  get() {
    return this.settings.get();
  }

  @Put()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('husband', 'wife')
  async update(@Body() data: HomeSettingsWrite) {
    const row = await this.settings.update(data);
    return { message: 'Datas da Home atualizadas.', ...row };
  }
}
