import type { Env } from './env';
import { execute, iso, jsonArray, now, queryAll, queryOne } from './db';
import type { RealtimeBroadcast, RealtimeSession } from './realtime-service';
import { forbidden, badRequest } from './http';
import { members } from './tenants';
import { sendPushToUsers } from './push';

export interface ConversationRow {
  id: string;
  type: string;
  title: string;
  participant_ids: string;
  created_by: string | null;
  created_at: number;
  updated_at: number;
}

export interface MessageRow {
  id: string;
  conversation_id: string;
  sender_id: string | null;
  sender_name: string;
  text: string | null;
  media_url: string | null;
  media_type: string | null;
  reply_to_message_id: string | null;
  read_by: string;
  delivered_by: string;
  edited_at: number | null;
  deleted_at: number | null;
  created_at: number;
}

export interface ChatResult<T> {
  data: T;
  message: string;
  broadcasts?: RealtimeBroadcast[];
  conversationId?: string;
}

export function conversationDto(row: ConversationRow, extra: {
  unreadCount?: number;
  title?: string;
  avatarPath?: string | null;
} = {}) {
  return {
    id: row.id,
    type: row.type,
    title: extra.title ?? row.title,
    participantIds: jsonArray(row.participant_ids),
    unreadCount: extra.unreadCount ?? 0,
    avatarPath: extra.avatarPath ?? null,
    createdBy: row.created_by,
    createdAt: iso(row.created_at),
    updatedAt: iso(row.updated_at),
  };
}

export function messageDto(
  row: MessageRow,
  extra: {
    senderAvatarPath?: string | null;
    replyToMessage?: Record<string, unknown> | null;
  } = {},
) {
  return {
    id: row.id,
    conversationId: row.conversation_id,
    senderId: row.sender_id,
    senderName: row.sender_name,
    senderAvatarPath: extra.senderAvatarPath ?? null,
    text: row.text,
    mediaUrl: row.media_url,
    mediaType: row.media_type,
    replyToMessageId: row.reply_to_message_id,
    replyToMessage: extra.replyToMessage ?? null,
    readBy: jsonArray(row.read_by),
    deliveredBy: jsonArray(row.delivered_by),
    editedAt: row.edited_at,
    deletedAt: row.deleted_at,
    at: row.created_at,
  };
}

async function getGlobalConversation(env: Env, tenantId: string): Promise<ConversationRow> {
  const existing = await queryOne<ConversationRow>(
    env.DB,
    `SELECT * FROM chat_conversations WHERE tenant_id = ? AND type = 'global' LIMIT 1`,
    [tenantId],
  );
  if (existing) return existing;
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    env.DB,
    `INSERT INTO chat_conversations (id, tenant_id, type, title, participant_ids, created_by, created_at, updated_at)
     VALUES (?, ?, 'global', 'Chat global', '[]', NULL, ?, ?)`,
    [id, tenantId, timestamp, timestamp],
  );
  return {
    id,
    type: 'global',
    title: 'Chat global',
    participant_ids: '[]',
    created_by: null,
    created_at: timestamp,
    updated_at: timestamp,
  };
}

async function conversationOrThrow(
  env: Env,
  tenantId: string,
  conversationId: string,
): Promise<ConversationRow> {
  const row = await queryOne<ConversationRow>(
    env.DB,
    'SELECT * FROM chat_conversations WHERE tenant_id = ? AND id = ?',
    [tenantId, conversationId],
  );
  if (!row) throw forbidden('Conversa não encontrada.');
  return row;
}

function assertDirectAccess(row: ConversationRow, userId: string): void {
  if (row.type === 'direct' && !jsonArray(row.participant_ids).includes(userId)) {
    throw forbidden('Sem acesso a esta conversa.');
  }
}

export async function chatUsers(env: Env, session: RealtimeSession) {
  const items = await members(env, session.tenantId);
  return items
    .map(({ id, name, email, role, avatarPath }) => ({
      id,
      name,
      email,
      role,
      avatarPath,
    }))
    .filter((user) => user.id !== session.userId);
}

