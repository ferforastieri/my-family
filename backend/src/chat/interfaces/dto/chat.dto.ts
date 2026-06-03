import { IsArray, IsIn, IsOptional, IsString } from 'class-validator';

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
  @IsIn(['image', 'video'])
  mediaType?: 'image' | 'video';

  @IsOptional()
  @IsString()
  senderName?: string;
}

export class ChatConversationResponseDto {
  id: string;
  type: 'global' | 'direct';
  title: string;
  participantIds: string[];
  createdBy: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export class ChatMessageResponseDto {
  id: string;
  conversationId: string;
  senderId: string | null;
  senderName: string;
  text: string | null;
  mediaUrl: string | null;
  mediaType: 'image' | 'video' | null;
  at: number;
}
