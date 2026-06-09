export const userRoles = ['marido', 'esposa', 'filhos', 'amigos'] as const;
export type UserRole = (typeof userRoles)[number];

export const adminRoles: UserRole[] = ['marido', 'esposa'];

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
  return role === 'marido' || role === 'esposa';
}

export function normalizeUserRole(role?: string | null): UserRole {
  if (role === 'admin') return 'marido';
  if (role === 'wife') return 'esposa';
  if (role === 'child') return 'filhos';
  if (role === 'friend') return 'amigos';
  return userRoles.includes(role as UserRole) ? (role as UserRole) : 'amigos';
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
