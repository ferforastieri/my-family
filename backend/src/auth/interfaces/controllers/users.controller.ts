import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  NotFoundException,
  Query,
  Req,
} from '@nestjs/common';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { UpdateUserDto } from '../dto/user.dto';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { TenancyService } from '@tenancy/application/tenancy.service';
import type { TenantPrincipal } from '@tenancy/domain/tenant.entity';
import { DemoRestrictedGuard } from '@tenancy/interfaces/demo-restricted.guard';
import { TenantAdminGuard } from '@tenancy/interfaces/tenant-admin.guard';

@Controller('users')
@UseGuards(JwtAuthGuard, TenantAdminGuard)
export class UsersController {
  constructor(private tenancy: TenancyService) {}

  @Get()
  async list(
    @Req() req: { user: TenantPrincipal },
    @Query() query: PaginationQuery,
  ) {
    const items = await this.tenancy.members(req.user.tenantId);
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    return {
      items: items.slice((page - 1) * limit, page * limit),
      page,
      limit,
      total: items.length,
      pages: Math.max(1, Math.ceil(items.length / limit)),
    };
  }

  @Get(':id')
  async one(@Req() req: { user: TenantPrincipal }, @Param('id') id: string) {
    const user = await this.tenancy.member(req.user.tenantId, id);
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return user;
  }

  @Patch(':id')
  @UseGuards(DemoRestrictedGuard)
  async update(
    @Req() req: { user: TenantPrincipal },
    @Param('id') id: string,
    @Body() dto: UpdateUserDto,
  ) {
    const user = await this.tenancy.updateMember(
      req.user.tenantId,
      req.user.id,
      id,
      dto,
    );
    if (!user) throw new NotFoundException('Usuário não encontrado');
    return { message: 'Usuário atualizado.', ...user };
  }

  @Delete(':id')
  @UseGuards(DemoRestrictedGuard)
  async delete(@Req() req: { user: TenantPrincipal }, @Param('id') id: string) {
    const ok = await this.tenancy.removeMember(
      req.user.tenantId,
      req.user.id,
      id,
    );
    if (!ok) throw new NotFoundException('Usuário não encontrado');
    return { ok, message: 'Usuário removido.' };
  }
}
