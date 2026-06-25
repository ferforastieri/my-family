import {
  Injectable,
  ConflictException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomBytes } from 'crypto';
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
import { UserRepository } from '../../infrastructure/repositories/user.repository';
import { PasswordResetRepository } from '../../infrastructure/repositories/password-reset.repository';
import type { UserEntity } from '@auth/domain/entities/user.entity';

type AuthJwtPayload = {
  sub: string;
  tenantId: string;
  membershipId: string;
  type?: 'refresh';
};

@Injectable()
export class AuthService {
  constructor(
    private users: UserRepository,
    private passwordResets: PasswordResetRepository,
    private tenants: TenantRepository,
    private tenantService: TenantService,
    private jwt: JwtService,
    private env: Environment,
    private email: EmailService,
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
      const { tenant, membership } = await this.tenantService.createForOwner({
        ownerUserId: user.id,
        name: data.familyName,
        slug: data.slug,
        defaultLocale: data.locale,
        status: 'pending_payment',
      });
      return this.tokenResponse(user, membership, tenant);
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
    const ok = await bcrypt.compare(password, user.passwordHash);
    return ok ? user : null;
  }

  async findById(id: string): Promise<UserEntity | null> {
    return this.users.findById(id);
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
    return this.withMembership(user, membership, tenant);
  }

  async updateAvatar(userId: string, avatarPath: string) {
    return this.users.update(userId, { avatarPath });
  }

  async updateProfile(userId: string, data: { name?: string }) {
    return this.users.update(userId, { name: data.name?.trim() });
  }

  async tokenResponse(
    user: UserEntity,
    membership?: MembershipEntity,
    tenant?: TenantEntity,
    tenantSlug?: string,
  ) {
    if (!membership || !tenant) {
      const session = await this.resolveSession(user.id, tenantSlug);
      membership = session.membership;
      tenant = session.tenant;
    }
    const authenticatedUser = this.withMembership(user, membership, tenant);
    const payload = {
      sub: user.id,
      tenantId: tenant.id,
      membershipId: membership.id,
    };
    const accessToken = this.jwt.sign(payload, {
      secret: this.env.jwt.secret,
      expiresIn: this.env.jwt.expiresIn,
    } as any);
    const refreshToken = this.jwt.sign({ ...payload, type: 'refresh' }, {
      secret: this.env.jwt.secret,
      expiresIn: '90d',
    } as any);
    return {
      accessToken,
      refreshToken,
      user: this.publicUser(authenticatedUser),
      tenant,
    };
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
    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Refresh token inválido.');
    }
    const user = await this.users.findById(payload.sub);
    const membership = await this.tenants.findMembership(
      payload.tenantId,
      payload.sub,
    );
    const tenant = await this.tenants.findTenantById(payload.tenantId);
    if (!user || !membership || !tenant || tenant.status === 'canceled') {
      throw new UnauthorizedException('Sessão expirada. Faça login novamente.');
    }
    return this.tokenResponse(user, membership, tenant);
  }

  publicUser(user: UserEntity) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      platformRole: user.platformRole ?? null,
      role: user.role,
      access: user.access,
      avatarPath: user.avatarPath,
      tenantId: user.tenantId,
      tenantSlug: user.tenantSlug,
    };
  }

  async requestPasswordReset(email: string): Promise<void> {
    const user = await this.users.findByEmail(email);
    if (!user) return;
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1);
    await this.passwordResets.create({
      userId: user.id,
      token,
      expiresAt,
    });
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
    if (newPassword.length < 8) {
      throw new BadRequestException('A senha deve ter pelo menos 8 caracteres');
    }
    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.users.update(user.id, { passwordHash });
    await this.passwordResets.markUsed(row.id);
  }

  private async resolveSession(userId: string, slug?: string) {
    const memberships = await this.tenants.listMembershipsForUser(userId);
    if (!memberships.length) {
      throw new UnauthorizedException(
        'Usuário não pertence a nenhuma família.',
      );
    }
    if (slug) {
      const tenant = await this.tenants.findTenantBySlug(slug);
      const membership = tenant
        ? memberships.find((row) => row.tenantId === tenant.id)
        : undefined;
      if (!tenant || !membership) {
        throw new UnauthorizedException(
          'Acesso não autorizado a esta família.',
        );
      }
      return { tenant, membership };
    }
    const membership = memberships[0];
    const tenant = await this.tenants.findTenantById(membership.tenantId);
    if (!tenant) throw new UnauthorizedException('Família não encontrada.');
    return { tenant, membership };
  }

  private withMembership(
    user: UserEntity,
    membership: MembershipEntity,
    tenant: TenantEntity,
  ): UserEntity {
    return {
      ...user,
      tenantId: tenant.id,
      tenantSlug: tenant.slug,
      membershipId: membership.id,
      role: membership.role,
      access: membership.access,
    };
  }
}
