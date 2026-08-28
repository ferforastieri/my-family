import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '@auth/guards/jwt-auth.guard';
import { TenancyService } from '../application/tenancy.service';
import { TenantAdminGuard } from './tenant-admin.guard';
import type { TenantFont, TenantPrincipal } from '../domain/tenant.entity';
import type { UserRole } from '@auth/domain/entities/user.entity';
import { DemoRestrictedGuard } from './demo-restricted.guard';

@Controller('tenant')
@UseGuards(JwtAuthGuard)
export class TenantController {
  constructor(private tenancy: TenancyService) {}
  @Get() current(@Req() req: { user: TenantPrincipal }) {
    return this.tenancy.current(req.user.tenantId);
  }
  @Patch() @UseGuards(TenantAdminGuard, DemoRestrictedGuard) update(
    @Req() req: { user: TenantPrincipal },
    @Body() body: { name?: string },
  ) {
    return this.tenancy.update(req.user.tenantId, body);
  }
  @Patch('theme') @UseGuards(TenantAdminGuard) theme(
    @Req() req: { user: TenantPrincipal },
    @Body() body: { primaryColor: string; fontFamily: TenantFont },
  ) {
    return this.tenancy.updateTheme(req.user.tenantId, body);
  }
  @Get('members') @UseGuards(TenantAdminGuard) members(
    @Req() req: { user: TenantPrincipal },
  ) {
    return this.tenancy.members(req.user.tenantId);
  }
  @Get('invitations') @UseGuards(TenantAdminGuard) invitations(
    @Req() req: { user: TenantPrincipal },
  ) {
    return this.tenancy.invitations(req.user.tenantId);
  }
  @Post('invitations') @UseGuards(TenantAdminGuard, DemoRestrictedGuard) invite(
    @Req() req: { user: TenantPrincipal },
    @Body()
    body: {
      phone: string;
      channel?: 'whatsapp' | 'sms';
      role?: 'admin' | 'member';
      relationship?: UserRole;
      access?: string[];
    },
  ) {
    return this.tenancy.invite(req.user.tenantId, req.user.id, body);
  }
  @Delete('invitations/:id')
  @UseGuards(TenantAdminGuard, DemoRestrictedGuard)
  revoke(@Req() req: { user: TenantPrincipal }, @Param('id') id: string) {
    return this.tenancy.revokeInvitation(req.user.tenantId, id);
  }
}

@Controller('invitations')
export class InvitationsController {
  constructor(private tenancy: TenancyService) {}
  @Post(':token/accept') @UseGuards(JwtAuthGuard) accept(
    @Req() req: { user: TenantPrincipal },
    @Param('token') token: string,
  ) {
    return this.tenancy.acceptInvitation(req.user.id, token);
  }
}
