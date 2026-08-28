import { ForbiddenException } from '@nestjs/common';
import type { Socket } from 'socket.io';
import type { WsSessionService } from '@auth/application/services/ws-session.service';
import type { TenantPrincipal } from '@tenancy/domain/tenant.entity';
import type { ChatService } from '../../application/services/chat.service';
import { ChatGateway } from './chat.gateway';

describe('ChatGateway conversation rooms', () => {
  const user = {
    id: 'user-a',
    tenantId: 'tenant-a',
    access: ['chat'],
  } as TenantPrincipal;

  it('does not join a room when conversation access is denied', async () => {
    const chat = {
      listMessages: jest
        .fn()
        .mockRejectedValue(new ForbiddenException('Sem acesso.')),
    };
    const session = { requireAccess: jest.fn().mockResolvedValue(user) };
    const client = { join: jest.fn() };
    const gateway = new ChatGateway(
      chat as unknown as ChatService,
      session as unknown as WsSessionService,
    );

    await expect(
      gateway.messages(client as unknown as Socket, {
        conversationId: 'conversation-b',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(client.join).not.toHaveBeenCalled();
  });

  it('validates conversation access before broadcasting typing state', async () => {
    const chat = {
      assertConversationAccess: jest
        .fn()
        .mockRejectedValue(new ForbiddenException('Sem acesso.')),
    };
    const session = { requireAccess: jest.fn().mockResolvedValue(user) };
    const client = { to: jest.fn() };
    const gateway = new ChatGateway(
      chat as unknown as ChatService,
      session as unknown as WsSessionService,
    );

    await expect(
      gateway.typing(client as unknown as Socket, {
        conversationId: 'conversation-b',
        isTyping: true,
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(client.to).not.toHaveBeenCalled();
  });
});
