import { Body, Controller, Post, Req } from '@nestjs/common';
import type { Request } from 'express';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { AuditService } from '../application/audit.service';
import { ClientAuditDto } from './client-audit.dto';

@Controller('audit')
export class AuditController {
  constructor(private readonly audit: AuditService) {}

  @Post('client-event')
  async clientEvent(
    @Req() request: Request & { user: UserEntity },
    @Body() dto: ClientAuditDto,
  ) {
    await this.audit.record({
      action: `client.${dto.action}`,
      resource: 'client',
      source: 'system',
      success: true,
      ...this.audit.requestActor(request),
      actorUserId: request.user.id,
      actorEmail: request.user.email,
      tenantId: request.user.tenantId,
      path: dto.path,
      metadata: dto.metadata,
    });
    return { message: 'Evento monitorado.' };
  }
}
