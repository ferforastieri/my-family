export const userRoles = ['owner', 'admin', 'member'] as const;
export type UserRole = (typeof userRoles)[number];
export const platformRoles = ['admin'] as const;
export type PlatformRole = (typeof platformRoles)[number];
export const sessionScopes = [
  'account',
  'tenant',
  'platform',
  'support',
] as const;
export type SessionScope = (typeof sessionScopes)[number];

export const adminRoles: UserRole[] = ['owner', 'admin'];

export function isAdminRole(role?: string | null): role is UserRole {
  return role === 'owner' || role === 'admin';
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
  platformRole?: PlatformRole | null;
  sessionScope: SessionScope;
  role: UserRole;
  access: UserAccessKey[];
  tenantId?: string | null;
  membershipId?: string | null;
  tenantSlug?: string | null;
  actorUserId?: string | null;
  actorEmail?: string | null;
  supportSessionId?: string | null;
  avatarPath?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export type AuthJwtPayload = {
  sub: string;
  scope: SessionScope;
  platformRole?: PlatformRole;
  tenantId?: string;
  membershipId?: string;
  effectiveSub?: string;
  supportSessionId?: string;
  type?: 'refresh';
};

export interface PasswordResetEntity {
  id: string;
  userId: string;
  token: string;
  expiresAt: Date;
  used?: Date | null;
  createdAt: Date;
}
import { userAccessKeys, type UserAccessKey } from '@shared/domain/access';
export { userAccessKeys, type UserAccessKey } from '@shared/domain/access';
