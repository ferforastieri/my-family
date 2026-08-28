import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import type { ChatMessageEntity } from '@chat/domain/entities/chat.entity';
import type { PaginationQuery } from '@shared/infrastructure/database/mongo.utils';
import { ChatRepository } from '../../infrastructure/repositories/chat.repository';
import { ListsService } from '../../../lists/application/services/lists.service';
import { ListsRealtimeGateway } from '../../../lists/interfaces/gateways/lists-realtime.gateway';
import { FotosService } from '../../../fotos/application/services/fotos.service';
import { NotificationsService } from '../../../notifications/application/services/notifications.service';
import { TenancyService } from '@tenancy/application/tenancy.service';
import type { TenantPrincipal } from '@tenancy/domain/tenant.entity';
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
    private tenancy: TenancyService,
    private lists: ListsService,
    private listsRealtime: ListsRealtimeGateway,
    private fotos: FotosService,
    private notifications: NotificationsService,
  ) {}

  async usersForChat(currentUser: TenantPrincipal) {
    const members = await this.tenancy.members(currentUser.tenantId);
    return members
      .map(({ id, name, phoneNumber, role, avatarPath }) => ({
        id,
        name,
        phoneNumber,
        role,
        avatarPath,
      }))
      .filter((user) => user.id !== currentUser.id);
  }

  async listConversations(
    user?: TenantPrincipal | null,
    query?: PaginationQuery,
  ) {
    const result = await this.chat.listForUser(user?.id, query);
    const users = user ? await this.tenancy.members(user.tenantId) : [];
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
    currentUser: TenantPrincipal,
    body: ChatConversationCreateDto,
  ) {
    const ids = Array.from(
      new Set([currentUser.id, ...(body.participantIds ?? [])]),
    );
    if (ids.length < 2)
      throw new ForbiddenException('Escolha pelo menos uma pessoa.');
    const members = await this.tenancy.members(currentUser.tenantId);
    if (ids.some((id) => !members.some((member) => member.id === id))) {
      throw new ForbiddenException('Uma das pessoas não pertence à família.');
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
      ? members.find((member) => member.id === participantId)
      : null;
    return {
      ...chatConversationMapper.toDto(conversation),
      unreadCount: 0,
      title: this.chatUserLabel(participant) || conversation.title,
      avatarPath: participant?.avatarPath ?? null,
    };
  }

  private chatUserLabel(
    user?: { name?: string | null; phoneNumber?: string } | null,
  ) {
    const name = user?.name?.trim();
    if (name) return name;
    return user?.phoneNumber ?? '';
  }

  async listMessages(
    conversationId: string,
    user?: TenantPrincipal | null,
    query?: PaginationQuery,
  ) {
    await this.assertConversationAccess(conversationId, user);
    const page = await this.chat.listMessages(conversationId, query);
    const items = await this.withSenderAvatars(page.items, user?.tenantId);
    return {
      ...page,
      items: items.map((message) => chatMessageMapper.toDto(message)),
    };
  }

  async assertConversationAccess(
    conversationId: string,
    user?: TenantPrincipal | null,
  ) {
    const conversation = await this.chat.findConversation(conversationId);
    if (!conversation) throw new ForbiddenException('Conversa não encontrada.');
    if (
      conversation.type === 'direct' &&
      (!user || !conversation.participantIds.includes(user.id))
    ) {
      throw new ForbiddenException('Sem acesso a esta conversa.');
    }
    return conversation;
  }

  async sendMessage(
    conversationId: string,
    body: Omit<ChatMessageSendDto, 'conversationId'>,
    user?: TenantPrincipal | null,
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
      user?.name || user?.phoneNumber || body.senderName?.trim() || 'Visitante';
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
    const [messageWithAvatar] = await this.withSenderAvatars(
      [message],
      user?.tenantId,
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
    const recipients =
      conversation.type === 'direct'
        ? conversation.participantIds
        : await this.chatNotificationRecipients(user?.tenantId);
    const delivery = await this.notifications.sendChatMessage({
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
    const delivered = await this.chat.markMessageDelivered(
      message.id,
      delivery.deliveredUserIds,
    );
    const [messageWithDelivery] = await this.withSenderAvatars(
      [delivered ?? message],
      user?.tenantId,
    );
    return chatMessageMapper.toDto(messageWithDelivery);
  }

  private async withSenderAvatars(
    messages: ChatMessageEntity[],
    tenantId?: string | null,
  ) {
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
    if (userIds.length === 0 || !tenantId) return messages;
    const members = await this.tenancy.members(tenantId);
    const avatars = new Map(
      members
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

  private async chatNotificationRecipients(tenantId?: string | null) {
    if (!tenantId) return [];
    const members = await this.tenancy.members(tenantId);
    return members
      .filter(
        (candidate) =>
          candidate.membershipRole === 'owner' ||
          candidate.membershipRole === 'admin' ||
          candidate.access.includes('chat'),
      )
      .map((candidate) => candidate.id);
  }

  async editMessage(body: ChatMessageEditDto, user: TenantPrincipal) {
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

  async deleteMessage(messageId: string, user: TenantPrincipal) {
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

  async markMessagesRead(conversationId: string, user: TenantPrincipal) {
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
