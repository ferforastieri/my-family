import { Injectable, Inject } from '@nestjs/common';
import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { DATABASE_CONNECTION } from '@shared/infrastructure/database/database.module';
import { NodePgDatabase } from 'drizzle-orm/node-postgres';

@Injectable()
export class AuthService {
  private auth: ReturnType<typeof betterAuth>;

  constructor(
    @Inject(DATABASE_CONNECTION)
    private db: NodePgDatabase<typeof import('@shared/infrastructure/database/schema')>,
    private env: Environment,
  ) {
    this.auth = betterAuth({
      database: drizzleAdapter(this.db, {
        provider: 'pg',
      }),
      secret: env.betterAuth.secret,
      baseURL: env.betterAuth.url,
      emailAndPassword: {
        enabled: true,
      },
    });
  }

  getAuth() {
    return this.auth;
  }
}

