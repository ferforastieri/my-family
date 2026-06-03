import { ForbiddenException, Injectable } from '@nestjs/common';
import { UserService } from '@auth/application/user.service';
import type { UserEntity } from '@shared/domain/entities';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { ChatRepository } from '../infrastructure/repositories/chat.repository';
import { ListsService } from '../../lists/application/lists.service';
import { ListsRealtimeGateway } from '../../lists/interfaces/gateways/lists-realtime.gateway';

@Injectable()
export class ChatService {
  constructor(
    private chat: ChatRepository,
    private users: UserService,
    private lists: ListsService,
    private listsRealtime: ListsRealtimeGateway,
  ) {}

  private messageDto(message: Awaited<ReturnType<ChatRepository['createMessage']>>) {
    return {
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      senderName: message.senderName,
      text: message.text,
      mediaUrl: message.mediaUrl,
      mediaType: message.mediaType,
      at: new Date(message.createdAt).getTime(),
    };
  }

  async usersForChat(currentUser: UserEntity) {
    const page = await this.users.list({ page: 1, limit: 100 });
    return page.items.map(({ id, name, email, role }) => ({ id, name, email, role })).filter((user) => user.id !== currentUser.id);
  }

  async listConversations(user?: UserEntity | null, query?: PaginationQuery) {
    return this.chat.listForUser(user?.id, query);
  }

  async createDirectConversation(currentUser: UserEntity, body: { title?: string; participantIds: string[] }) {
    const ids = Array.from(new Set([currentUser.id, ...(body.participantIds ?? [])]));
    if (ids.length < 2) throw new ForbiddenException('Escolha pelo menos uma pessoa.');
    return this.chat.createDirectConversation({
      title: body.title?.trim() || 'Conversa',
      participantIds: ids,
      createdBy: currentUser.id,
    });
  }

  async listMessages(conversationId: string, user?: UserEntity | null, query?: PaginationQuery) {
    const conversation = await this.chat.findConversation(conversationId);
    if (!conversation) return [];
    if (conversation.type === 'direct' && (!user || !conversation.participantIds.includes(user.id))) {
      throw new ForbiddenException('Sem acesso a esta conversa.');
    }
    const page = await this.chat.listMessages(conversationId, query);
    return { ...page, items: page.items.map((message) => this.messageDto(message)) };
  }

  async sendMessage(
    conversationId: string,
    body: { text?: string; mediaUrl?: string; mediaType?: 'image' | 'video'; senderName?: string },
    user?: UserEntity | null,
  ) {
    const conversation = await this.chat.findConversation(conversationId);
    if (!conversation) throw new ForbiddenException('Conversa não encontrada.');
    if (conversation.type === 'direct' && (!user || !conversation.participantIds.includes(user.id))) {
      throw new ForbiddenException('Sem acesso a esta conversa.');
    }
    const senderName = user?.name || user?.email || body.senderName?.trim() || 'Visitante';
    const message = await this.chat.createMessage({
      conversationId,
      senderId: user?.id ?? null,
      senderName,
      text: body.text?.trim(),
      mediaUrl: body.mediaUrl,
      mediaType: body.mediaType,
    });
    if (body.text?.trim()) {
      const listResult = await this.lists.addFromChat(body.text, user);
      if (listResult) {
        this.listsRealtime.emitListCreated(listResult.list);
        for (const item of listResult.items) this.listsRealtime.emitItemCreated(item);
      }
    }
    return this.messageDto(message);
  }
}
