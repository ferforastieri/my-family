import { Global, Injectable, Module } from '@nestjs/common';
import { configDotenv } from 'dotenv';

@Injectable()
export class Environment {
  type: 'development' | 'production' | 'staging';
  http: {
    port: number;
  };
  database: {
    mongo: {
      uri: string;
      dbName?: string;
    };
  };
  jwt: {
    secret: string;
    expiresIn: string;
  };
  uploadPath: string;
  cors: {
    origin: string;
  };
  smtp?: {
    host: string;
    port: number;
    user: string;
    pass: string;
  };
  emailFrom?: string;
  emailFromName?: string;
  passwordResetUrl?: string;
  firebase?: {
    serviceAccountPath?: string;
    serviceAccountJson?: string;
  };
  redis?: { url: string };
  log: {
    level: string;
  };
  security: {
    throttleTtlMs: number;
    throttleLimit: number;
    csrfSecret: string;
  };
  billing?: {
    stripeSecretKey: string;
    stripeWebhookSecret: string;
    stripePriceId: string;
    successUrl: string;
    cancelUrl: string;
  };

  isProduction(): boolean {
    return this.type === 'production';
  }

  isDevelopment(): boolean {
    return this.type === 'development';
  }

  isStaging(): boolean {
    return this.type === 'staging';
  }

  constructor(data: Partial<Environment>) {
    Object.assign(this, data);
  }
}

class EnvironmentFactory {
  static createFromEnv(path = '.env'): Environment {
    const output = configDotenv({
      path,
    });
    const uploadPath = process.env.UPLOAD_PATH || output.parsed?.UPLOAD_PATH;
    if (!uploadPath) {
      throw new Error('UPLOAD_PATH é obrigatório');
    }
    const logLevel = readEnv('LOG_LEVEL', output.parsed);
    const throttleTtlMs = readNumberEnv('THROTTLE_TTL_MS', output.parsed);
    const throttleLimit = readNumberEnv('THROTTLE_LIMIT', output.parsed);
    const csrfSecret = readEnv('CSRF_SECRET', output.parsed);

    return new Environment({
      type:
        ((process.env.NODE_ENV || output.parsed?.NODE_ENV) as
          | 'development'
          | 'production'
          | 'staging') || 'development',
      http: {
        port: +(process.env.PORT || output.parsed?.PORT || 3000),
      },
      database: {
        mongo: {
          uri:
            process.env.MONGO_URI ||
            output.parsed?.MONGO_URI ||
            'mongodb://localhost:27017/my-family',
          dbName:
            process.env.MONGO_DB || output.parsed?.MONGO_DB || 'my-family',
        },
      },
      jwt: {
        secret:
          process.env.JWT_SECRET || output.parsed?.JWT_SECRET || 'change-me',
        expiresIn:
          process.env.JWT_EXPIRES_IN || output.parsed?.JWT_EXPIRES_IN || '7d',
      },
      uploadPath,
      cors: {
        origin: process.env.CORS_ORIGIN || output.parsed?.CORS_ORIGIN || '*',
      },
      smtp:
        (process.env.SMTP_HOST || output.parsed?.SMTP_HOST) &&
        (process.env.SMTP_USER || output.parsed?.SMTP_USER) &&
        (process.env.SMTP_PASS || output.parsed?.SMTP_PASS)
          ? {
              host: process.env.SMTP_HOST || output.parsed!.SMTP_HOST,
              port: +(
                process.env.SMTP_PORT ||
                output.parsed?.SMTP_PORT ||
                '587'
              ),
              user: process.env.SMTP_USER || output.parsed!.SMTP_USER,
              pass: process.env.SMTP_PASS || output.parsed!.SMTP_PASS,
            }
          : undefined,
      emailFrom: process.env.EMAIL_FROM || output.parsed?.EMAIL_FROM,
      emailFromName:
        process.env.EMAIL_FROM_NAME ||
        output.parsed?.EMAIL_FROM_NAME ||
        'Nossa Família',
      passwordResetUrl:
        process.env.PASSWORD_RESET_URL ||
        output.parsed?.PASSWORD_RESET_URL ||
        '',
      firebase:
        process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
        output.parsed?.FIREBASE_SERVICE_ACCOUNT_PATH ||
        process.env.FIREBASE_SERVICE_ACCOUNT_JSON ||
        output.parsed?.FIREBASE_SERVICE_ACCOUNT_JSON
          ? {
              serviceAccountPath:
                process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
                output.parsed?.FIREBASE_SERVICE_ACCOUNT_PATH,
              serviceAccountJson:
                process.env.FIREBASE_SERVICE_ACCOUNT_JSON ||
                output.parsed?.FIREBASE_SERVICE_ACCOUNT_JSON,
            }
          : undefined,
      redis:
        process.env.REDIS_URL || output.parsed?.REDIS_URL
          ? { url: process.env.REDIS_URL || output.parsed?.REDIS_URL! }
          : undefined,
      log: {
        level: logLevel,
      },
      security: {
        throttleTtlMs,
        throttleLimit,
        csrfSecret,
      },
      billing:
        readOptionalEnv('STRIPE_SECRET_KEY', output.parsed) &&
        readOptionalEnv('STRIPE_WEBHOOK_SECRET', output.parsed) &&
        readOptionalEnv('STRIPE_PRICE_ID', output.parsed)
          ? {
              stripeSecretKey: readOptionalEnv(
                'STRIPE_SECRET_KEY',
                output.parsed,
              )!,
              stripeWebhookSecret: readOptionalEnv(
                'STRIPE_WEBHOOK_SECRET',
                output.parsed,
              )!,
              stripePriceId: readOptionalEnv('STRIPE_PRICE_ID', output.parsed)!,
              successUrl:
                readOptionalEnv('BILLING_SUCCESS_URL', output.parsed) ||
                'http://localhost:3458/app/billing',
              cancelUrl:
                readOptionalEnv('BILLING_CANCEL_URL', output.parsed) ||
                'http://localhost:3458/app/billing',
            }
          : undefined,
    });
  }
}

function readEnv(name: string, parsed?: Record<string, string>): string {
  const value = process.env[name] || parsed?.[name];
  if (!value) {
    throw new Error(`${name} é obrigatório`);
  }
  return value;
}

function readNumberEnv(name: string, parsed?: Record<string, string>): number {
  const value = Number(readEnv(name, parsed));
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`${name} deve ser um número positivo`);
  }
  return value;
}

function readOptionalEnv(
  name: string,
  parsed?: Record<string, string>,
): string | undefined {
  return process.env[name] || parsed?.[name] || undefined;
}

@Global()
@Module({})
export class EnvironmentModule {
  static forRoot() {
    const environment = {
      provide: Environment,
      useFactory: () => {
        const env = EnvironmentFactory.createFromEnv();
        return env;
      },
    };

    return {
      module: EnvironmentModule,
      providers: [environment],
      exports: [environment],
    };
  }
}
