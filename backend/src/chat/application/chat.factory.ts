import type { Factory } from '@shared/application/mapper';
import type { ChatMessageWrite } from '../infrastructure/repositories/chat.repository';
import type {
  ChatConversationCreateDto,
  ChatMessageSendDto,
} from '../interfaces/dto/chat.dto';

export type ChatConversationWrite = {
  title: string;
  participantIds: string[];
  createdBy: string;
};

export class ChatConversationFactory implements Factory<
  ChatConversationCreateDto & { createdBy: string },
  ChatConversationWrite
> {
  create(
    input: ChatConversationCreateDto & { createdBy: string },
  ): ChatConversationWrite {
    return {
      title: input.title?.trim() || 'Conversa',
      participantIds: Array.from(new Set(input.participantIds ?? [])),
      createdBy: input.createdBy,
    };
  }
}

export class ChatMessageFactory implements Factory<
  ChatMessageSendDto & { senderId?: string | null; senderName: string },
  ChatMessageWrite
> {
  create(
    input: ChatMessageSendDto & {
      senderId?: string | null;
      senderName: string;
    },
  ): ChatMessageWrite {
    return {
      conversationId: input.conversationId,
      senderId: input.senderId ?? null,
      senderName: input.senderName,
      text: input.text?.trim(),
      mediaUrl: input.mediaUrl,
      mediaType: input.mediaType,
    };
  }
}

export const chatConversationFactory = new ChatConversationFactory();
export const chatMessageFactory = new ChatMessageFactory();
