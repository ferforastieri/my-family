import { ForbiddenException, Injectable } from '@nestjs/common';
import { UserService } from '@auth/application/user.service';
import type { UserEntity } from '@shared/domain/entities';
import { ChatRepository } from '../infrastructure/repositories/chat.repository';

@Injectable()
export class ChatService {
  constructor(
    private chat: ChatRepository,
    private users: UserService,
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
    return (await this.users.list()).map(({ id, name, email, role }) => ({ id, name, email, role })).filter((user) => user.id !== currentUser.id);
  }

  async listConversations(user?: UserEntity | null) {
    return this.chat.listForUser(user?.id);
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

  async listMessages(conversationId: string, user?: UserEntity | null) {
    const conversation = await this.chat.findConversation(conversationId);
    if (!conversation) return [];
    if (conversation.type === 'direct' && (!user || !conversation.participantIds.includes(user.id))) {
      throw new ForbiddenException('Sem acesso a esta conversa.');
    }
    return (await this.chat.listMessages(conversationId)).map((message) => this.messageDto(message));
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
    return this.messageDto(message);
  }
}
