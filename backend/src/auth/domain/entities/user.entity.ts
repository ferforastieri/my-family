export const userRoles = ['husband', 'wife', 'children', 'friends'] as const;
export type UserRole = (typeof userRoles)[number];

export const adminRoles: UserRole[] = ['husband', 'wife'];

export const userAccessKeys = [
  'memorias',
  'playlist',
  'cartas',
  'jogos',
  'listas',
  'localizacao',
  'chat',
  'nossaHistoria',
] as const;
export type UserAccessKey = (typeof userAccessKeys)[number];

export function isAdminRole(role?: string | null): role is UserRole {
  return role === 'husband' || role === 'wife';
}

export function normalizeAccessKeys(
  access?: readonly string[] | null,
): UserAccessKey[] {
  if (!access?.length) return [];
  return [...new Set(access)].filter((key): key is UserAccessKey =>
    userAccessKeys.includes(key as UserAccessKey),
  );
}

export interface UserEntity {
  id: string;
  email: string;
  passwordHash?: string | null;
  name?: string | null;
  role: UserRole;
  access: UserAccessKey[];
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
