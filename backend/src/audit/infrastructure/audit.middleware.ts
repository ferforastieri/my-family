import { Injectable, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';
import { randomUUID } from 'node:crypto';
import { AuditService, clientIp } from '../application/audit.service';
import type { UserEntity } from '@auth/domain/entities/user.entity';

@Injectable()
export class AuditMiddleware implements NestMiddleware {
  constructor(private readonly audit: AuditService) {}

  use(request: Request, response: Response, next: NextFunction): void {
    const startedAt = Date.now();
    const requestId =
      request.headers['x-request-id']?.toString() || randomUUID();
    response.setHeader('x-request-id', requestId);

    response.on('finish', () => {
      const user = (request as Request & { user?: UserEntity }).user;
      const path = request.originalUrl.split('?')[0] || request.path;
      const record = {
        action: requestAction(request.method, path),
        resource: resourceFromPath(path),
        source: 'http' as const,
        actorUserId: user?.id,
        actorEmail: user?.email,
        tenantId: user?.tenantId,
        method: request.method,
        path,
        statusCode: response.statusCode,
        success: response.statusCode < 400,
        ip: clientIp(request),
        userAgent: request.headers['user-agent'],
        durationMs: Date.now() - startedAt,
        metadata: { requestId },
      };
      this.audit.logRequest(record);
      if (shouldPersist(request.method, path, response.statusCode)) {
        void this.audit.record(record);
      }
    });

    next();
  }
}

function shouldPersist(method: string, path: string, statusCode: number) {
  if (path.endsWith('/health')) return false;
  if (
    path.endsWith('/auth/login') ||
    path.endsWith('/auth/register') ||
    path.endsWith('/auth/logout') ||
    path.endsWith('/audit/client-event')
  ) {
    return false;
  }
  return (
    !['GET', 'HEAD', 'OPTIONS'].includes(method) ||
    statusCode >= 400 ||
    path.includes('/platform/admin')
  );
}

function requestAction(method: string, path: string): string {
  return `http.${method.toLowerCase()}.${resourceFromPath(path)}`;
}

function resourceFromPath(path: string): string {
  const parts = path.split('/').filter(Boolean);
  const apiIndex = parts.indexOf('api');
  return parts[apiIndex + 1] || parts[0] || 'root';
}
