import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import type { Request } from 'express';
import { Model } from 'mongoose';
import {
  AuditLogDocument,
  AuditLogMongoDocument,
} from '../infrastructure/persistence/audit-log.schema';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import type { AuditRecord } from '../domain/audit-record';

export type AuditPage = {
  items: Array<{
    id: string;
    action: string;
    resource: string;
    source: string;
    actorUserId?: string;
    actorEmail?: string;
    effectiveUserId?: string;
    effectiveUserEmail?: string;
    tenantId?: string;
    membershipId?: string;
    supportSessionId?: string;
    method?: string;
    path?: string;
    statusCode?: number;
    success: boolean;
    ip?: string;
    userAgent?: string;
    durationMs?: number;
    metadata: Record<string, unknown>;
    createdAt: Date;
  }>;
  page: number;
  limit: number;
  total: number;
  pages: number;
};

@Injectable()
export class AuditService {
  private readonly logger = new Logger('ApplicationAudit');

  constructor(
    @InjectModel(AuditLogDocument.name)
    private readonly audits: Model<AuditLogMongoDocument>,
  ) {}

  async record(record: AuditRecord): Promise<void> {
    const normalized = this.normalize(record);
    this.logAudit(normalized);
    try {
      await this.audits.create(normalized);
    } catch (error) {
      this.logger.error(
        `Não foi possível persistir auditoria: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  logAudit(record: AuditRecord): void {
    this.logger.log(
      JSON.stringify({ event: 'audit', ...this.normalize(record) }),
    );
  }

  private normalize(record: AuditRecord): AuditRecord {
    return {
      ...record,
      actorEmail: record.actorEmail?.trim().toLowerCase(),
      userAgent: record.userAgent?.slice(0, 500),
      ip: record.ip?.slice(0, 100),
      metadata: sanitizeMetadata(record.metadata),
    };
  }

  logRequest(record: AuditRecord): void {
    this.logger.log(JSON.stringify({ event: 'request', ...record }));
  }

  async list(page = 1, limit = 30): Promise<AuditPage> {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(100, Math.max(1, limit));
    const skip = (safePage - 1) * safeLimit;
    const [documents, total] = await Promise.all([
      this.audits
        .find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(safeLimit)
        .lean()
        .exec(),
      this.audits.countDocuments().exec(),
    ]);
    return {
      items: documents.map((document) => ({
        id: String(document._id),
        action: document.action,
        resource: document.resource,
        source: document.source,
        actorUserId: document.actorUserId,
        actorEmail: document.actorEmail,
        effectiveUserId: document.effectiveUserId,
        effectiveUserEmail: document.effectiveUserEmail,
        tenantId: document.tenantId,
        membershipId: document.membershipId,
        supportSessionId: document.supportSessionId,
        method: document.method,
        path: document.path,
        statusCode: document.statusCode,
        success: document.success,
        ip: document.ip,
        userAgent: document.userAgent,
        durationMs: document.durationMs,
        metadata: document.metadata ?? {},
        createdAt: document.createdAt,
      })),
      page: safePage,
      limit: safeLimit,
      total,
      pages: Math.max(1, Math.ceil(total / safeLimit)),
    };
  }

  countSince(date: Date): Promise<number> {
    return this.audits.countDocuments({ createdAt: { $gte: date } }).exec();
  }

  requestActor(request: Request): Partial<AuditRecord> {
    const user = (request as Request & { user?: UserEntity }).user;
    return {
      actorUserId: user?.actorUserId ?? user?.id,
      actorEmail: user?.actorEmail ?? user?.email,
      effectiveUserId: user?.actorUserId ? user.id : undefined,
      effectiveUserEmail: user?.actorUserId ? user.email : undefined,
      tenantId: user?.tenantId ?? undefined,
      membershipId: user?.membershipId ?? undefined,
      supportSessionId: user?.supportSessionId ?? undefined,
      ip: clientIp(request),
      userAgent: request.headers['user-agent'],
    };
  }
}

export function clientIp(request: Request): string | undefined {
  const forwarded = request.headers['x-forwarded-for'];
  if (typeof forwarded === 'string') return forwarded.split(',')[0]?.trim();
  if (Array.isArray(forwarded)) return forwarded[0];
  return request.ip || request.socket.remoteAddress;
}

function sanitizeMetadata(
  value?: Record<string, unknown>,
): Record<string, unknown> {
  if (!value) return {};
  const blocked = /password|token|secret|authorization|cookie/i;
  return Object.fromEntries(
    Object.entries(value)
      .filter(([key]) => !blocked.test(key))
      .slice(0, 30)
      .map(([key, item]) => [key, sanitizeValue(item)]),
  );
}

function sanitizeValue(value: unknown): unknown {
  if (
    value === null ||
    typeof value === 'boolean' ||
    typeof value === 'number'
  ) {
    return value;
  }
  if (typeof value === 'string') return value.slice(0, 500);
  if (Array.isArray(value)) return value.slice(0, 20).map(sanitizeValue);
  if (typeof value === 'object') {
    return sanitizeMetadata(value as Record<string, unknown>);
  }
  return String(value).slice(0, 500);
}
