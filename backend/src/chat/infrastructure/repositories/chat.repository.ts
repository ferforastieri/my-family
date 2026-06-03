import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  ChatConversationDocument,
  ChatConversationMongoDocument,
  ChatMessageDocument,
  ChatMessageMongoDocument,
} from '@shared/infrastructure/database/schemas';
import {
  normalizePagination,
  paginated,
  PaginationQuery,
  toId,
} from '@shared/infrastructure/database/mongo.utils';
import type {
  ChatConversationEntity,
  ChatMessageEntity,
} from '@shared/domain/entities';

export type ChatMessageWrite = {
  conversationId: string;
  senderId?: string | null;
  senderName: string;
  text?: string;
  mediaUrl?: string;
  mediaType?: 'image' | 'video';
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
      docs.reverse().map((doc) => this.toMessage(doc)!),
      total,
      page,
      limit,
    );
  }

  async createMessage(data: ChatMessageWrite) {
    const message = this.toMessage(await this.messages.create(data))!;
    await this.conversations
      .findByIdAndUpdate(data.conversationId, {
        $set: { updatedAt: new Date() },
      })
      .exec();
    return message;
  }
}
