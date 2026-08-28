export const userRoles = ['husband', 'wife', 'children', 'friends'] as const;
export type UserRole = (typeof userRoles)[number];

export const userAccessKeys = [
  'memorias',
  'playlist',
  'cartas',
  'jogos',
  'listas',
  'notas',
  'localizacao',
  'chat',
  'nossaHistoria',
] as const;
export type UserAccessKey = (typeof userAccessKeys)[number];

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
  phoneNumber: string;
  name?: string | null;
  role: UserRole;
  access: UserAccessKey[];
  avatarPath?: string | null;
  platformRole?: 'super_admin' | null;
  createdAt: Date;
  updatedAt: Date;
}
