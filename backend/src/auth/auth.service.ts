import { Injectable, Inject, ConflictException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomBytes } from 'crypto';
import { DATABASE_CONNECTION } from '@shared/infrastructure/database/database.module';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { users, passwordResets, User, NewUser, UserRole } from '@shared/infrastructure/database/schema';
import { eq } from 'drizzle-orm';
import * as bcrypt from 'bcrypt';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { EmailService } from '@shared/infrastructure/email/email.service';

@Injectable()
export class AuthService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private db: NodePgDatabase<typeof import('@shared/infrastructure/database/schema')>,
    private jwt: JwtService,
    private env: Environment,
    private email: EmailService,
  ) {}

  async register(email: string, password: string, name?: string, role?: UserRole) {
    const existing = await this.db.select().from(users).where(eq(users.email, email)).limit(1);
    if (existing.length) throw new ConflictException('Email já cadastrado');
    const passwordHash = await bcrypt.hash(password, 12);
    const [user] = await this.db.insert(users).values({ email, passwordHash, name, role } as NewUser).returning();
    return this.tokenResponse(user);
  }

  async validateUser(email: string, password: string): Promise<User | null> {
    const [user] = await this.db.select().from(users).where(eq(users.email, email)).limit(1);
    if (!user?.passwordHash) return null;
    const ok = await bcrypt.compare(password, user.passwordHash);
    return ok ? user : null;
  }

  async findById(id: number): Promise<User | null> {
    const [user] = await this.db.select().from(users).where(eq(users.id, id)).limit(1);
    return user ?? null;
  }

  async updateAvatar(userId: number, avatarPath: string) {
    const [updated] = await this.db
      .update(users)
      .set({ avatarPath, updatedAt: new Date() } as any)
      .where(eq(users.id, userId))
      .returning();
    return updated ?? null;
  }

  tokenResponse(user: User) {
    const payload = { sub: user.id, email: user.email };
    const access_token = this.jwt.sign(payload, {
      secret: this.env.jwt.secret,
      expiresIn: this.env.jwt.expiresIn,
    } as any);
    return {
      access_token,
      user: { id: user.id, email: user.email, name: user.name, role: user.role, avatarPath: user.avatarPath },
    };
  }

  async requestPasswordReset(email: string): Promise<void> {
    const [user] = await this.db.select().from(users).where(eq(users.email, email)).limit(1);
    if (!user) return;
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1);
    await this.db.insert(passwordResets).values({
      userId: user.id,
      token,
      expiresAt,
    });
    if (this.email.isEnabled) {
      await this.email.sendPasswordReset(user.email, token);
    }
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    const [row] = await this.db.select().from(passwordResets).where(eq(passwordResets.token, token)).limit(1);
    if (!row) throw new BadRequestException('Token inválido ou expirado');
    if (row.used) throw new BadRequestException('Token já utilizado');
    if (row.expiresAt < new Date()) throw new BadRequestException('Token expirado');
    const [user] = await this.db.select().from(users).where(eq(users.id, row.userId)).limit(1);
    if (!user) throw new BadRequestException('Usuário não encontrado');
    if (newPassword.length < 8) throw new BadRequestException('A senha deve ter pelo menos 8 caracteres');
    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.db.update(users).set({ passwordHash, updatedAt: new Date() } as any).where(eq(users.id, user.id));
    await this.db.update(passwordResets).set({ used: new Date() } as Record<string, unknown>).where(eq(passwordResets.id, row.id));
  }
}
