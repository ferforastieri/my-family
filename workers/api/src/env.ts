export type JobMessage =
  | { type: 'notification.send'; tenantId: string; title: string; body?: string; url?: string; excludeUserIds?: string[] }
  | { type: 'notification.scheduled'; tenantId: string; scheduledNotificationId: string }
  | { type: 'session.cleanup' }
  | { type: 'demo.cleanup' };

export interface Env {
  DB: D1Database;
  MEDIA: R2Bucket;
  JOBS: Queue<JobMessage>;
  REALTIME: DurableObjectNamespace;
  RATE_LIMITER: DurableObjectNamespace;

  APP_ENV?: string;
  JWT_SECRET: string;
  TURNSTILE_SECRET?: string;
  CORS_ORIGIN: string;
  COOKIE_SECURE?: string;
  COOKIE_SAME_SITE?: string;
  PLATFORM_ADMIN_EMAIL?: string;
  INVITATION_URL?: string;

  VAPID_PUBLIC_KEY?: string;
  VAPID_PRIVATE_KEY?: string;
  VAPID_SUBJECT?: string;

  MEDIA_BASE_URL?: string;
  MEDIA_SIGNING_SECRET?: string;
  FIREBASE_SERVICE_ACCOUNT_JSON?: string;

  THROTTLE_TTL_MS?: string;
  THROTTLE_LIMIT?: string;
}

export type AppEnv = {
  Bindings: Env;
  Variables: {
    principal: import('./auth').Principal;
    requestId: string;
  };
};

export function isProduction(env: Env): boolean {
  return (env.APP_ENV ?? 'production') === 'production';
}

export function corsOrigins(env: Env): string[] {
  return (env.CORS_ORIGIN ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
}
