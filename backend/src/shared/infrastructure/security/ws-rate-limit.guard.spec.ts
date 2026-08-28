import type { ExecutionContext } from '@nestjs/common';
import { WsException } from '@nestjs/websockets';
import { WsRateLimitGuard } from './ws-rate-limit.guard';

describe('WsRateLimitGuard', () => {
  const context = {
    switchToWs: () => ({
      getClient: () => ({
        id: 'socket-1',
        handshake: {
          auth: { token: 'secret-token' },
          headers: {},
          address: '::1',
        },
      }),
    }),
  } as unknown as ExecutionContext;

  it('allows events below the limit', async () => {
    const storage = {
      increment: jest.fn().mockResolvedValue({ isBlocked: false }),
    };
    await expect(
      new WsRateLimitGuard(storage as never).canActivate(context),
    ).resolves.toBe(true);
    expect(storage.increment).toHaveBeenCalledWith(
      expect.stringMatching(/^ws:[a-f0-9]{64}$/),
      10_000,
      60,
      30_000,
      'ws-events',
    );
  });

  it('rejects floods', async () => {
    const storage = {
      increment: jest.fn().mockResolvedValue({ isBlocked: true }),
    };
    await expect(
      new WsRateLimitGuard(storage as never).canActivate(context),
    ).rejects.toBeInstanceOf(WsException);
  });
});
