import type { Mapper } from '@shared/application/mapper';
import type {
  ChatConversationEntity,
  ChatMessageEntity,
} from '@chat/domain/entities/chat.entity';
import {
  ChatConversationResponseDto,
  ChatMessageResponseDto,
} from '../../interfaces/dto/chat.dto';

export class ChatConversationMapper implements Mapper<
  ChatConversationEntity,
  ChatConversationResponseDto
> {
  toDto(source: ChatConversationEntity): ChatConversationResponseDto {
    return {
      id: source.id,
      type: source.type,
      title: source.title,
      participantIds: source.participantIds,
      unreadCount: 0,
      avatarPath: null,
      createdBy: source.createdBy ?? null,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    };
  }
}

export class ChatMessageMapper implements Mapper<
  ChatMessageEntity,
  ChatMessageResponseDto
> {
  toDto(source: ChatMessageEntity): ChatMessageResponseDto {
    return {
      id: source.id,
      conversationId: source.conversationId,
      senderId: source.senderId ?? null,
      senderName: source.senderName,
      text: source.text ?? null,
      mediaUrl: source.mediaUrl ?? null,
      mediaType: source.mediaType ?? null,
      replyToMessageId: source.replyToMessageId ?? null,
      replyToMessage: source.replyToMessage
        ? {
            id: source.replyToMessage.id,
            senderId: source.replyToMessage.senderId ?? null,
            senderName: source.replyToMessage.senderName,
            text: source.replyToMessage.text ?? null,
            mediaUrl: source.replyToMessage.mediaUrl ?? null,
            mediaType: source.replyToMessage.mediaType ?? null,
          }
        : null,
      readBy: source.readBy,
      editedAt: source.editedAt ? new Date(source.editedAt).getTime() : null,
      deletedAt: source.deletedAt ? new Date(source.deletedAt).getTime() : null,
      at: new Date(source.createdAt).getTime(),
    };
  }
}

export const chatConversationMapper = new ChatConversationMapper();
export const chatMessageMapper = new ChatMessageMapper();
