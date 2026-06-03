import { ForbiddenException, Injectable } from '@nestjs/common';
import { UserService } from '@auth/application/user.service';
import type { UserEntity } from '@shared/domain/entities';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { ChatRepository } from '../infrastructure/repositories/chat.repository';
import { ListsService } from '../../lists/application/lists.service';
import { ListsRealtimeGateway } from '../../lists/interfaces/gateways/lists-realtime.gateway';
import { FotosService } from '../../fotos/application/fotos.service';
import { chatConversationFactory, chatMessageFactory } from './chat.factory';
import { chatConversationMapper, chatMessageMapper } from './chat.mapper';
import type {
  ChatConversationCreateDto,
  ChatMessageSendDto,
} from '../interfaces/dto/chat.dto';

@Injectable()
export class ChatService {
  constructor(
    private chat: ChatRepository,
    private users: UserService,
    private lists: ListsService,
    private listsRealtime: ListsRealtimeGateway,
    private fotos: FotosService,
  ) {}

  async usersForChat(currentUser: UserEntity) {
    const page = await this.users.list({ page: 1, limit: 100 });
    return page.items
      .map(({ id, name, email, role }) => ({ id, name, email, role }))
      .filter((user) => user.id !== currentUser.id);
  }

  async listConversations(user?: UserEntity | null, query?: PaginationQuery) {
    const result = await this.chat.listForUser(user?.id, query);
    return {
      ...result,
      items: result.items.map((item) => chatConversationMapper.toDto(item)),
    };
  }

  async createDirectConversation(
    currentUser: UserEntity,
    body: ChatConversationCreateDto,
  ) {
    const ids = Array.from(
      new Set([currentUser.id, ...(body.participantIds ?? [])]),
    );
    if (ids.length < 2)
      throw new ForbiddenException('Escolha pelo menos uma pessoa.');
    return chatConversationMapper.toDto(
      await this.chat.createDirectConversation(
        chatConversationFactory.create({
          ...body,
          participantIds: ids,
          createdBy: currentUser.id,
        }),
      ),
    );
  }

  async listMessages(
    conversationId: string,
    user?: UserEntity | null,
    query?: PaginationQuery,
  ) {
    const conversation = await this.chat.findConversation(conversationId);
    if (!conversation) return [];
    if (
      conversation.type === 'direct' &&
      (!user || !conversation.participantIds.includes(user.id))
    ) {
      throw new ForbiddenException('Sem acesso a esta conversa.');
    }
    const page = await this.chat.listMessages(conversationId, query);
    return {
      ...page,
      items: page.items.map((message) => chatMessageMapper.toDto(message)),
    };
  }

  async sendMessage(
    conversationId: string,
    body: Omit<ChatMessageSendDto, 'conversationId'>,
    user?: UserEntity | null,
  ) {
    const conversation = await this.chat.findConversation(conversationId);
    if (!conversation) throw new ForbiddenException('Conversa não encontrada.');
    if (
      conversation.type === 'direct' &&
      (!user || !conversation.participantIds.includes(user.id))
    ) {
      throw new ForbiddenException('Sem acesso a esta conversa.');
    }
    const senderName =
      user?.name || user?.email || body.senderName?.trim() || 'Visitante';
    const message = await this.chat.createMessage(
      chatMessageFactory.create({
        conversationId,
        senderId: user?.id ?? null,
        senderName,
        text: body.text?.trim(),
        mediaUrl: body.mediaUrl,
        mediaType: body.mediaType,
      }),
    );
    if (body.text?.trim()) {
      const listResult = await this.lists.addFromChat(body.text, user);
      if (listResult) {
        this.listsRealtime.emitListCreated(listResult.list);
        for (const item of listResult.items)
          this.listsRealtime.emitItemCreated(item);
      }
    }
    if (body.mediaUrl?.startsWith('fotos/')) {
      await this.fotos.ensureFromChat({
        url: body.mediaUrl,
        tipo: body.mediaType === 'video' ? 'video' : 'imagem',
        album: 'Chat',
        texto: body.text?.trim() || `Enviado por ${senderName}`,
        data: new Date(),
      });
      await this.fotos.processUpload(body.mediaUrl);
    }
    return chatMessageMapper.toDto(message);
  }
}
