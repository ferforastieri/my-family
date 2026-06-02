export const userRoles = ['admin', 'wife', 'child', 'friend'] as const;
export type UserRole = (typeof userRoles)[number];

export interface UserEntity {
  id: string;
  email: string;
  passwordHash?: string | null;
  name?: string | null;
  role: UserRole;
  avatarPath?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface PasswordResetEntity {
  id: string;
  userId: string;
  token: string;
  expiresAt: Date;
  used?: Date | null;
  createdAt: Date;
}

export interface FotoEntity {
  id: string;
  url: string;
  texto?: string | null;
  album?: string | null;
  tipo: 'imagem' | 'video';
  data?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface MusicaEntity {
  id: string;
  titulo: string;
  artista: string;
  linkSpotify: string;
  descricao?: string | null;
  momento: string;
  data: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface CartaEntity {
  id: string;
  titulo: string;
  conteudo: string;
  data: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface NotificationEntity {
  id: string;
  title: string;
  body: string;
  url: string;
  icon?: string | null;
  createdAt: Date;
}

export interface PushSubscriptionEntity {
  id: string;
  fcmToken?: string | null;
  platform?: 'web' | 'android' | 'ios' | 'unknown' | null;
  userAgent?: string | null;
  createdAt: Date;
}

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
  mediaType?: 'image' | 'video' | null;
  createdAt: Date;
}

export interface QuizQuestionEntity {
  id: string;
  question: string;
  options: string[];
  correctIndex: number;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface GameCompletionEntity {
  id: string;
  game: 'quiz' | 'word_search';
  playerName: string;
  userId?: string | null;
  score?: number | null;
  total?: number | null;
  createdAt: Date;
}
