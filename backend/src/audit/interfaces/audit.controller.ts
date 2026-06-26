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
    const record = {
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
    } as const;
    if (shouldPersistClientEvent(dto.action)) {
      await this.audit.record(record);
    } else {
      this.audit.logAudit(record);
    }
    return { message: 'Evento monitorado.' };
  }
}

function shouldPersistClientEvent(action: string): boolean {
  const normalized = action.trim().toLowerCase();
  if (
    !normalized ||
    normalized === 'navigation' ||
    normalized === 'app.opened'
  ) {
    return false;
  }
  return /(^|[._-])(admin|billing|checkout|clear|cleared|create|created|delete|deleted|edit|edited|error|failed|failure|login|logout|payment|password|remove|removed|schedule|scheduled|security|send|sent|subscription|update|updated)([._-]|$)/.test(
    normalized,
  );
}
