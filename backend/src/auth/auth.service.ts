import { Injectable, Inject, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { DATABASE_CONNECTION } from '@shared/infrastructure/database/database.module';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';
import { users, User, NewUser } from '@shared/infrastructure/database/schema';
import { eq } from 'drizzle-orm';
import * as bcrypt from 'bcrypt';
import { Environment } from '@shared/infrastructure/environment/environment.module';

@Injectable()
export class AuthService {
  constructor(
    @Inject(DATABASE_CONNECTION)
    private db: NodePgDatabase<typeof import('@shared/infrastructure/database/schema')>,
    private jwt: JwtService,
    private env: Environment,
  ) {}

  async register(email: string, password: string, name?: string) {
    const existing = await this.db.select().from(users).where(eq(users.email, email)).limit(1);
    if (existing.length) throw new ConflictException('Email já cadastrado');
    const passwordHash = await bcrypt.hash(password, 12);
    const [user] = await this.db.insert(users).values({ email, passwordHash, name } as NewUser).returning();
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

  tokenResponse(user: User) {
    const payload = { sub: user.id, email: user.email };
    const access_token = this.jwt.sign(payload, {
      secret: this.env.jwt.secret,
      expiresIn: this.env.jwt.expiresIn,
    } as any);
    return {
      access_token,
      user: { id: user.id, email: user.email, name: user.name },
    };
  }
}
