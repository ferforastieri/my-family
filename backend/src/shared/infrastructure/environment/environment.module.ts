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
  r2?: {
    accountId: string;
    accessKeyId: string;
    secretAccessKey: string;
    bucket: string;
    mediaBaseUrl?: string;
    signingSecret?: string;
  };
  cors: {
    origin: string;
  };
  invitationUrl?: string;
  turnstileSecret?: string;
  phoneAuth: {
    hashSecret: string;
    defaultCountryCode: string;
    platformAdminPhone?: string;
    whatsapp?: {
      accessToken: string;
      phoneNumberId: string;
      apiVersion: string;
      otpTemplate: string;
      invitationTemplate?: string;
    };
    sms?: {
      accountSid: string;
      authToken: string;
      from: string;
    };
  };
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
    trustProxyHops: number;
  };
  cookies: {
    secure: boolean;
    sameSite: 'lax' | 'strict' | 'none';
    domain?: string;
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
    const nodeEnv =
      ((process.env.NODE_ENV || output.parsed?.NODE_ENV) as
        | 'development'
        | 'production'
        | 'staging') || 'development';
    const jwtSecret = readEnv('JWT_SECRET', output.parsed);
    const phoneOtpSecret = readEnv('PHONE_OTP_SECRET', output.parsed);
    const corsOrigin = readEnv('CORS_ORIGIN', output.parsed);
    const redisUrl = process.env.REDIS_URL || output.parsed?.REDIS_URL;
    const trustProxyHops = readNonNegativeNumberEnv(
      'TRUST_PROXY_HOPS',
      output.parsed,
      nodeEnv === 'production' ? undefined : 0,
    );
    const cookieSecure = readBooleanEnv(
      'COOKIE_SECURE',
      output.parsed,
      nodeEnv === 'production',
    );
    const cookieSameSite = readCookieSameSite(output.parsed);
    const cookieDomain =
      process.env.COOKIE_DOMAIN || output.parsed?.COOKIE_DOMAIN || undefined;
    if (nodeEnv === 'production') {
      assertStrongSecret('JWT_SECRET', jwtSecret);
      assertStrongSecret('PHONE_OTP_SECRET', phoneOtpSecret);
      if (corsOrigin.trim() === '*')
        throw new Error('CORS_ORIGIN não pode ser * em produção');
      if (!redisUrl)
        throw new Error('REDIS_URL é obrigatório em produção para rate limit');
      if (!(process.env.TURNSTILE_SECRET || output.parsed?.TURNSTILE_SECRET))
        throw new Error('TURNSTILE_SECRET é obrigatório em produção');
      if (!cookieSecure)
        throw new Error('COOKIE_SECURE deve ser true em produção');
      if (!cookieDomain || !/^\.?[a-z0-9.-]+$/i.test(cookieDomain))
        throw new Error('COOKIE_DOMAIN é obrigatório e deve ser um domínio');
      const mediaBaseUrl =
        process.env.MEDIA_BASE_URL || output.parsed?.MEDIA_BASE_URL;
      const mediaSigningSecret =
        process.env.MEDIA_SIGNING_SECRET || output.parsed?.MEDIA_SIGNING_SECRET;
      if (mediaBaseUrl) {
        assertStrongSecret('MEDIA_SIGNING_SECRET', mediaSigningSecret ?? '');
      }
    }

    return new Environment({
      type: nodeEnv,
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
        secret: jwtSecret,
        expiresIn:
          process.env.JWT_EXPIRES_IN || output.parsed?.JWT_EXPIRES_IN || '15m',
      },
      uploadPath,
      r2:
        (process.env.R2_ACCOUNT_ID || output.parsed?.R2_ACCOUNT_ID) &&
        (process.env.R2_ACCESS_KEY_ID || output.parsed?.R2_ACCESS_KEY_ID) &&
        (process.env.R2_SECRET_ACCESS_KEY ||
          output.parsed?.R2_SECRET_ACCESS_KEY) &&
        (process.env.R2_MEDIA_BUCKET || output.parsed?.R2_MEDIA_BUCKET)
          ? {
              accountId:
                process.env.R2_ACCOUNT_ID || output.parsed.R2_ACCOUNT_ID,
              accessKeyId:
                process.env.R2_ACCESS_KEY_ID || output.parsed.R2_ACCESS_KEY_ID,
              secretAccessKey:
                process.env.R2_SECRET_ACCESS_KEY ||
                output.parsed.R2_SECRET_ACCESS_KEY,
              bucket:
                process.env.R2_MEDIA_BUCKET || output.parsed.R2_MEDIA_BUCKET,
              mediaBaseUrl:
                process.env.MEDIA_BASE_URL || output.parsed?.MEDIA_BASE_URL,
              signingSecret:
                process.env.MEDIA_SIGNING_SECRET ||
                output.parsed?.MEDIA_SIGNING_SECRET,
            }
          : undefined,
      cors: {
        origin: corsOrigin,
      },
      invitationUrl:
        process.env.INVITATION_URL || output.parsed?.INVITATION_URL || '',
      turnstileSecret:
        process.env.TURNSTILE_SECRET || output.parsed?.TURNSTILE_SECRET,
      phoneAuth: {
        hashSecret: phoneOtpSecret,
        defaultCountryCode:
          process.env.DEFAULT_PHONE_COUNTRY_CODE ||
          output.parsed?.DEFAULT_PHONE_COUNTRY_CODE ||
          '55',
        platformAdminPhone:
          process.env.PLATFORM_ADMIN_PHONE ||
          output.parsed?.PLATFORM_ADMIN_PHONE,
        whatsapp:
          (process.env.WHATSAPP_ACCESS_TOKEN ||
            output.parsed?.WHATSAPP_ACCESS_TOKEN) &&
          (process.env.WHATSAPP_PHONE_NUMBER_ID ||
            output.parsed?.WHATSAPP_PHONE_NUMBER_ID) &&
          (process.env.WHATSAPP_OTP_TEMPLATE ||
            output.parsed?.WHATSAPP_OTP_TEMPLATE)
            ? {
                accessToken:
                  process.env.WHATSAPP_ACCESS_TOKEN ||
                  output.parsed.WHATSAPP_ACCESS_TOKEN,
                phoneNumberId:
                  process.env.WHATSAPP_PHONE_NUMBER_ID ||
                  output.parsed.WHATSAPP_PHONE_NUMBER_ID,
                apiVersion:
                  process.env.WHATSAPP_API_VERSION ||
                  output.parsed?.WHATSAPP_API_VERSION ||
                  'v23.0',
                otpTemplate:
                  process.env.WHATSAPP_OTP_TEMPLATE ||
                  output.parsed.WHATSAPP_OTP_TEMPLATE,
                invitationTemplate:
                  process.env.WHATSAPP_INVITATION_TEMPLATE ||
                  output.parsed?.WHATSAPP_INVITATION_TEMPLATE,
              }
            : undefined,
        sms:
          (process.env.TWILIO_ACCOUNT_SID ||
            output.parsed?.TWILIO_ACCOUNT_SID) &&
          (process.env.TWILIO_AUTH_TOKEN || output.parsed?.TWILIO_AUTH_TOKEN) &&
          (process.env.TWILIO_FROM_NUMBER || output.parsed?.TWILIO_FROM_NUMBER)
            ? {
                accountSid:
                  process.env.TWILIO_ACCOUNT_SID ||
                  output.parsed.TWILIO_ACCOUNT_SID,
                authToken:
                  process.env.TWILIO_AUTH_TOKEN ||
                  output.parsed.TWILIO_AUTH_TOKEN,
                from:
                  process.env.TWILIO_FROM_NUMBER ||
                  output.parsed.TWILIO_FROM_NUMBER,
              }
            : undefined,
      },
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
      redis: redisUrl ? { url: redisUrl } : undefined,
      log: {
        level: logLevel,
      },
      security: {
        throttleTtlMs,
        throttleLimit,
        trustProxyHops,
      },
      cookies: {
        secure: cookieSecure,
        sameSite: cookieSameSite,
        domain: cookieDomain,
      },
    });
  }
}

