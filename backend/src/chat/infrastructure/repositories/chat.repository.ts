import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  ChatConversationDocument,
  ChatConversationMongoDocument,
} from '../persistence/chat-conversation.schema';
import {
  ChatMessageDocument,
  ChatMessageMongoDocument,
} from '../persistence/chat-message.schema';
import {
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type {
  ChatConversationEntity,
  ChatMessageEntity,
} from '@chat/domain/entities/chat.entity';

export type ChatMessageWrite = {
  conversationId: string;
  senderId?: string | null;
  senderName: string;
  text?: string;
  mediaUrl?: string;
  mediaType?: 'image' | 'video' | 'sticker';
  replyToMessageId?: string | null;
  readBy?: string[];
};

@Injectable()
export class ChatRepository {
  constructor(
    @InjectModel(ChatConversationDocument.name)
    private conversations: Model<ChatConversationMongoDocument>,
    @InjectModel(ChatMessageDocument.name)
    private messages: Model<ChatMessageMongoDocument>,
  ) {}

  private toConversation(
    doc: ChatConversationMongoDocument | null,
  ): ChatConversationEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      type: doc.type,
      title: doc.title,
      participantIds: doc.participantIds ?? [],
      createdBy: doc.createdBy ?? null,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    };
  }

  private toMessage(
    doc: ChatMessageMongoDocument | null,
  ): ChatMessageEntity | null {
    if (!doc) return null;
    return {
      id: toId(doc),
      conversationId: doc.conversationId,
      senderId: doc.senderId ?? null,
      senderName: doc.senderName,
      text: doc.text ?? null,
      mediaUrl: doc.mediaUrl ?? null,
      mediaType: doc.mediaType ?? null,
      replyToMessageId: doc.replyToMessageId ?? null,
      readBy: doc.readBy ?? [],
      editedAt: doc.editedAt ?? null,
      deletedAt: doc.deletedAt ?? null,
      createdAt: doc.createdAt,
    };
  }

  async getGlobalConversation() {
    const existing = await this.conversations
      .findOne({ type: 'global' })
      .exec();
    if (existing) return this.toConversation(existing)!;
    return this.toConversation(
      await this.conversations.create({
        type: 'global',
        title: 'Chat global',
        participantIds: [],
      }),
    )!;
  }

  async listForUser(userId?: string | null, query?: PaginationQuery) {
    const global = await this.getGlobalConversation();
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 30,
      maxLimit: 100,
    });
    if (!userId) return paginated(page === 1 ? [global] : [], 1, page, limit);
    const rows = await this.conversations
      .find({ type: 'direct', participantIds: userId })
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(Math.max(0, limit - 1))
      .exec();
    const totalDirect = await this.conversations
      .countDocuments({ type: 'direct', participantIds: userId })
      .exec();
    return paginated(
      [global, ...rows.map((doc) => this.toConversation(doc)!)],
      totalDirect + 1,
      page,
      limit,
    );
  }

  async unreadCountsForUser(userId: string, conversationIds: string[]) {
    if (conversationIds.length === 0) return new Map<string, number>();
    const rows = await this.messages
      .aggregate<{ _id: string; count: number }>([
        {
          $match: {
            conversationId: { $in: conversationIds },
            senderId: { $ne: userId },
            readBy: { $ne: userId },
            deletedAt: { $exists: false },
          },
        },
        { $group: { _id: '$conversationId', count: { $sum: 1 } } },
      ])
      .exec();
    return new Map(rows.map((row) => [row._id, row.count]));
  }

  async findConversation(id: string) {
    return this.toConversation(await this.conversations.findById(id).exec());
  }

  async createDirectConversation(data: {
    title: string;
    participantIds: string[];
    createdBy: string;
  }) {
    return this.toConversation(
      await this.conversations.create({ type: 'direct', ...data }),
    )!;
  }

  async listMessages(conversationId: string, query?: PaginationQuery) {
    const { page, limit, skip } = normalizePagination(query, {
      page: 1,
      limit: 80,
      maxLimit: 100,
    });
    const filter = { conversationId };
    const [docs, total] = await Promise.all([
      this.messages
        .find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.messages.countDocuments(filter).exec(),
    ]);
    return paginated(
      await this.withReplyMessages(
        docs.reverse().map((doc) => this.toMessage(doc)!),
      ),
      total,
      page,
      limit,
    );
  }

  async createMessage(data: ChatMessageWrite) {
    const message = (
      await this.withReplyMessages([
        this.toMessage(await this.messages.create(data))!,
      ])
    )[0];
    await this.conversations
      .findByIdAndUpdate(data.conversationId, {
        $set: { updatedAt: new Date() },
      })
      .exec();
    return message;
  }

  private async withReplyMessages(messages: ChatMessageEntity[]) {
    const replyIds = [
      ...new Set(
        messages
          .map((message) => message.replyToMessageId)
          .filter(
            (id): id is string => typeof id === 'string' && id.length > 0,
          ),
      ),
    ];
    if (replyIds.length === 0) return messages;
    const replyDocs = await this.messages
      .find({ _id: { $in: replyIds } })
      .exec();
    const replies = new Map(
      replyDocs
        .map((doc) => this.toMessage(doc))
        .filter((message): message is ChatMessageEntity => message != null)
        .map((message) => [message.id, message]),
    );
    return messages.map((message) => {
      const reply = message.replyToMessageId
        ? replies.get(message.replyToMessageId)
        : null;
      return {
        ...message,
        replyToMessage: reply
          ? {
              id: reply.id,
              senderId: reply.senderId,
              senderName: reply.senderName,
              text: reply.text,
              mediaUrl: reply.mediaUrl,
              mediaType: reply.mediaType,
            }
          : null,
      };
    });
  }

  async findMessage(id: string) {
    return this.toMessage(await this.messages.findById(id).exec());
  }

  async editMessage(id: string, text: string) {
    return this.toMessage(
      await this.messages
        .findByIdAndUpdate(
          id,
          { $set: { text, editedAt: new Date() } },
          { new: true },
        )
        .exec(),
    );
  }

  async deleteMessage(id: string) {
    return this.toMessage(
      await this.messages
        .findByIdAndUpdate(
          id,
          {
            $set: {
              text: null,
              mediaUrl: null,
              mediaType: null,
              deletedAt: new Date(),
            },
          },
          { new: true },
        )
        .exec(),
    );
  }

  async markMessagesRead(conversationId: string, userId: string) {
    await this.messages
      .updateMany(
        {
          conversationId,
          senderId: { $ne: userId },
          readBy: { $ne: userId },
        },
        { $addToSet: { readBy: userId } },
      )
      .exec();
  }
}
