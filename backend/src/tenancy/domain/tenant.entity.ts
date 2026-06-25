import type { UserAccessKey } from '@shared/domain/access';
import type { SessionScope } from '@auth/domain/entities/user.entity';

export const tenantLocales = ['pt-BR', 'en', 'es'] as const;
export type TenantLocale = (typeof tenantLocales)[number];

export const tenantStatuses = [
  'draft',
  'pending_payment',
  'active',
  'past_due',
  'suspended',
  'canceled',
] as const;
export type TenantStatus = (typeof tenantStatuses)[number];

export const membershipRoles = ['owner', 'admin', 'member'] as const;
export type MembershipRole = (typeof membershipRoles)[number];

export interface TenantEntity {
  id: string;
  name: string;
  slug: string;
  ownerUserId: string;
  defaultLocale: TenantLocale;
  status: TenantStatus;
  isDemo: boolean;
  isPublished: boolean;
  theme: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

export interface MembershipEntity {
  id: string;
  tenantId: string;
  userId: string;
  role: MembershipRole;
  access: UserAccessKey[];
  relationLabel?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface TenantContextValue {
  tenantId: string;
  tenantSlug?: string;
  userId?: string;
  membershipId?: string;
  role?: MembershipRole;
  access?: UserAccessKey[];
  isDemo?: boolean;
  isPublic?: boolean;
  sessionScope?: SessionScope;
  actorUserId?: string;
  supportSessionId?: string;
}

export function isTenantAdmin(role?: string | null): boolean {
  return role === 'owner' || role === 'admin';
}
