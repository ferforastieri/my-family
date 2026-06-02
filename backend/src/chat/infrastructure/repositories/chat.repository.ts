import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  ChatConversationDocument,
  ChatConversationMongoDocument,
  ChatMessageDocument,
  ChatMessageMongoDocument,
} from '@shared/infrastructure/database/schemas';
import { toId } from '@shared/infrastructure/database/mongo.utils';
import type { ChatConversationEntity, ChatMessageEntity } from '@shared/domain/entities';

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
    @InjectModel(ChatConversationDocument.name) private conversations: Model<ChatConversationMongoDocument>,
    @InjectModel(ChatMessageDocument.name) private messages: Model<ChatMessageMongoDocument>,
  ) {}

  private toConversation(doc: ChatConversationMongoDocument | null): ChatConversationEntity | null {
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

  private toMessage(doc: ChatMessageMongoDocument | null): ChatMessageEntity | null {
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
    const existing = await this.conversations.findOne({ type: 'global' }).exec();
    if (existing) return this.toConversation(existing)!;
    return this.toConversation(await this.conversations.create({ type: 'global', title: 'Chat global', participantIds: [] }))!;
  }

  async listForUser(userId?: string | null) {
    const global = await this.getGlobalConversation();
    if (!userId) return [global];
    const rows = await this.conversations
      .find({ type: 'direct', participantIds: userId })
      .sort({ updatedAt: -1 })
      .exec();
    return [global, ...rows.map((doc) => this.toConversation(doc)!)];
  }

  async findConversation(id: string) {
    return this.toConversation(await this.conversations.findById(id).exec());
  }

  async createDirectConversation(data: { title: string; participantIds: string[]; createdBy: string }) {
    return this.toConversation(await this.conversations.create({ type: 'direct', ...data }))!;
  }

  async listMessages(conversationId: string, limit = 80) {
    return (await this.messages.find({ conversationId }).sort({ createdAt: -1 }).limit(limit).exec())
      .reverse()
      .map((doc) => this.toMessage(doc)!);
  }

  async createMessage(data: ChatMessageWrite) {
    const message = this.toMessage(await this.messages.create(data))!;
    await this.conversations.findByIdAndUpdate(data.conversationId, { $set: { updatedAt: new Date() } }).exec();
    return message;
  }
}
