import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import {
  InjectThrottlerStorage,
  type ThrottlerStorage,
} from '@nestjs/throttler';
import { WsException } from '@nestjs/websockets';
import { createHash } from 'node:crypto';
import type { Socket } from 'socket.io';
import { ACCESS_COOKIE, cookieValue } from './auth-cookies';

@Injectable()
export class WsRateLimitGuard implements CanActivate {
  constructor(
    @InjectThrottlerStorage() private readonly storage: ThrottlerStorage,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const client = context.switchToWs().getClient<Socket>();
    const tracker = this.tracker(client);
    const result = await this.storage.increment(
      `ws:${tracker}`,
      10_000,
      60,
      30_000,
      'ws-events',
    );
    if (result.isBlocked) {
      throw new WsException(
        'Muitas mensagens em pouco tempo. Aguarde antes de continuar.',
      );
    }
    return true;
  }

  private tracker(client: Socket): string {
    const token = cookieValue(client.handshake, ACCESS_COOKIE) ?? '';
    const source = token || client.handshake.address || client.id;
    return createHash('sha256').update(source).digest('hex');
  }
}
