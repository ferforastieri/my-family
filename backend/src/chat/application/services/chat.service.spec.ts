import { ForbiddenException } from '@nestjs/common';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { ChatService } from './chat.service';

describe('ChatService tenant boundaries', () => {
  it('rejects direct conversations containing a user outside the tenant', async () => {
    const chat = { createDirectConversation: jest.fn() };
    const currentUser = {
      id: 'member-a',
      tenantId: 'tenant-a',
    } as UserEntity;
    const users = {
      findOne: jest.fn((id: string) =>
        Promise.resolve(id === currentUser.id ? currentUser : null),
      ),
    };
    const service = new ChatService(
      chat as never,
      users as never,
      {} as never,
      {} as never,
      {} as never,
      {} as never,
    );

    await expect(
      service.createDirectConversation(currentUser, {
        participantIds: ['user-from-another-tenant'],
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(chat.createDirectConversation).not.toHaveBeenCalled();
  });
});
