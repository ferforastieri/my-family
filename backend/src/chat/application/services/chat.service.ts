import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { UserService } from '@auth/application/services/user.service';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import type { ChatMessageEntity } from '@chat/domain/entities/chat.entity';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { ChatRepository } from '../../infrastructure/repositories/chat.repository';
import { ListsService } from '../../../lists/application/services/lists.service';
import { ListsRealtimeGateway } from '../../../lists/interfaces/gateways/lists-realtime.gateway';
import { FotosService } from '../../../fotos/application/services/fotos.service';
import { NotificationsService } from '../../../notifications/application/services/notifications.service';
import { isAdminRole } from '@auth/domain/entities/user.entity';
import {
  chatConversationFactory,
  chatMessageFactory,
} from '../factories/chat.factory';
import {
  chatConversationMapper,
  chatMessageMapper,
} from '../mappers/chat.mapper';
import type {
  ChatConversationCreateDto,
  ChatMessageEditDto,
  ChatMessageSendDto,
} from '../../interfaces/dto/chat.dto';

@Injectable()
export class ChatService {
  constructor(
    private chat: ChatRepository,
    private users: UserService,
    private lists: ListsService,
    private listsRealtime: ListsRealtimeGateway,
    private fotos: FotosService,
    private notifications: NotificationsService,
  ) {}

  async usersForChat(currentUser: UserEntity) {
    const page = await this.users.list({ page: 1, limit: 100 });
    return page.items
      .map(({ id, name, email, role, avatarPath }) => ({
        id,
        name,
        email,
        role,
        avatarPath,
      }))
      .filter((user) => user.id !== currentUser.id);
  }

