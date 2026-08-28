import type { ExecutionContext } from '@nestjs/common';
import { Environment } from '../environment/environment.module';
import {
  buildRateLimiters,
  phoneTracker,
  requestPath,
} from './rate-limit.config';

describe('rate limit configuration', () => {
  const environment = new Environment({
    phoneAuth: { hashSecret: 'test', defaultCountryCode: '55' },
    security: { throttleTtlMs: 60_000, throttleLimit: 120, trustProxyHops: 2 },
  });

  const contextFor = (path: string) =>
    ({
      switchToHttp: () => ({ getRequest: () => ({ path }) }),
    }) as ExecutionContext;

  it('normalizes the route even when the global prefix is present', () => {
    expect(requestPath(contextFor('/api/auth/phone/request-code'))).toBe(
      '/auth/phone/request-code',
    );
  });

  it('uses a canonical phone tracker to prevent formatting bypasses', () => {
    expect(
      phoneTracker(
        { body: { phone: '(11) 99999-9999' }, ip: '127.0.0.1' },
        environment,
      ),
    ).toBe('5511999999999');
    expect(
      phoneTracker(
        { body: { phone: '+55 11 99999-9999' }, ip: '127.0.0.1' },
        environment,
      ),
    ).toBe('5511999999999');
  });

  it('applies independent limits to OTP by IP and phone and to demo creation', () => {
    const limits = buildRateLimiters(environment);
    expect(limits.find((item) => item.name === 'otp-ip')).toMatchObject({
      limit: 10,
    });
    expect(limits.find((item) => item.name === 'otp-phone')).toMatchObject({
      limit: 5,
    });
    expect(limits.find((item) => item.name === 'verify-phone')).toMatchObject({
      limit: 10,
    });
    expect(limits.find((item) => item.name === 'demo-ip')).toMatchObject({
      limit: 3,
    });
  });
});
