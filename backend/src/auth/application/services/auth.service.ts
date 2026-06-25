import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomBytes } from 'node:crypto';
import * as bcrypt from 'bcrypt';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { EmailService } from '@shared/infrastructure/email/email.service';
import { TenantRepository } from '@tenancy/infrastructure/tenant.repository';
import { TenantService } from '@tenancy/application/tenant.service';
import type {
  MembershipEntity,
  TenantEntity,
  TenantLocale,
} from '@tenancy/domain/tenant.entity';
import type {
  AuthJwtPayload,
  SessionScope,
  UserEntity,
} from '@auth/domain/entities/user.entity';
import { UserRepository } from '../../infrastructure/repositories/user.repository';
import { PasswordResetRepository } from '../../infrastructure/repositories/password-reset.repository';
import { SupportSessionService } from './support-session.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UserRepository,
    private readonly passwordResets: PasswordResetRepository,
    private readonly tenants: TenantRepository,
    private readonly tenantService: TenantService,
    private readonly supportSessions: SupportSessionService,
    private readonly jwt: JwtService,
    private readonly env: Environment,
    private readonly email: EmailService,
  ) {}

  async register(data: {
    email: string;
    password: string;
    name?: string;
    familyName: string;
    slug?: string;
    locale?: TenantLocale;
  }) {
    const existing = await this.users.findByEmail(data.email);
    if (existing) throw new ConflictException('Email já cadastrado');
    const passwordHash = await bcrypt.hash(data.password, 12);
    const user = await this.users.create({
      email: data.email,
      passwordHash,
      name: data.name,
    });
    try {
      await this.tenantService.createForOwner({
        ownerUserId: user.id,
        name: data.familyName,
        slug: data.slug,
        defaultLocale: data.locale,
        status: 'pending_payment',
      });
      return this.accountSession(user);
    } catch (error) {
      await this.users.delete(user.id);
      throw error;
    }
  }

  async validateUser(
    email: string,
    password: string,
  ): Promise<UserEntity | null> {
    const user = await this.users.findByEmail(email);
    if (!user?.passwordHash) return null;
    return (await bcrypt.compare(password, user.passwordHash)) ? user : null;
  }

  findById(id: string): Promise<UserEntity | null> {
    return this.users.findById(id);
  }

  async accountSession(user: UserEntity) {
    return this.sessionResponse(user, 'account');
  }

  async tenantSession(userId: string, tenantSlug: string) {
    const user = await this.users.findById(userId);
    const tenant = await this.tenants.findTenantBySlug(tenantSlug);
    if (!user || !tenant) {
      throw new UnauthorizedException('Família não encontrada.');
    }
    const membership = await this.tenants.findMembership(tenant.id, user.id);
    if (!membership || tenant.status === 'canceled') {
      throw new ForbiddenException('Acesso não autorizado a esta família.');
    }
    return this.sessionResponse(
      this.withMembership(user, membership, tenant, 'tenant'),
      'tenant',
      tenant,
      membership,
    );
  }

  async platformSession(userId: string) {
    const user = await this.users.findById(userId);
    if (!user || user.platformRole !== 'admin') {
      throw new ForbiddenException(
        'Acesso restrito ao administrador da plataforma.',
      );
    }
    return this.sessionResponse(
      { ...user, sessionScope: 'platform' },
      'platform',
    );
  }

  async supportSession(data: {
    actorUserId: string;
    tenantId: string;
    reason: string;
  }) {
    const actor = await this.users.findById(data.actorUserId);
    const tenant = await this.tenants.findTenantById(data.tenantId);
    if (!actor || actor.platformRole !== 'admin' || !tenant) {
      throw new ForbiddenException('Impersonação não autorizada.');
    }
    const effectiveUser = await this.users.findById(tenant.ownerUserId);
    const membership = effectiveUser
      ? await this.tenants.findMembership(tenant.id, effectiveUser.id)
      : null;
    if (!effectiveUser || !membership) {
      throw new BadRequestException('Proprietário da família não encontrado.');
    }
    const support = await this.supportSessions.create({
      actorUserId: actor.id,
      effectiveUserId: effectiveUser.id,
      tenantId: tenant.id,
      reason: data.reason,
    });
    const user = this.withMembership(
      effectiveUser,
      membership,
      tenant,
      'support',
      {
        actorUserId: actor.id,
        actorEmail: actor.email,
        supportSessionId: support.sessionId,
      },
    );
    const payload: AuthJwtPayload = {
      sub: actor.id,
      effectiveSub: effectiveUser.id,
      scope: 'support',
      platformRole: 'admin',
      tenantId: tenant.id,
      membershipId: membership.id,
      supportSessionId: support.sessionId,
    };
    return {
      scope: 'support' as const,
      accessToken: this.sign(payload, '30m'),
      refreshToken: null,
      expiresAt: support.expiresAt,
      supportSessionId: support.sessionId,
      reason: support.reason,
      user: this.publicUser(user),
      tenant,
      memberships: await this.membershipOptions(actor.id),
    };
  }

  async endSupportSession(sessionId: string, actorUserId: string) {
    await this.supportSessions.end(sessionId, actorUserId);
    return this.platformSession(actorUserId);
  }

  async resolvePayload(payload: AuthJwtPayload): Promise<UserEntity | null> {
    if (!payload.sub || payload.type === 'refresh') return null;
    const actor = await this.users.findById(payload.sub);
    if (!actor) return null;
    if (payload.scope === 'account') {
      return { ...actor, sessionScope: 'account' };
    }
    if (payload.scope === 'platform') {
      return actor.platformRole === 'admin'
        ? { ...actor, sessionScope: 'platform' }
        : null;
    }
    if (
      payload.scope === 'tenant' &&
      payload.tenantId &&
      payload.membershipId
    ) {
      return this.findAuthenticatedUser(payload.sub, payload.tenantId);
    }
    if (
      payload.scope === 'support' &&
      payload.tenantId &&
      payload.effectiveSub &&
      payload.supportSessionId
    ) {
      const support = await this.supportSessions.requireActive(
        payload.supportSessionId,
      );
      if (
        support.actorUserId !== payload.sub ||
        support.effectiveUserId !== payload.effectiveSub ||
        support.tenantId !== payload.tenantId
      ) {
        return null;
      }
      const [effectiveUser, tenant, membership] = await Promise.all([
        this.users.findById(payload.effectiveSub),
        this.tenants.findTenantById(payload.tenantId),
        this.tenants.findMembership(payload.tenantId, payload.effectiveSub),
      ]);
      if (!effectiveUser || !tenant || !membership) return null;
      return this.withMembership(
        effectiveUser,
        membership,
        tenant,
        'support',
        {
          actorUserId: actor.id,
          actorEmail: actor.email,
          supportSessionId: payload.supportSessionId,
        },
      );
    }
    return null;
  }

  async findAuthenticatedUser(
    userId: string,
    tenantId: string,
  ): Promise<UserEntity | null> {
    const [user, membership, tenant] = await Promise.all([
      this.users.findById(userId),
      this.tenants.findMembership(tenantId, userId),
      this.tenants.findTenantById(tenantId),
    ]);
    if (!user || !membership || !tenant || tenant.status === 'canceled') {
      return null;
    }
    return this.withMembership(user, membership, tenant, 'tenant');
  }

  async refresh(token: string) {
    if (!token) throw new BadRequestException('Refresh token é obrigatório');
    let payload: AuthJwtPayload;
    try {
      payload = this.jwt.verify<AuthJwtPayload>(token, {
        secret: this.env.jwt.secret,
      });
    } catch {
      throw new UnauthorizedException('Sessão expirada. Faça login novamente.');
    }
    if (payload.type !== 'refresh' || payload.scope === 'support') {
      throw new UnauthorizedException('Refresh token inválido.');
    }
    const user = await this.users.findById(payload.sub);
    if (!user) throw new UnauthorizedException('Sessão inválida.');
    if (payload.scope === 'tenant' && payload.tenantId) {
      const tenant = await this.tenants.findTenantById(payload.tenantId);
      if (!tenant) throw new UnauthorizedException('Família não encontrada.');
      return this.tenantSession(user.id, tenant.slug);
    }
    if (payload.scope === 'platform') return this.platformSession(user.id);
    return this.accountSession(user);
  }

  async sessionFor(user: UserEntity) {
    const tenant = user.tenantId
      ? await this.tenants.findTenantById(user.tenantId)
      : null;
    return {
      scope: user.sessionScope,
      user: this.publicUser(user),
      tenant,
      memberships: await this.membershipOptions(
        user.actorUserId ?? user.id,
      ),
      support: user.supportSessionId
        ? {
            sessionId: user.supportSessionId,
            actorUserId: user.actorUserId,
            actorEmail: user.actorEmail,
          }
        : null,
    };
  }

  updateAvatar(userId: string, avatarPath: string) {
    return this.users.update(userId, { avatarPath });
  }

  updateProfile(userId: string, data: { name?: string }) {
    return this.users.update(userId, { name: data.name?.trim() });
  }

  publicUser(user: UserEntity) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      platformRole: user.platformRole ?? null,
      sessionScope: user.sessionScope,
      role: user.role,
      access: user.access,
      avatarPath: user.avatarPath,
      tenantId: user.tenantId ?? null,
      membershipId: user.membershipId ?? null,
      tenantSlug: user.tenantSlug ?? null,
      actorUserId: user.actorUserId ?? null,
      actorEmail: user.actorEmail ?? null,
      supportSessionId: user.supportSessionId ?? null,
    };
  }

  async requestPasswordReset(email: string): Promise<void> {
    const user = await this.users.findByEmail(email);
    if (!user) return;
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000);
    await this.passwordResets.create({ userId: user.id, token, expiresAt });
    if (this.email.isEnabled) {
      await this.email.sendPasswordReset(user.email, token);
    }
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    const row = await this.passwordResets.findByToken(token);
    if (!row) throw new BadRequestException('Token inválido ou expirado');
    if (row.used) throw new BadRequestException('Token já utilizado');
    if (row.expiresAt < new Date())
      throw new BadRequestException('Token expirado');
    const user = await this.users.findById(row.userId);
    if (!user) throw new BadRequestException('Usuário não encontrado');
    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.users.update(user.id, { passwordHash });
    await this.passwordResets.markUsed(row.id);
  }

  private async sessionResponse(
    user: UserEntity,
    scope: Exclude<SessionScope, 'support'>,
    tenant?: TenantEntity,
    membership?: MembershipEntity,
  ) {
    const payload: AuthJwtPayload = {
      sub: user.id,
      scope,
      platformRole: user.platformRole ?? undefined,
      tenantId: tenant?.id,
      membershipId: membership?.id,
    };
    return {
      scope,
      accessToken: this.sign(payload, this.env.jwt.expiresIn),
      refreshToken: this.sign({ ...payload, type: 'refresh' }, '90d'),
      user: this.publicUser({ ...user, sessionScope: scope }),
      tenant: tenant ?? null,
      memberships: await this.membershipOptions(user.id),
      support: null,
    };
  }

  private sign(payload: AuthJwtPayload, expiresIn: string): string {
    return this.jwt.sign(payload, {
      secret: this.env.jwt.secret,
      expiresIn,
    } as never);
  }

  private async membershipOptions(userId: string) {
    const memberships = await this.tenants.listMembershipsForUser(userId);
    const tenants = await Promise.all(
      memberships.map((row) => this.tenants.findTenantById(row.tenantId)),
    );
    return memberships.flatMap((membership, index) => {
      const tenant = tenants[index];
      return tenant
        ? [
            {
              tenant,
              membership: {
                id: membership.id,
                role: membership.role,
                access: membership.access,
                relationLabel: membership.relationLabel ?? null,
              },
            },
          ]
        : [];
    });
  }

  private withMembership(
    user: UserEntity,
    membership: MembershipEntity,
    tenant: TenantEntity,
    sessionScope: 'tenant' | 'support',
    support?: {
      actorUserId: string;
      actorEmail: string;
      supportSessionId: string;
    },
  ): UserEntity {
    return {
      ...user,
      sessionScope,
      tenantId: tenant.id,
      tenantSlug: tenant.slug,
      membershipId: membership.id,
      role: membership.role,
      access: membership.access,
      actorUserId: support?.actorUserId ?? null,
      actorEmail: support?.actorEmail ?? null,
      supportSessionId: support?.supportSessionId ?? null,
    };
  }
}
