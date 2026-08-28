import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  createHmac,
  randomBytes,
  randomInt,
  timingSafeEqual,
} from 'node:crypto';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { UserRepository } from '../../infrastructure/repositories/user.repository';
import { PhoneChallengeRepository } from '../../infrastructure/repositories/phone-challenge.repository';
import type { UserEntity } from '@auth/domain/entities/user.entity';
import { TenancyRepository } from '@tenancy/infrastructure/tenancy.repository';
import {
  TenancyService,
  hashToken,
} from '@tenancy/application/tenancy.service';
import {
  PhoneMessagingService,
  type PhoneChannel,
} from './phone-messaging.service';

@Injectable()
export class AuthService {
  constructor(
    private users: UserRepository,
    private challenges: PhoneChallengeRepository,
    private jwt: JwtService,
    private env: Environment,
    private messaging: PhoneMessagingService,
    private tenancy: TenancyService,
    private tenancyRepo: TenancyRepository,
  ) {}

  normalizePhoneNumber(value: string) {
    const raw = value?.trim() ?? '';
    let digits = raw.replace(/\D/g, '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (
      !raw.startsWith('+') &&
      (digits.length === 10 || digits.length === 11)
    ) {
      digits = `${this.env.phoneAuth.defaultCountryCode}${digits}`;
    }
    if (!/^[1-9]\d{9,14}$/.test(digits)) {
      throw new BadRequestException(
        'Número inválido. Informe DDD e celular, ou use o formato internacional.',
      );
    }
    return `+${digits}`;
  }

  async requestCode(phone: string, channel: PhoneChannel) {
    const phoneNumber = this.normalizePhoneNumber(phone);
    const code = randomInt(100000, 1000000).toString();
    await this.challenges.replace({
      phoneNumber,
      codeHash: this.hashOtp(phoneNumber, code),
      channel,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    });

    if (this.messaging.isConfigured(channel)) {
      await this.messaging.sendOtp(phoneNumber, code, channel);
      return { phoneNumber, expiresIn: 300 };
    }
    if (!this.env.isProduction()) {
      return { phoneNumber, expiresIn: 300, devCode: code };
    }
    await this.messaging.sendOtp(phoneNumber, code, channel);
    return { phoneNumber, expiresIn: 300 };
  }

  async authenticateWithCode(input: {
    phone: string;
    code: string;
    invitationToken?: string;
    tenantSlug?: string;
    userAgent?: string;
  }) {
    const phoneNumber = this.normalizePhoneNumber(input.phone);
    let user = await this.users.findByPhoneNumber(phoneNumber);
    await this.verifyCode(phoneNumber, input.code);

    if (!user) {
      user = await this.createUser(phoneNumber);
      try {
        if (input.invitationToken) {
          const tenant = await this.tenancy.acceptInvitation(
            user.id,
            input.invitationToken,
          );
          return this.tokenResponse(user, tenant?.id, input.userAgent);
        }
        const tenant = await this.tenancy.createFamily(
          user.id,
          'Minha Família',
          `familia-${randomBytes(5).toString('hex')}`,
        );
        return this.tokenResponse(user, tenant.id, input.userAgent);
      } catch (error) {
        await this.users.delete(user.id);
        throw error;
      }
    }

    if (input.invitationToken) {
      const tenant = await this.tenancy.acceptInvitation(
        user.id,
        input.invitationToken,
      );
      return this.tokenResponse(user, tenant?.id, input.userAgent);
    }
    const tenantId = await this.tenantIdForSlug(user.id, input.tenantSlug);
    return this.tokenResponse(user, tenantId, input.userAgent);
  }

  private async createUser(phoneNumber: string) {
    if (await this.users.findByPhoneNumber(phoneNumber)) {
      throw new ConflictException('Celular já cadastrado.');
    }
    const configuredAdmin = this.env.phoneAuth.platformAdminPhone
      ? this.normalizePhoneNumber(this.env.phoneAuth.platformAdminPhone)
      : undefined;
    return this.users.create({
      phoneNumber,
      role: 'friends',
      ...(configuredAdmin === phoneNumber
        ? { platformRole: 'super_admin' as const }
        : {}),
    });
  }

