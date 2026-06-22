import { Global, Injectable, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Injectable()
export class Environment {
  type: 'development' | 'production' | 'staging';
  http: { port: number };
  database: { mongo: { uri: string; dbName?: string } };
  jwt: { secret: string; expiresIn: string };
  uploadPath: string;
  cors: { origin: string };
  smtp?: { host: string; port: number; user: string; pass: string };
  emailFrom?: string;
  emailFromName?: string;
  passwordResetUrl?: string;
  firebase?: {
    serviceAccountPath?: string;
    serviceAccountJson?: string;
  };
  redis?: { url: string };
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

  constructor(data: Partial<Environment>) {
    Object.assign(this, data);
  }

  isProduction(): boolean {
    return this.type === 'production';
  }

  isDevelopment(): boolean {
    return this.type === 'development';
  }

  isStaging(): boolean {
    return this.type === 'staging';
  }
}

class EnvironmentFactory {
  static create(config: ConfigService): Environment {
    const uploadPath = required(config, 'UPLOAD_PATH');
    const type = (config.get<string>('NODE_ENV') || 'development') as
      | 'development'
      | 'production'
      | 'staging';
    const stripeSecretKey = config.get<string>('STRIPE_SECRET_KEY');
    const stripeWebhookSecret = config.get<string>('STRIPE_WEBHOOK_SECRET');
    const stripePriceId = config.get<string>('STRIPE_PRICE_ID');
    const smtpHost = config.get<string>('SMTP_HOST');
    const smtpUser = config.get<string>('SMTP_USER');
    const smtpPass = config.get<string>('SMTP_PASS');
    const firebasePath = config.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH');
    const firebaseJson = config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');
    const redisUrl = config.get<string>('REDIS_URL');

    return new Environment({
      type,
      http: { port: number(config, 'PORT', 3000) },
      database: {
        mongo: {
          uri:
            config.get<string>('MONGO_URI') ||
            'mongodb://localhost:27017/my-family',
          dbName: config.get<string>('MONGO_DB') || 'my-family',
        },
      },
      jwt: {
        secret: config.get<string>('JWT_SECRET') || 'change-me',
        expiresIn: config.get<string>('JWT_EXPIRES_IN') || '7d',
      },
      uploadPath,
      cors: { origin: config.get<string>('CORS_ORIGIN') || '*' },
      smtp:
        smtpHost && smtpUser && smtpPass
          ? {
              host: smtpHost,
              port: number(config, 'SMTP_PORT', 587),
              user: smtpUser,
              pass: smtpPass,
            }
          : undefined,
      emailFrom: config.get<string>('EMAIL_FROM'),
      emailFromName: config.get<string>('EMAIL_FROM_NAME') || 'Nossa Família',
      passwordResetUrl: config.get<string>('PASSWORD_RESET_URL') || '',
      firebase:
        firebasePath || firebaseJson
          ? {
              serviceAccountPath: firebasePath,
              serviceAccountJson: firebaseJson,
            }
          : undefined,
      redis: redisUrl ? { url: redisUrl } : undefined,
      security: {
        throttleTtlMs: positive(config, 'THROTTLE_TTL_MS'),
        throttleLimit: positive(config, 'THROTTLE_LIMIT'),
        csrfSecret: required(config, 'CSRF_SECRET'),
      },
      billing:
        stripeSecretKey && stripeWebhookSecret && stripePriceId
          ? {
              stripeSecretKey,
              stripeWebhookSecret,
              stripePriceId,
              successUrl:
                config.get<string>('BILLING_SUCCESS_URL') ||
                'http://localhost:3458/app/billing',
              cancelUrl:
                config.get<string>('BILLING_CANCEL_URL') ||
                'http://localhost:3458/app/billing',
            }
          : undefined,
    });
  }
}

function required(config: ConfigService, name: string): string {
  const value = config.get<string>(name);
  if (!value) throw new Error(`${name} é obrigatório`);
  return value;
}

function positive(config: ConfigService, name: string): number {
  const value = Number(required(config, name));
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`${name} deve ser um número positivo`);
  }
  return value;
}

function number(config: ConfigService, name: string, fallback: number): number {
  const raw = config.get<string>(name);
  if (!raw) return fallback;
  const value = Number(raw);
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`${name} deve ser um número positivo`);
  }
  return value;
}

@Global()
@Module({})
export class EnvironmentModule {
  static forRoot() {
    const environment = {
      provide: Environment,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => EnvironmentFactory.create(config),
    };

    return {
      module: EnvironmentModule,
      imports: [ConfigModule.forRoot({ isGlobal: true })],
      providers: [environment],
      exports: [environment],
    };
  }
}
