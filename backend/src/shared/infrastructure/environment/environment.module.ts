import { Global, Injectable, Module } from '@nestjs/common';
import { configDotenv } from 'dotenv';

@Injectable()
export class Environment {
  type: 'development' | 'production' | 'staging';
  http: {
    port: number;
  };
  database: {
    postgres: {
      url: string;
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
  vapidPublicKey?: string;
  vapidPrivateKey?: string;
  redis?: { url: string };

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

    return new Environment({
      type:
        (output.parsed?.NODE_ENV as 'development' | 'production' | 'staging') ||
        'development',
      http: {
        port: +(process.env.PORT || output.parsed?.PORT || 3000),
      },
      database: {
        postgres: {
          url: output.parsed?.DATABASE_URL || '',
        },
      },
      jwt: {
        secret: output.parsed?.JWT_SECRET || 'change-me',
        expiresIn: output.parsed?.JWT_EXPIRES_IN || '7d',
      },
      uploadPath: output.parsed?.UPLOAD_PATH || 'sda1/Aplicativos/Family',
      cors: {
        origin: output.parsed?.CORS_ORIGIN || '*',
      },
      smtp:
        output.parsed?.SMTP_HOST && output.parsed?.SMTP_USER && output.parsed?.SMTP_PASS
          ? {
              host: output.parsed.SMTP_HOST,
              port: +(output.parsed.SMTP_PORT || '587'),
              user: output.parsed.SMTP_USER,
              pass: output.parsed.SMTP_PASS,
            }
          : undefined,
      emailFrom: output.parsed?.EMAIL_FROM,
      emailFromName: output.parsed?.EMAIL_FROM_NAME || 'Nossa Família',
      passwordResetUrl: output.parsed?.PASSWORD_RESET_URL || '',
      vapidPublicKey: output.parsed?.VAPID_PUBLIC_KEY,
      vapidPrivateKey: output.parsed?.VAPID_PRIVATE_KEY,
      redis: (process.env.REDIS_URL || output.parsed?.REDIS_URL)
        ? { url: process.env.REDIS_URL || output.parsed?.REDIS_URL! }
        : undefined,
    });
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

