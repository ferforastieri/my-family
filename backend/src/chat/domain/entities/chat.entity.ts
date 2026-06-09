export interface ChatConversationEntity {
  id: string;
  type: 'global' | 'direct';
  title: string;
  participantIds: string[];
  createdBy?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface ChatMessageEntity {
  id: string;
  conversationId: string;
  senderId?: string | null;
  senderName: string;
  text?: string | null;
  mediaUrl?: string | null;
  mediaType?: 'image' | 'video' | 'sticker' | null;
  readBy: string[];
  editedAt?: Date | null;
  deletedAt?: Date | null;
  createdAt: Date;
}