  async listConversations(user?: UserEntity | null, query?: PaginationQuery) {
    const result = await this.chat.listForUser(user?.id, query);
    const users = user
      ? (await this.users.list({ page: 1, limit: 100 })).items
      : [];
    const unreadCounts = user
      ? await this.chat.unreadCountsForUser(
          user.id,
          result.items.map((item) => item.id),
        )
      : new Map<string, number>();
    return {
      ...result,
      items: result.items.map((item) => {
        const participant =
          item.type === 'direct'
            ? users.find(
                (candidate) =>
                  candidate.id !== user?.id &&
                  item.participantIds.includes(candidate.id),
              )
            : null;
        return {
          ...chatConversationMapper.toDto(item),
          unreadCount: unreadCounts.get(item.id) ?? 0,
          title:
            item.type === 'direct'
              ? this.chatUserLabel(participant) || item.title
              : item.title,
          avatarPath: participant?.avatarPath ?? null,
        };
      }),
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
    const participants = await Promise.all(
      ids.map((id) => this.users.findOne(id)),
    );
    if (participants.some((participant) => !participant)) {
      throw new ForbiddenException(
        'Todos os participantes devem pertencer à família atual.',
      );
    }
    const conversation = await this.chat.createDirectConversation(
      chatConversationFactory.create({
        ...body,
        participantIds: ids,
        createdBy: currentUser.id,
      }),
    );
    const participantId = ids.find((id) => id !== currentUser.id);
    const participant = participantId
      ? await this.users.findOne(participantId)
      : null;
    return {
      ...chatConversationMapper.toDto(conversation),
      unreadCount: 0,
      title: this.chatUserLabel(participant) || conversation.title,
      avatarPath: participant?.avatarPath ?? null,
    };
  }

  private chatUserLabel(
    user?: { name?: string | null; email?: string } | null,
  ) {
    const name = user?.name?.trim();
    if (name) return name;
    return user?.email ?? '';
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
    const items = await this.withSenderAvatars(page.items);
    return {
      ...page,
      items: items.map((message) => chatMessageMapper.toDto(message)),
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
    if (!body.text?.trim() && !body.mediaUrl) {
      throw new BadRequestException('Escreva uma mensagem.');
    }
    if (body.replyToMessageId) {
      const replyTo = await this.chat.findMessage(body.replyToMessageId);
      if (!replyTo || replyTo.conversationId !== conversationId) {
        throw new BadRequestException('Mensagem respondida inválida.');
      }
    }
    const message = await this.chat.createMessage(
      chatMessageFactory.create({
        conversationId,
        senderId: user?.id ?? null,
        senderName,
        text: body.text?.trim(),
        mediaUrl: body.mediaUrl,
        mediaType: body.mediaType,
        replyToMessageId: body.replyToMessageId,
      }),
    );
    const [messageWithAvatar] = await this.withSenderAvatars([message]);
    if (body.text?.trim()) {
      const listResult = await this.lists.addFromChat(body.text, user);
      if (listResult) {
        this.listsRealtime.emitListCreated(listResult.list);
        for (const item of listResult.items)
          this.listsRealtime.emitItemCreated(item);
      }
    }
    if (body.mediaUrl?.startsWith(`tenants/${currentTenantId(user)}/fotos/`)) {
      await this.fotos.ensureFromChat({
        url: body.mediaUrl,
        tipo: body.mediaType === 'video' ? 'video' : 'imagem',
        album: 'Chat',
        texto: body.text?.trim() || `Enviado por ${senderName}`,
        data: new Date(),
      });
      await this.fotos.processUpload(body.mediaUrl);
    }
    const recipients =
      conversation.type === 'direct'
        ? conversation.participantIds
        : await this.chatNotificationRecipients();
    await this.notifications.sendChatMessage({
      conversationId: conversation.id,
      conversationTitle:
        conversation.type === 'global' ? 'Chat da família' : conversation.title,
      conversationType: conversation.type,
      senderId: user?.id ?? '',
      senderName,
      recipientUserIds: recipients,
      text: messageWithAvatar.text,
      mediaType: messageWithAvatar.mediaType,
    });
    return chatMessageMapper.toDto(messageWithAvatar);
  }

  private async withSenderAvatars(messages: ChatMessageEntity[]) {
    const userIds = [
      ...new Set(
        messages
          .flatMap((message) => [
            message.senderId,
            message.replyToMessage?.senderId,
          ])
          .filter(
            (id): id is string => typeof id === 'string' && id.length > 0,
          ),
      ),
    ];
    if (userIds.length === 0) return messages;
    const page = await this.users.list({ page: 1, limit: 100 });
    const avatars = new Map(
      page.items
        .filter((user) => userIds.includes(user.id))
        .map((user) => [user.id, user.avatarPath ?? null]),
    );
    return messages.map((message) => ({
      ...message,
      senderAvatarPath: message.senderId
        ? (avatars.get(message.senderId) ?? null)
        : null,
      replyToMessage: message.replyToMessage
        ? {
            ...message.replyToMessage,
            senderAvatarPath: message.replyToMessage.senderId
              ? (avatars.get(message.replyToMessage.senderId) ?? null)
              : null,
          }
        : message.replyToMessage,
    }));
  }

  private async chatNotificationRecipients() {
    const page = await this.users.list({ page: 1, limit: 100 });
    return page.items
      .filter(
        (candidate) =>
          isAdminRole(candidate.role) || candidate.access.includes('chat'),
      )
      .map((candidate) => candidate.id);
  }

  async editMessage(body: ChatMessageEditDto, user: UserEntity) {
    const message = await this.chat.findMessage(body.messageId);
    if (!message) throw new ForbiddenException('Mensagem não encontrada.');
    if (message.senderId !== user.id) {
      throw new ForbiddenException('Você só pode editar suas mensagens.');
    }
    if (message.deletedAt) {
      throw new BadRequestException('Esta mensagem foi apagada.');
    }
    const text = body.text.trim();
    if (!text) throw new BadRequestException('Escreva uma mensagem.');
    const updated = await this.chat.editMessage(message.id, text);
    if (!updated) throw new ForbiddenException('Mensagem não encontrada.');
    return chatMessageMapper.toDto(updated);
  }

  async deleteMessage(messageId: string, user: UserEntity) {
    const message = await this.chat.findMessage(messageId);
    if (!message) throw new ForbiddenException('Mensagem não encontrada.');
    if (message.senderId !== user.id) {
      throw new ForbiddenException('Você só pode apagar suas mensagens.');
    }
    if (message.deletedAt) return chatMessageMapper.toDto(message);
    const deleted = await this.chat.deleteMessage(message.id);
    if (!deleted) throw new ForbiddenException('Mensagem não encontrada.');
    return chatMessageMapper.toDto(deleted);
  }

  async markMessagesRead(conversationId: string, user: UserEntity) {
    const conversation = await this.chat.findConversation(conversationId);
    if (!conversation) throw new ForbiddenException('Conversa não encontrada.');
    if (
      conversation.type === 'direct' &&
      !conversation.participantIds.includes(user.id)
    ) {
      throw new ForbiddenException('Sem acesso a esta conversa.');
    }
    await this.chat.markMessagesRead(conversationId, user.id);
    return { conversationId, userId: user.id };
  }
}

function currentTenantId(user?: UserEntity | null): string {
  if (!user?.tenantId) {
    throw new ForbiddenException('Contexto da família não selecionado.');
  }
  return user.tenantId;
}
