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
