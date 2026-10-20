import type { Env } from './env';
import {
  chatUsers,
  createDirectConversation,
  deleteMessage,
  editMessage,
  listConversations,
  listMessages,
  markMessagesRead,
  sendMessage,
  typing,
} from './chat-service';
import { badRequest } from './http';

export interface RealtimeSession {
  userId: string;
  tenantId: string;
  name: string;
  role: string;
  access: string[];
  isAdmin: boolean;
  conversationIds: string[];
}

export interface RealtimeBroadcast {
  event: string;
  data: unknown;
  conversationId?: string;
  exceptUserId?: string;
}

export interface RealtimeResult {
  data: unknown;
  message: string;
  broadcasts?: RealtimeBroadcast[];
  conversationId?: string;
}

export async function routeRealtimeEvent(
  env: Env,
  session: RealtimeSession,
  event: string,
  payload: unknown,
): Promise<RealtimeResult> {
  const data = (payload ?? {}) as Record<string, any>;

  switch (event) {
    case 'chat.users':
      return {
        data: await chatUsers(env, session),
        message: 'Requisição concluída.',
      };

    case 'chat.conversations':
      return listConversations(env, session, data);

    case 'chat.conversation.create':
      return createDirectConversation(env, session, {
        title: typeof data.title === 'string' ? data.title : undefined,
        participantIds: Array.isArray(data.participantIds)
          ? data.participantIds.filter((value: unknown): value is string => typeof value === 'string')
          : [],
      });

    case 'chat.messages': {
      if (typeof data.conversationId !== 'string' || !data.conversationId) {
        throw badRequest('conversationId é obrigatório');
      }
      return listMessages(env, session, data.conversationId, data);
    }

    case 'chat.message.send': {
      if (typeof data.conversationId !== 'string' || !data.conversationId) {
        throw badRequest('conversationId é obrigatório');
      }
      return sendMessage(env, session, data.conversationId, {
        text: typeof data.text === 'string' ? data.text : undefined,
        mediaUrl: typeof data.mediaUrl === 'string' ? data.mediaUrl : undefined,
        mediaType:
          data.mediaType === 'image' || data.mediaType === 'video' || data.mediaType === 'sticker'
            ? data.mediaType
            : undefined,
        senderName: typeof data.senderName === 'string' ? data.senderName : undefined,
        replyToMessageId:
          typeof data.replyToMessageId === 'string' ? data.replyToMessageId : undefined,
      });
    }

    case 'chat.message.edit': {
      if (typeof data.messageId !== 'string' || !data.messageId) {
        throw badRequest('messageId é obrigatório');
      }
      if (typeof data.text !== 'string') throw badRequest('text é obrigatório');
      return editMessage(env, session, data.messageId, data.text);
    }

    case 'chat.message.delete': {
      if (typeof data.messageId !== 'string' || !data.messageId) {
        throw badRequest('messageId é obrigatório');
      }
      return deleteMessage(env, session, data.messageId);
    }

    case 'chat.messages.read': {
      if (typeof data.conversationId !== 'string' || !data.conversationId) {
        throw badRequest('conversationId é obrigatório');
      }
      return markMessagesRead(env, session, data.conversationId);
    }

    case 'chat.typing': {
      if (typeof data.conversationId !== 'string' || !data.conversationId) {
        throw badRequest('conversationId é obrigatório');
      }
      return typing(env, session, {
        conversationId: data.conversationId,
        senderName: typeof data.senderName === 'string' ? data.senderName : undefined,
        isTyping: data.isTyping === true,
      });
    }

    default:
      throw badRequest(`Evento não suportado: ${event}`);
  }
}

export async function broadcastToTenant(
  env: Env,
  tenantId: string,
  event: string,
  data: unknown,
  conversationId?: string,
): Promise<void> {
  const stub = env.REALTIME.get(env.REALTIME.idFromName(tenantId));
  await stub.fetch('https://realtime.internal/broadcast', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ event, data, conversationId }),
  });
}
