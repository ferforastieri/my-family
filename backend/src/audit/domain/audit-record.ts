export type AuditSource = 'http' | 'websocket' | 'system';

export type AuditRecord = {
  action: string;
  resource: string;
  source: AuditSource;
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
  metadata?: Record<string, unknown>;
};
