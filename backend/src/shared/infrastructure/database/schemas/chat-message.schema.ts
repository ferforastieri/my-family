import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

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

  @Prop({ enum: ['image', 'video'] })
  mediaType?: 'image' | 'video';

  createdAt: Date;
}

export type ChatMessageMongoDocument = HydratedDocument<ChatMessageDocument>;
export const ChatMessageSchema =
  SchemaFactory.createForClass(ChatMessageDocument);
