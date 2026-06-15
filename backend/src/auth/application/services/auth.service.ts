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
import { UserRepository } from '../../infrastructure/repositories/user.repository';
import { PasswordResetRepository } from '../../infrastructure/repositories/password-reset.repository';
import type { UserEntity, UserRole } from '@auth/domain/entities/user.entity';

type AuthJwtPayload = {
  sub: string;
  email?: string;
  type?: 'refresh';
};

@Injectable()
export class AuthService {
  constructor(
    private users: UserRepository,
    private passwordResets: PasswordResetRepository,
    private jwt: JwtService,
    private env: Environment,
    private email: EmailService,
  ) {}

  async register(
    email: string,
    password: string,
    name?: string,
    role?: UserRole,
  ) {
    const existing = await this.users.findByEmail(email);
    if (existing) throw new ConflictException('Email já cadastrado');
    const passwordHash = await bcrypt.hash(password, 12);
    const user = await this.users.create({ email, passwordHash, name, role });
    return this.tokenResponse(user);
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

  async updateAvatar(userId: string, avatarPath: string) {
    return this.users.update(userId, { avatarPath });
  }

  tokenResponse(user: UserEntity) {
    const payload = { sub: user.id, email: user.email };
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
      access_token: accessToken,
      refreshToken,
      refresh_token: refreshToken,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        access: user.access,
        avatarPath: user.avatarPath,
      },
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
    const user = await this.users.findById(payload.sub);
    if (!user)
      throw new UnauthorizedException('Sessão expirada. Faça login novamente.');
    return this.tokenResponse(user);
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
    if (newPassword.length < 8)
      throw new BadRequestException('A senha deve ter pelo menos 8 caracteres');
    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.users.update(user.id, { passwordHash });
    await this.passwordResets.markUsed(row.id);
  }
}
