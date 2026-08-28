import type {
  UserAccessKey,
  UserRole,
} from '@auth/domain/entities/user.entity';

type TenantStatus = 'active' | 'suspended' | 'deleted';
export type MembershipRole = 'owner' | 'admin' | 'member';
export type TenantFont = 'nunitoSans' | 'cormorantGaramond';
type PlatformRole = 'super_admin';

export interface TenantTheme {
  primaryColor: string;
  fontFamily: TenantFont;
}

export interface TenantEntity {
  id: string;
  name: string;
  slug: string;
  status: TenantStatus;
  planCode: string;
  subscriptionStatus: 'active' | 'past_due' | 'cancelled';
  theme: TenantTheme;
  isDemo: boolean;
  expiresAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface TenantPrincipal {
  id: string;
  phoneNumber: string;
  name?: string | null;
  avatarPath?: string | null;
  platformRole?: PlatformRole | null;
  tenantId?: string | null;
  tenant?: TenantEntity | null;
  membershipId?: string | null;
  membershipRole?: MembershipRole | null;
  role: UserRole;
  access: UserAccessKey[];
  isDemo?: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export function isTenantAdmin(user?: Partial<TenantPrincipal> | null) {
  return user?.membershipRole === 'owner' || user?.membershipRole === 'admin';
}
