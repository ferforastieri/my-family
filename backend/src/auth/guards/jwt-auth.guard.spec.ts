import { UnauthorizedException, type ExecutionContext } from '@nestjs/common';
import { JwtAuthGuard } from './jwt-auth.guard';

describe('JwtAuthGuard', () => {
  const createGuard = () => {
    const jwt = { verifyAsync: jest.fn() };
    const auth = { findAuthenticatedUser: jest.fn() };
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue(false) };
    const guard = new JwtAuthGuard(
      jwt as never,
      auth as never,
      reflector as never,
    );
    return { guard, jwt, auth, reflector };
  };

  it('permite uma rota marcada com @Public sem exigir token', async () => {
    const { guard, jwt, auth, reflector } = createGuard();
    reflector.getAllAndOverride.mockReturnValue(true);

    await expect(guard.canActivate(context({}))).resolves.toBe(true);
    expect(jwt.verifyAsync).not.toHaveBeenCalled();
    expect(auth.findAuthenticatedUser).not.toHaveBeenCalled();
  });

  it('valida o bearer token e adiciona o usuário à requisição', async () => {
    const { guard, jwt, auth } = createGuard();
    const request = { headers: { authorization: 'Bearer access-token' } };
    jwt.verifyAsync.mockResolvedValue({ sub: 'user-1', tenantId: 'tenant-1' });
    auth.findAuthenticatedUser.mockResolvedValue({
      id: 'user-1',
      tenantId: 'tenant-1',
    });

    await expect(guard.canActivate(context(request))).resolves.toBe(true);
    expect(auth.findAuthenticatedUser).toHaveBeenCalledWith(
      'user-1',
      'tenant-1',
    );
    expect((request as any).user.id).toBe('user-1');
  });

  it('rejeita refresh token em uma rota protegida', async () => {
    const { guard, jwt } = createGuard();
    jwt.verifyAsync.mockResolvedValue({
      sub: 'user-1',
      tenantId: 'tenant-1',
      type: 'refresh',
    });

    await expect(
      guard.canActivate(
        context({ headers: { authorization: 'Bearer refresh-token' } }),
      ),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('ignora contextos WebSocket, que possuem autenticação própria', async () => {
    const { guard, jwt } = createGuard();
    const wsContext = {
      getType: () => 'ws',
    } as unknown as ExecutionContext;

    await expect(guard.canActivate(wsContext)).resolves.toBe(true);
    expect(jwt.verifyAsync).not.toHaveBeenCalled();
  });
});

function context(request: object): ExecutionContext {
  return {
    getType: () => 'http',
    getHandler: () => function handler() {},
    getClass: () => class Controller {},
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}
