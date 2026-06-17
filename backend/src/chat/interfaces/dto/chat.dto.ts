import {
  IsArray,
  IsBoolean,
  IsIn,
  IsOptional,
  IsString,
} from 'class-validator';

export class ChatConversationCreateDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsArray()
  @IsString({ each: true })
  participantIds: string[];
}

export class ChatMessageSendDto {
  @IsString()
  conversationId: string;

  @IsOptional()
  @IsString()
  text?: string;

  @IsOptional()
  @IsString()
  mediaUrl?: string;

  @IsOptional()
  @IsIn(['image', 'video', 'sticker'])
  mediaType?: 'image' | 'video' | 'sticker';

  @IsOptional()
  @IsString()
  senderName?: string;

  @IsOptional()
  @IsString()
  replyToMessageId?: string;
}

export class ChatMessageEditDto {
  @IsString()
  messageId: string;

  @IsString()
  text: string;
}

export class ChatMessageActionDto {
  @IsString()
  messageId: string;
}

export class ChatMessagesReadDto {
  @IsString()
  conversationId: string;
}

export class ChatTypingDto {
  @IsString()
  conversationId: string;

  @IsOptional()
  @IsString()
  senderName?: string;

  @IsBoolean()
  isTyping: boolean;
}

export class ChatConversationResponseDto {
  id: string;
  type: 'global' | 'direct';
  title: string;
  participantIds: string[];
  unreadCount: number;
  avatarPath: string | null;
  createdBy: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export class ChatMessageResponseDto {
  id: string;
  conversationId: string;
  senderId: string | null;
  senderName: string;
  senderAvatarPath: string | null;
  text: string | null;
  mediaUrl: string | null;
  mediaType: 'image' | 'video' | 'sticker' | null;
  replyToMessageId: string | null;
  replyToMessage: ChatMessageReplyResponseDto | null;
  readBy: string[];
  editedAt: number | null;
  deletedAt: number | null;
  at: number;
}

export class ChatMessageReplyResponseDto {
  id: string;
  senderId: string | null;
  senderName: string;
  senderAvatarPath: string | null;
  text: string | null;
  mediaUrl: string | null;
  mediaType: 'image' | 'video' | 'sticker' | null;
}
