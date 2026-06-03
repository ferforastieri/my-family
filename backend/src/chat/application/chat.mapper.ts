import type { Mapper } from '@shared/application/mapper';
import type {
  ChatConversationEntity,
  ChatMessageEntity,
} from '@shared/domain/entities';
import {
  ChatConversationResponseDto,
  ChatMessageResponseDto,
} from '../interfaces/dto/chat.dto';

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
      at: new Date(source.createdAt).getTime(),
    };
  }
}

export const chatConversationMapper = new ChatConversationMapper();
export const chatMessageMapper = new ChatMessageMapper();
