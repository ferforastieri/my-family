import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { applyTenantScope } from '@tenancy/infrastructure/tenant-scope.plugin';

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'chat_messages',
})
export class ChatMessageDocument {
  @Prop({ required: true })
  conversationId: string;

  @Prop()
  senderId?: string;

  @Prop({ required: true })
  senderName: string;

  @Prop()
  text?: string;

  @Prop()
  mediaUrl?: string;

  @Prop({ type: String, enum: ['image', 'video', 'sticker'] })
  mediaType?: 'image' | 'video' | 'sticker';

  @Prop()
  replyToMessageId?: string;

  @Prop({ type: [String], default: [] })
  readBy: string[];

  @Prop()
  editedAt?: Date;

  @Prop()
  deletedAt?: Date;

  createdAt: Date;
}

export type ChatMessageMongoDocument = HydratedDocument<ChatMessageDocument>;
export const ChatMessageSchema =
  SchemaFactory.createForClass(ChatMessageDocument);
applyTenantScope(ChatMessageSchema);
