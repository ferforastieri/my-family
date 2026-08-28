import type { ExecutionContext } from '@nestjs/common';
import type { ThrottlerOptions } from '@nestjs/throttler';
import type { Environment } from '../environment/environment.module';

const OTP_REQUEST_PATH = '/auth/phone/request-code';
const OTP_VERIFY_PATH = '/auth/phone/verify-code';
const DEMO_PATH = '/public/demo-sessions';

export function buildRateLimiters(
  environment: Environment,
): ThrottlerOptions[] {
  return [
    {
      name: 'default',
      ttl: environment.security.throttleTtlMs,
      limit: environment.security.throttleLimit,
    },
    {
      name: 'otp-ip',
      ttl: 10 * 60 * 1000,
      limit: 10,
      blockDuration: 10 * 60 * 1000,
      skipIf: (context) => requestPath(context) !== OTP_REQUEST_PATH,
    },
    {
      name: 'otp-phone',
      ttl: 10 * 60 * 1000,
      limit: 5,
      blockDuration: 10 * 60 * 1000,
      skipIf: (context) => requestPath(context) !== OTP_REQUEST_PATH,
      getTracker: (request) => phoneTracker(request, environment),
    },
    {
      name: 'verify-ip',
      ttl: 10 * 60 * 1000,
      limit: 30,
      blockDuration: 10 * 60 * 1000,
      skipIf: (context) => requestPath(context) !== OTP_VERIFY_PATH,
    },
    {
      name: 'verify-phone',
      ttl: 10 * 60 * 1000,
      limit: 10,
      blockDuration: 10 * 60 * 1000,
      skipIf: (context) => requestPath(context) !== OTP_VERIFY_PATH,
      getTracker: (request) => phoneTracker(request, environment),
    },
    {
      name: 'demo-ip',
      ttl: 60 * 60 * 1000,
      limit: 3,
      blockDuration: 60 * 60 * 1000,
      skipIf: (context) => requestPath(context) !== DEMO_PATH,
    },
  ];
}

export function requestPath(context: ExecutionContext): string {
  const request = context.switchToHttp().getRequest<{ path?: string }>();
  const path = request.path ?? '';
  return path.startsWith('/api/') ? path.substring(4) : path;
}

export function phoneTracker(
  request: Record<string, any>,
  environment: Environment,
): string {
  const raw = typeof request.body?.phone === 'string' ? request.body.phone : '';
  let digits = raw.replace(/\D/g, '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (
    !raw.trim().startsWith('+') &&
    (digits.length === 10 || digits.length === 11)
  ) {
    digits = `${environment.phoneAuth.defaultCountryCode}${digits}`;
  }
  return digits || `invalid:${String(request.ip ?? 'unknown')}`;
}
