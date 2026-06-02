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
  tipo: 'imagem' | 'video';
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
