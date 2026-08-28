import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { createHash, randomBytes } from 'node:crypto';
import { TenancyRepository } from '../infrastructure/tenancy.repository';
import { UserRepository } from '@auth/infrastructure/repositories/user.repository';
import {
  normalizeAccessKeys,
  type UserRole,
} from '@auth/domain/entities/user.entity';
import type { MembershipRole, TenantFont } from '../domain/tenant.entity';
import {
  PhoneMessagingService,
  type PhoneChannel,
} from '@auth/application/services/phone-messaging.service';

const reservedSlugs = new Set([
  'api',
  'app',
  'admin',
  'painel',
  'demo',
  'public',
  'www',
  'ajuda',
  'suporte',
]);

@Injectable()
export class TenancyService {
  constructor(
    private repo: TenancyRepository,
    private users: UserRepository,
    private messaging: PhoneMessagingService,
  ) {}

  normalizeSlug(value: string) {
    const slug = value?.trim().toLowerCase();
    if (
      !/^[a-z0-9][a-z0-9-]{1,46}[a-z0-9]$/.test(slug) ||
      reservedSlugs.has(slug)
    )
      throw new BadRequestException(
        'Endereço da família inválido ou reservado.',
      );
    return slug;
  }
  async createFamily(userId: string, name: string, rawSlug: string) {
    const slug = this.normalizeSlug(rawSlug);
    if (!name?.trim())
      throw new BadRequestException('Nome da família é obrigatório.');
    if (await this.repo.findTenantBySlug(slug))
      throw new ConflictException('Este endereço já está em uso.');
    const tenant = await this.repo.createTenant({ name: name.trim(), slug });
    try {
      await this.repo.createMembership({
        tenantId: tenant.id,
        userId,
        role: 'owner',
        relationship: 'friends',
      });
    } catch (error) {
      await this.repo.deleteTenant(tenant.id);
      throw error;
    }
    return tenant;
  }
  async membershipsForUser(userId: string) {
    const rows = await this.repo.listMembershipsForUser(userId);
    const items = await Promise.all(
      rows.map(async (row) => {
        const tenant = await this.repo.findTenantById(row.tenantId);
        return tenant && tenant.status !== 'deleted'
          ? {
              ...tenant,
              membershipRole: row.role,
              relationship: row.relationship,
              access: row.access,
            }
          : null;
      }),
    );
    return items.filter(Boolean);
  }
  async principal(userId: string, tenantId: string) {
    const [user, tenant, membership] = await Promise.all([
      this.users.findById(userId),
      this.repo.findTenantById(tenantId),
      this.repo.findMembership(tenantId, userId),
    ]);
    if (!user || !tenant || !membership)
      throw new ForbiddenException('Você não participa desta família.');
    if (tenant.status !== 'active')
      throw new ForbiddenException('Este ambiente está indisponível.');
    return {
      id: user.id,
      phoneNumber: user.phoneNumber,
      name: user.name,
      avatarPath: user.avatarPath,
      platformRole: user.platformRole,
      tenantId: tenant.id,
      tenant,
      membershipId: String(membership._id),
      membershipRole: membership.role as MembershipRole,
      role: membership.relationship as UserRole,
      access: normalizeAccessKeys(membership.access),
      isDemo: tenant.isDemo,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }
  async current(tenantId: string) {
    const tenant = await this.repo.findTenantById(tenantId);
    if (!tenant) throw new NotFoundException('Família não encontrada.');
    return tenant;
  }
  update(tenantId: string, data: { name?: string }) {
    return this.repo.updateTenant(tenantId, {
      ...(data.name?.trim() ? { name: data.name.trim() } : {}),
    });
  }
  updateTheme(
    tenantId: string,
    data: { primaryColor: string; fontFamily: TenantFont },
  ) {
    if (!/^#[0-9A-Fa-f]{6}$/.test(data.primaryColor))
      throw new BadRequestException('Cor principal inválida.');
    if (!['nunitoSans', 'cormorantGaramond'].includes(data.fontFamily))
      throw new BadRequestException('Fonte inválida.');
    return this.repo.updateTenant(tenantId, {
      theme: {
        primaryColor: data.primaryColor.toUpperCase(),
        fontFamily: data.fontFamily,
      },
    });
  }
  async invite(
    tenantId: string,
    invitedBy: string,
    input: {
      phone: string;
      channel?: PhoneChannel;
      role?: MembershipRole;
      relationship?: UserRole;
      access?: string[];
    },
  ) {
    const phoneNumber = this.messaging.normalizePhoneNumber(input.phone);
    if (!phoneNumber) throw new BadRequestException('Celular inválido.');
    if (input.role === 'owner')
      throw new BadRequestException('O papel owner não pode ser convidado.');
    const token = randomBytes(32).toString('base64url');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const row = await this.repo.createInvitation({
      tenantId,
      invitedBy,
      phoneNumber,
      channel: input.channel ?? 'whatsapp',
      role: input.role ?? 'member',
      relationship: input.relationship ?? 'friends',
      access: normalizeAccessKeys(input.access),
      tokenHash: hashToken(token),
      expiresAt,
    });
    const tenant = await this.repo.findTenantById(tenantId);
    try {
      await this.messaging.sendInvitation(
        phoneNumber,
        tenant?.name ?? 'uma família',
        token,
        input.channel ?? 'whatsapp',
      );
    } catch {
      // O convite continua válido e pode ser reenviado sem perder o token.
    }
    return {
      id: String(row._id),
      phoneNumber,
      channel: row.channel,
      role: row.role,
      expiresAt,
      token,
    };
  }
  invitations(tenantId: string) {
    return this.repo.listInvitations(tenantId);
  }
  revokeInvitation(tenantId: string, id: string) {
    return this.repo.revokeInvitation(id, tenantId);
  }
  async acceptInvitation(userId: string, rawToken: string) {
    const invitation = await this.repo.findInvitationByHash(
      hashToken(rawToken),
    );
    if (!invitation)
      throw new BadRequestException('Convite inválido ou expirado.');
    const user = await this.users.findById(userId);
    if (!user || user.phoneNumber !== invitation.phoneNumber)
      throw new ForbiddenException('Este convite pertence a outro celular.');
    const existing = await this.repo.findMembership(
      invitation.tenantId,
      userId,
    );
    if (!existing)
      await this.repo.createMembership({
        tenantId: invitation.tenantId,
        userId,
        role: invitation.role as MembershipRole,
        relationship: invitation.relationship as UserRole,
        access: normalizeAccessKeys(invitation.access),
      });
    await this.repo.acceptInvitation(String(invitation._id));
    return this.repo.findTenantById(invitation.tenantId);
  }
  async members(tenantId: string) {
    const rows = await this.repo.listMembershipsForTenant(tenantId);
    return Promise.all(
      rows.map(async (row) => {
        const user = await this.users.findById(row.userId);
        return {
          id: row.userId,
          membershipId: String(row._id),
          phoneNumber: user?.phoneNumber ?? '',
          name: user?.name ?? null,
          avatarPath: user?.avatarPath ?? null,
          role: row.relationship,
          membershipRole: row.role,
          access: row.access,
          createdAt: row.createdAt,
        };
      }),
    );
  }
  async member(tenantId: string, userId: string) {
    return (
      (await this.members(tenantId)).find((item) => item.id === userId) ?? null
    );
  }
  async updateMember(
    tenantId: string,
    actorUserId: string,
    userId: string,
    data: {
      role?: UserRole;
      access?: string[];
      membershipRole?: MembershipRole;
    },
  ) {
    const [actor, membership] = await Promise.all([
      this.repo.findMembership(tenantId, actorUserId),
      this.repo.findMembership(tenantId, userId),
    ]);
    if (!actor || !membership)
      throw new NotFoundException('Membro não encontrado.');
    if (membership.role === 'owner' && actor.role !== 'owner') {
      throw new ForbiddenException('Somente o owner pode alterar o owner.');
    }
    if (data.membershipRole && actor.role !== 'owner') {
      throw new ForbiddenException(
        'Somente o owner pode alterar administradores.',
      );
    }
    if (
      membership.role === 'owner' &&
      data.membershipRole &&
      data.membershipRole !== 'owner'
    )
      throw new BadRequestException(
        'Transfira a propriedade antes de alterar o owner.',
      );
    await this.repo.updateMembership(tenantId, userId, {
      ...(data.role ? { relationship: data.role } : {}),
      ...(data.access ? { access: normalizeAccessKeys(data.access) } : {}),
      ...(data.membershipRole ? { role: data.membershipRole } : {}),
    });
    return this.member(tenantId, userId);
  }
  async removeMember(tenantId: string, actorUserId: string, userId: string) {
    const [actor, membership] = await Promise.all([
      this.repo.findMembership(tenantId, actorUserId),
      this.repo.findMembership(tenantId, userId),
    ]);
    if (!actor || !membership) return false;
    if (membership.role === 'owner')
      throw new BadRequestException('O owner não pode ser removido.');
    if (membership.role === 'admin' && actor.role !== 'owner') {
      throw new ForbiddenException(
        'Somente o owner pode remover administradores.',
      );
    }
    await this.repo.deleteMembership(tenantId, userId);
    return true;
  }
}

export function hashToken(value: string) {
  return createHash('sha256').update(value).digest('hex');
}
