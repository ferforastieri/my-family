import {
  Controller,
  Get,
  ParseIntPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { PlatformAdminGuard } from './platform-admin.guard';
import { PlatformAdminService } from './platform-admin.service';

@Controller('platform/admin')
@UseGuards(PlatformAdminGuard)
export class PlatformAdminController {
  constructor(private readonly platform: PlatformAdminService) {}

  @Get('overview')
  overview() {
    return this.platform.overview();
  }

  @Get('audit')
  audit(
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit = 30,
  ) {
    return this.platform.auditLogs(page, limit);
  }
}
