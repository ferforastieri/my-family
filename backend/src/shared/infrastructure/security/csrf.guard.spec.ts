import { ForbiddenException, type ExecutionContext } from '@nestjs/common';
import { CsrfGuard } from './csrf.guard';

function context(
  method: string,
  path: string,
  cookie?: string,
  token?: string,
) {
  return {
    getType: () => 'http',
    switchToHttp: () => ({
      getRequest: () => ({
        method,
        path,
        headers: {
          ...(cookie ? { cookie: `fmf_csrf=${cookie}` } : {}),
          ...(token ? { 'x-csrf-token': token } : {}),
        },
      }),
    }),
  } as unknown as ExecutionContext;
}

describe('CsrfGuard', () => {
  const guard = new CsrfGuard();

  it('allows safe methods and matching double-submit tokens', () => {
    expect(guard.canActivate(context('GET', '/api/tenant'))).toBe(true);
    expect(
      guard.canActivate(context('PATCH', '/api/tenant', 'same', 'same')),
    ).toBe(true);
  });

  it('rejects a cookie-authenticated mutation without a matching token', () => {
    expect(() =>
      guard.canActivate(context('POST', '/api/tenant', 'cookie', 'different')),
    ).toThrow(ForbiddenException);
    expect(() => guard.canActivate(context('DELETE', '/api/tenant'))).toThrow(
      ForbiddenException,
    );
  });

  it('exempts only public OTP posts', () => {
    expect(
      guard.canActivate(context('POST', '/api/auth/phone/request-code')),
    ).toBe(true);
  });
});
