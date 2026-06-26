import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { applyTenantScope } from '@tenancy/infrastructure/tenant-scope.plugin';

@Schema({ timestamps: true, collection: 'chat_conversations' })
export class ChatConversationDocument {
  @Prop({ type: String, required: true, enum: ['global', 'direct'] })
  type: 'global' | 'direct';

  @Prop({ required: true })
  title: string;

  @Prop({ type: [String], default: [] })
  participantIds: string[];

  @Prop()
  createdBy?: string;

  createdAt: Date;
  updatedAt: Date;
}

export type ChatConversationMongoDocument =
  HydratedDocument<ChatConversationDocument>;
export const ChatConversationSchema = SchemaFactory.createForClass(
  ChatConversationDocument,
);
applyTenantScope(ChatConversationSchema);
