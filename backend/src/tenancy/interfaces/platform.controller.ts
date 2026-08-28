import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { TenancyRepository } from '../infrastructure/tenancy.repository';
import { PlatformAdminGuard } from './platform-admin.guard';

@Controller('platform')
@UseGuards(JwtAuthGuard, PlatformAdminGuard)
export class PlatformController {
  constructor(private repo: TenancyRepository) {}
  @Get('tenants') list(
    @Query('page') rawPage?: string,
    @Query('limit') rawLimit?: string,
  ) {
    const page = Math.max(1, Number(rawPage) || 1);
    const limit = Math.min(100, Math.max(1, Number(rawLimit) || 20));
    return this.repo.listTenants(page, limit);
  }
  @Patch('tenants/:id/status') status(
    @Param('id') id: string,
    @Body('status') status: 'active' | 'suspended',
  ) {
    if (!['active', 'suspended'].includes(status)) {
      throw new BadRequestException('Status inválido.');
    }
    return this.repo.updateTenant(id, { status });
  }
}