function userLabel(user?: { name?: string | null; email?: string } | null) {
  return user?.name?.trim() || user?.email || '';
}

export async function listConversations(
  env: Env,
  session: RealtimeSession,
  query?: { page?: number | string; limit?: number | string },
): Promise<ChatResult<unknown>> {
  const global = await getGlobalConversation(env, session.tenantId);
  const page = Math.max(1, Number(query?.page ?? 1) || 1);
  const limit = Math.min(100, Math.max(1, Number(query?.limit ?? 30) || 30));
  const direct = await queryAll<ConversationRow>(
    env.DB,
    `SELECT * FROM chat_conversations
      WHERE tenant_id = ? AND type = 'direct'
        AND EXISTS (SELECT 1 FROM json_each(participant_ids) WHERE value = ?)
      ORDER BY updated_at DESC LIMIT ? OFFSET ?`,
    [session.tenantId, session.userId, Math.max(0, limit - 1), (page - 1) * limit],
  );
  const totalDirect = await queryOne<{ count: number }>(
    env.DB,
    `SELECT COUNT(*) AS count FROM chat_conversations
      WHERE tenant_id = ? AND type = 'direct'
        AND EXISTS (SELECT 1 FROM json_each(participant_ids) WHERE value = ?)`,
    [session.tenantId, session.userId],
  );
  const rows = page === 1 ? [global, ...direct] : direct;
  const ids = rows.map((row) => row.id);
  const unread = new Map<string, number>();
  if (ids.length) {
    const placeholders = ids.map(() => '?').join(',');
    const counts = await queryAll<{ conversation_id: string; count: number }>(
      env.DB,
      `SELECT conversation_id, COUNT(*) AS count FROM chat_messages
        WHERE tenant_id = ? AND conversation_id IN (${placeholders})
          AND deleted_at IS NULL
          AND (sender_id IS NULL OR sender_id <> ?)
          AND NOT EXISTS (SELECT 1 FROM json_each(read_by) WHERE value = ?)
        GROUP BY conversation_id`,
      [session.tenantId, ...ids, session.userId, session.userId],
    );
    for (const row of counts) unread.set(row.conversation_id, row.count);
  }
  const tenantMembers = await members(env, session.tenantId);
  const total = (totalDirect?.count ?? 0) + 1;
  return {
    message: 'Requisição concluída.',
    data: {
      items: rows.map((row) => {
        const participant =
          row.type === 'direct'
            ? tenantMembers.find(
                (candidate) =>
                  candidate.id !== session.userId &&
                  jsonArray(row.participant_ids).includes(candidate.id),
              )
            : null;
        return conversationDto(row, {
          unreadCount: unread.get(row.id) ?? 0,
          title: row.type === 'direct' ? userLabel(participant) || row.title : row.title,
          avatarPath: participant?.avatarPath ?? null,
        });
      }),
      page,
      limit,
      total,
      pages: Math.max(1, Math.ceil(total / limit)),
    },
  };
}

export async function createDirectConversation(
  env: Env,
  session: RealtimeSession,
  input: { title?: string; participantIds?: string[] },
): Promise<ChatResult<unknown>> {
  const ids = Array.from(new Set([session.userId, ...(input.participantIds ?? [])]));
  if (ids.length < 2) throw forbidden('Escolha pelo menos uma pessoa.');
  const tenantMembers = await members(env, session.tenantId);
  if (ids.some((id) => !tenantMembers.some((member) => member.id === id))) {
    throw forbidden('Uma das pessoas não pertence à família.');
  }
  const id = crypto.randomUUID();
  const timestamp = now();
  const title = input.title?.trim() || 'Conversa';
  await execute(
    env.DB,
    `INSERT INTO chat_conversations (id, tenant_id, type, title, participant_ids, created_by, created_at, updated_at)
     VALUES (?, ?, 'direct', ?, ?, ?, ?, ?)`,
    [id, session.tenantId, title, JSON.stringify(ids), session.userId, timestamp, timestamp],
  );
  const row = (await queryOne<ConversationRow>(
    env.DB,
    'SELECT * FROM chat_conversations WHERE id = ?',
    [id],
  ))!;
  const participantId = ids.find((value) => value !== session.userId);
  const participant = participantId
    ? tenantMembers.find((member) => member.id === participantId)
    : null;
  const dto = conversationDto(row, {
    title: userLabel(participant) || title,
    avatarPath: participant?.avatarPath ?? null,
  });
  return {
    message: 'Conversa criada.',
    data: dto,
    broadcasts: [{ event: 'chat.conversation.created', data: dto }],
  };
}