  private async verifyCode(phoneNumber: string, code: string) {
    if (!/^\d{6}$/.test(code)) {
      throw new UnauthorizedException('Código inválido ou expirado.');
    }
    const challenge = await this.challenges.findActive(phoneNumber);
    if (!challenge) {
      throw new UnauthorizedException('Código inválido ou expirado.');
    }
    const expected = Buffer.from(challenge.codeHash, 'hex');
    const received = Buffer.from(this.hashOtp(phoneNumber, code), 'hex');
    if (
      expected.length !== received.length ||
      !timingSafeEqual(expected, received)
    ) {
      await this.challenges.registerFailure(String(challenge._id));
      throw new UnauthorizedException('Código inválido ou expirado.');
    }
    const consumed = await this.challenges.consume(String(challenge._id));
    if (consumed.modifiedCount !== 1) {
      throw new UnauthorizedException('Código inválido ou expirado.');
    }
  }

  private hashOtp(phoneNumber: string, code: string) {
    return createHmac('sha256', this.env.phoneAuth.hashSecret)
      .update(`${phoneNumber}:${code}`)
      .digest('hex');
  }

  async findById(id: string): Promise<UserEntity | null> {
    return this.users.findById(id);
  }

  listTenants(userId: string) {
    return this.tenancy.membershipsForUser(userId);
  }

  tenantPrincipal(userId: string, tenantId: string) {
    return this.tenancy.principal(userId, tenantId);
  }

  async tenantIdForSlug(userId: string, slug?: string) {
    if (!slug) return undefined;
    const tenant = await this.tenancyRepo.findTenantBySlug(slug);
    if (!tenant) throw new UnauthorizedException('Família não encontrada.');
    await this.tenancy.principal(userId, tenant.id);
    return tenant.id;
  }

  async updateAvatar(userId: string, avatarPath: string) {
    return this.users.update(userId, { avatarPath });
  }

  async updateProfile(userId: string, data: { name?: string }) {
    return this.users.update(userId, { name: data.name?.trim() });
  }

  async tokenResponse(user: UserEntity, tenantId?: string, userAgent?: string) {
    const memberships = await this.tenancy.membershipsForUser(user.id);
    const selectedTenantId =
      tenantId ?? (memberships.length === 1 ? memberships[0].id : undefined);
    const principal = selectedTenantId
      ? await this.tenancy.principal(user.id, selectedTenantId)
      : null;
    const accessToken = this.jwt.sign(
      {
        sub: user.id,
        ...(selectedTenantId ? { tenantId: selectedTenantId } : {}),
      },
      {
        secret: this.env.jwt.secret,
        algorithm: 'HS256',
        issuer: 'nossa-familia-api',
        audience: 'nossa-familia-app',
        expiresIn: this.env.jwt.expiresIn,
      } as never,
    );
    const refreshToken = randomBytes(48).toString('base64url');
    await this.tenancyRepo.createSession({
      userId: user.id,
      tokenHash: hashToken(refreshToken),
      tenantId: selectedTenantId,
      userAgent,
      expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    });
    return {
      accessToken,
      refreshToken,
      user: principal ?? {
        id: user.id,
        phoneNumber: user.phoneNumber,
        name: user.name,
        role: user.role,
        access: user.access,
        avatarPath: user.avatarPath,
        platformRole: user.platformRole,
      },
      tenant: principal?.tenant ?? null,
      tenants: memberships,
    };
  }

  async refresh(token: string, userAgent?: string) {
    if (!token) throw new BadRequestException('Refresh token é obrigatório');
    const tokenHash = hashToken(token);
    const session = await this.tenancyRepo.consumeSession(tokenHash);
    if (!session) {
      throw new UnauthorizedException('Sessão expirada. Entre novamente.');
    }
    const user = await this.users.findById(session.userId);
    if (!user)
      throw new UnauthorizedException('Sessão expirada. Entre novamente.');
    return this.tokenResponse(user, session.tenantId, userAgent);
  }

  async logout(refreshToken: string) {
    if (refreshToken) {
      await this.tenancyRepo.revokeSession(hashToken(refreshToken));
    }
  }

  async switchTenant(userId: string, tenantId: string, userAgent?: string) {
    const user = await this.users.findById(userId);
    if (!user) throw new UnauthorizedException();
    await this.tenancy.principal(userId, tenantId);
    return this.tokenResponse(user, tenantId, userAgent);
  }
}