function readBooleanEnv(
  name: string,
  parsed: Record<string, string> | undefined,
  fallback: boolean,
): boolean {
  const value = process.env[name] ?? parsed?.[name];
  if (value == null || value === '') return fallback;
  if (value === 'true') return true;
  if (value === 'false') return false;
  throw new Error(`${name} deve ser true ou false`);
}

function readCookieSameSite(
  parsed?: Record<string, string>,
): 'lax' | 'strict' | 'none' {
  const value = (
    process.env.COOKIE_SAME_SITE ??
    parsed?.COOKIE_SAME_SITE ??
    'lax'
  )
    .trim()
    .toLowerCase();
  if (value === 'lax' || value === 'strict' || value === 'none') return value;
  throw new Error('COOKIE_SAME_SITE deve ser lax, strict ou none');
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

function readNonNegativeNumberEnv(
  name: string,
  parsed: Record<string, string> | undefined,
  fallback?: number,
): number {
  const raw = process.env[name] || parsed?.[name];
  if (!raw && fallback !== undefined) return fallback;
  const value = Number(raw);
  if (!Number.isInteger(value) || value < 0) {
    throw new Error(`${name} deve ser um número inteiro não negativo`);
  }
  return value;
}

function assertStrongSecret(name: string, value: string): void {
  if (value.length < 32 || /^(change-me|replace|gere-|secret)/i.test(value)) {
    throw new Error(`${name} deve ter pelo menos 32 caracteres aleatórios`);
  }
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