async function withSenderAvatars(
  env: Env,
  tenantId: string,
  rows: MessageRow[],
): Promise<Map<string, string | null>> {
  const ids = [
    ...new Set(
      rows
        .flatMap((row) => [row.sender_id])
        .filter((value): value is string => typeof value === 'string' && value.length > 0),
    ),
  ];
  if (!ids.length) return new Map();
  const tenantMembers = await members(env, tenantId);
  return new Map(
    tenantMembers
      .filter((member) => ids.includes(member.id))
      .map((member) => [member.id, member.avatarPath ?? null]),
  );
}

async function replyMap(env: Env, tenantId: string, rows: MessageRow[]) {
  const ids = [
    ...new Set(
      rows
        .map((row) => row.reply_to_message_id)
        .filter((value): value is string => typeof value === 'string' && value.length > 0),
    ),
  ];
  if (!ids.length) return new Map<string, MessageRow>();
  const placeholders = ids.map(() => '?').join(',');
  const replies = await queryAll<MessageRow>(
    env.DB,
    `SELECT * FROM chat_messages WHERE tenant_id = ? AND id IN (${placeholders})`,
    [tenantId, ...ids],
  );
  return new Map(replies.map((row) => [row.id, row]));
}

export async function listMessages(
  env: Env,
  session: RealtimeSession,
  conversationId: string,
  query?: { page?: number | string; limit?: number | string },
): Promise<ChatResult<unknown>> {
  const conversation = await conversationOrThrow(env, session.tenantId, conversationId);
  assertDirectAccess(conversation, session.userId);
  const page = Math.max(1, Number(query?.page ?? 1) || 1);
  const limit = Math.min(100, Math.max(1, Number(query?.limit ?? 80) || 80));
  const [rows, total] = await Promise.all([
    queryAll<MessageRow>(
      env.DB,
      `SELECT * FROM chat_messages WHERE tenant_id = ? AND conversation_id = ?
       ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [session.tenantId, conversationId, limit, (page - 1) * limit],
    ),
    queryOne<{ count: number }>(
      env.DB,
      'SELECT COUNT(*) AS count FROM chat_messages WHERE tenant_id = ? AND conversation_id = ?',
      [session.tenantId, conversationId],
    ),
  ]);
  const ordered = rows.reverse();
  const avatars = await withSenderAvatars(env, session.tenantId, ordered);
  const replies = await replyMap(env, session.tenantId, ordered);
  const items = await Promise.all(
    ordered.map(async (row) => {
      const reply = row.reply_to_message_id ? replies.get(row.reply_to_message_id) : null;
      const replyAvatars = reply ? await withSenderAvatars(env, session.tenantId, [reply]) : new Map();
      return messageDto(row, {
        senderAvatarPath: row.sender_id ? (avatars.get(row.sender_id) ?? null) : null,
        replyToMessage: reply
          ? {
              id: reply.id,
              senderId: reply.sender_id,
              senderName: reply.sender_name,
              senderAvatarPath: reply.sender_id
                ? (replyAvatars.get(reply.sender_id) ?? null)
                : null,
              text: reply.text,
              mediaUrl: reply.media_url,
              mediaType: reply.media_type,
            }
          : null,
      });
    }),
  );
  const count = total?.count ?? 0;
  return {
    message: 'Requisição concluída.',
    conversationId,
    data: {
      items,
      page,
      limit,
      total: count,
      pages: Math.max(1, Math.ceil(count / limit)),
    },
  };
}

function parseListMessage(text: string) {
  const trimmed = text.trim();
  const match = /^lista(?:\s*:\s*|\s+)([\s\S]*)$/i.exec(trimmed);
  if (!match) return null;
  const lines = match[1]
    .trim()
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const first = lines.shift() ?? '';
  const inline = first.includes(':') ? first.split(':') : null;
  const title = (inline ? inline.shift() : first)?.trim() || 'Lista';
  const firstItems = inline?.join(':') ?? '';
  const items = [firstItems, ...lines]
    .flatMap((line) => line.split(/[,;]/))
    .map((item) => item.replace(/^[-*•]\s*/, '').trim())
    .filter(Boolean);
  return { title, items: items.length ? items : ['Novo item'] };
}

async function addListFromChat(
  env: Env,
  session: RealtimeSession,
  text: string,
): Promise<RealtimeBroadcast[]> {
  const parsed = parseListMessage(text);
  if (!parsed) return [];
  const broadcasts: RealtimeBroadcast[] = [];
  let list = await queryOne<{ id: string; title: string }>(
    env.DB,
    'SELECT id, title FROM family_lists WHERE tenant_id = ? AND LOWER(title) = LOWER(?)',
    [session.tenantId, parsed.title],
  );
  if (!list) {
    const id = crypto.randomUUID();
    const timestamp = now();
    await execute(
      env.DB,
      `INSERT INTO family_lists (id, tenant_id, title, description, created_by, created_at, updated_at)
       VALUES (?, ?, ?, NULL, ?, ?, ?)`,
      [id, session.tenantId, parsed.title, session.userId, timestamp, timestamp],
    );
    list = { id, title: parsed.title };
    broadcasts.push({
      event: 'lists.created',
      data: {
        id,
        title: parsed.title,
        description: null,
        createdBy: session.userId,
        createdAt: new Date(timestamp).toISOString(),
        updatedAt: new Date(timestamp).toISOString(),
      },
    });
  }
  for (const itemText of parsed.items) {
    const id = crypto.randomUUID();
    const timestamp = now();
    await execute(
      env.DB,
      `INSERT INTO family_list_items (id, tenant_id, list_id, text, checked, created_by, created_at, updated_at)
       VALUES (?, ?, ?, ?, 0, ?, ?, ?)`,
      [id, session.tenantId, list.id, itemText, session.userId, timestamp, timestamp],
    );
    broadcasts.push({
      event: 'lists.items.created',
      data: {
        id,
        listId: list.id,
        text: itemText,
        checked: false,
        createdBy: session.userId,
        createdAt: new Date(timestamp).toISOString(),
        updatedAt: new Date(timestamp).toISOString(),
      },
    });
  }
  return broadcasts;
}

export async function sendMessage(
  env: Env,
  session: RealtimeSession,
  conversationId: string,
  body: {
    text?: string;
    mediaUrl?: string;
    mediaType?: 'image' | 'video' | 'sticker';
    senderName?: string;
    replyToMessageId?: string;
  },
): Promise<ChatResult<unknown>> {
  const conversation = await conversationOrThrow(env, session.tenantId, conversationId);
  assertDirectAccess(conversation, session.userId);
  const text = body.text?.trim();
  if (!text && !body.mediaUrl) throw badRequest('Escreva uma mensagem.');
  if (body.replyToMessageId) {
    const reply = await queryOne<MessageRow>(
      env.DB,
      'SELECT * FROM chat_messages WHERE tenant_id = ? AND id = ? AND conversation_id = ?',
      [session.tenantId, body.replyToMessageId, conversationId],
    );
    if (!reply) throw badRequest('Mensagem respondida inválida.');
  }
  const senderName = session.name?.trim() || body.senderName?.trim() || 'Visitante';
  const id = crypto.randomUUID();
  const timestamp = now();
  await execute(
    env.DB,
    `INSERT INTO chat_messages (id, tenant_id, conversation_id, sender_id, sender_name, text, media_url, media_type, reply_to_message_id, read_by, delivered_by, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '[]', ?)`,
    [
      id,
      session.tenantId,
      conversationId,
      session.userId,
      senderName,
      text ?? null,
      body.mediaUrl ?? null,
      body.mediaType ?? null,
      body.replyToMessageId ?? null,
      JSON.stringify([session.userId]),
      timestamp,
    ],
  );
  await execute(
    env.DB,
    'UPDATE chat_conversations SET updated_at = ? WHERE tenant_id = ? AND id = ?',
    [timestamp, session.tenantId, conversationId],
  );
  const recipients =
    conversation.type === 'direct'
      ? jsonArray(conversation.participant_ids).filter((id) => id !== session.userId)
      : (await members(env, session.tenantId))
          .filter(
            (member) =>
              member.id !== session.userId &&
              (member.membershipRole === 'owner' ||
                member.membershipRole === 'admin' ||
                member.access.includes('chat')),
          )
          .map((member) => member.id);
  const preview = text
    ? text.length > 120
      ? `${text.slice(0, 117)}...`
      : text
    : body.mediaType === 'image'
      ? 'Foto'
      : body.mediaType === 'video'
        ? 'Vídeo'
        : 'Mensagem';
  const push = await sendPushToUsers(env, session.tenantId, recipients, {
    title: senderName,
    body: preview,
    type: 'chat',
    conversationId,
    senderId: session.userId,
    senderName,
    url: `/chat?conversationId=${conversationId}`,
    channelId: 'chat_messages',
    includeNotification: false,
  });
  if (push.deliveredUserIds.length) {
    await execute(env.DB, 'UPDATE chat_messages SET delivered_by = ? WHERE id = ?', [
      JSON.stringify(push.deliveredUserIds),
      id,
    ]);
  }
  const row = (await queryOne<MessageRow>(
    env.DB,
    'SELECT * FROM chat_messages WHERE id = ?',
    [id],
  ))!;
  const avatars = await withSenderAvatars(env, session.tenantId, [row]);
  let replyDto: Record<string, unknown> | null = null;
  if (row.reply_to_message_id) {
    const reply = await queryOne<MessageRow>(
      env.DB,
      'SELECT * FROM chat_messages WHERE id = ?',
      [row.reply_to_message_id],
    );
    if (reply) {
      const replyAvatars = await withSenderAvatars(env, session.tenantId, [reply]);
      replyDto = {
        id: reply.id,
        senderId: reply.sender_id,
        senderName: reply.sender_name,
        senderAvatarPath: reply.sender_id
          ? (replyAvatars.get(reply.sender_id) ?? null)
          : null,
        text: reply.text,
        mediaUrl: reply.media_url,
        mediaType: reply.media_type,
      };
    }
  }
  const dto = messageDto(row, {
    senderAvatarPath: row.sender_id ? (avatars.get(row.sender_id) ?? null) : null,
    replyToMessage: replyDto,
  });
  const broadcasts: RealtimeBroadcast[] = [
    { event: 'chat.message.created', data: dto, conversationId },
  ];
  if (text) broadcasts.push(...(await addListFromChat(env, session, text)));
  return {
    message: 'Mensagem enviada.',
    data: dto,
    conversationId,
    broadcasts,
  };
}

export async function editMessage(
  env: Env,
  session: RealtimeSession,
  messageId: string,
  text: string,
): Promise<ChatResult<unknown>> {
  const row = await queryOne<MessageRow>(
    env.DB,
    'SELECT * FROM chat_messages WHERE tenant_id = ? AND id = ?',
    [session.tenantId, messageId],
  );
  if (!row) throw forbidden('Mensagem não encontrada.');
  if (row.sender_id !== session.userId) {
    throw forbidden('Você só pode editar suas mensagens.');
  }
  if (row.deleted_at) throw badRequest('Esta mensagem foi apagada.');
  const value = text.trim();
  if (!value) throw badRequest('Escreva uma mensagem.');
  const timestamp = now();
  await execute(
    env.DB,
    'UPDATE chat_messages SET text = ?, edited_at = ? WHERE tenant_id = ? AND id = ?',
    [value, timestamp, session.tenantId, messageId],
  );
  const updated = (await queryOne<MessageRow>(
    env.DB,
    'SELECT * FROM chat_messages WHERE id = ?',
    [messageId],
  ))!;
  const dto = messageDto(updated);
  return {
    message: 'Mensagem editada.',
    data: dto,
    conversationId: updated.conversation_id,
    broadcasts: [
      { event: 'chat.message.updated', data: dto, conversationId: updated.conversation_id },
    ],
  };
}

export async function deleteMessage(
  env: Env,
  session: RealtimeSession,
  messageId: string,
): Promise<ChatResult<unknown>> {
  const row = await queryOne<MessageRow>(
    env.DB,
    'SELECT * FROM chat_messages WHERE tenant_id = ? AND id = ?',
    [session.tenantId, messageId],
  );
  if (!row) throw forbidden('Mensagem não encontrada.');
  if (row.sender_id !== session.userId) {
    throw forbidden('Você só pode apagar suas mensagens.');
  }
  if (!row.deleted_at) {
    await execute(
      env.DB,
      `UPDATE chat_messages SET text = NULL, media_url = NULL, media_type = NULL, deleted_at = ?
       WHERE tenant_id = ? AND id = ?`,
      [now(), session.tenantId, messageId],
    );
  }
  const updated = (await queryOne<MessageRow>(
    env.DB,
    'SELECT * FROM chat_messages WHERE id = ?',
    [messageId],
  ))!;
  const dto = messageDto(updated);
  return {
    message: 'Mensagem apagada.',
    data: dto,
    conversationId: updated.conversation_id,
    broadcasts: [
      { event: 'chat.message.updated', data: dto, conversationId: updated.conversation_id },
    ],
  };
}

export async function markMessagesRead(
  env: Env,
  session: RealtimeSession,
  conversationId: string,
): Promise<ChatResult<unknown>> {
  const conversation = await conversationOrThrow(env, session.tenantId, conversationId);
  assertDirectAccess(conversation, session.userId);
  await execute(
    env.DB,
    `UPDATE chat_messages
        SET read_by = json_insert(read_by, '$[#]', ?)
      WHERE tenant_id = ? AND conversation_id = ? AND deleted_at IS NULL
        AND (sender_id IS NULL OR sender_id <> ?)
        AND NOT EXISTS (SELECT 1 FROM json_each(read_by) WHERE value = ?)`,
    [session.userId, session.tenantId, conversationId, session.userId, session.userId],
  );
  const payload = { conversationId, userId: session.userId };
  return {
    message: 'Mensagens lidas.',
    data: payload,
    conversationId,
    broadcasts: [
      { event: 'chat.messages.read', data: payload, conversationId },
    ],
  };
}

export async function typing(
  env: Env,
  session: RealtimeSession,
  body: { conversationId: string; senderName?: string; isTyping: boolean },
): Promise<ChatResult<unknown>> {
  const conversation = await conversationOrThrow(env, session.tenantId, body.conversationId);
  assertDirectAccess(conversation, session.userId);
  const payload = {
    conversationId: body.conversationId,
    userId: session.userId,
    senderName: session.name?.trim() || body.senderName?.trim() || 'Pessoa',
    isTyping: body.isTyping,
  };
  return {
    message: 'Requisição concluída.',
    data: payload,
    conversationId: body.conversationId,
    broadcasts: [
      {
        event: 'chat.typing',
        data: payload,
        conversationId: body.conversationId,
        exceptUserId: session.userId,
      },
    ],
  };
}
