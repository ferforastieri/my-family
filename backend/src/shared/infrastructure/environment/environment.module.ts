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
  betterAuth: {
    secret: string;
    url: string;
  };
  cors: {
    origin: string;
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

    return new Environment({
      type:
        (output.parsed?.NODE_ENV as 'development' | 'production' | 'staging') ||
        'development',
      http: {
        port: +(output.parsed?.PORT || 3000),
      },
      database: {
        postgres: {
          url: output.parsed?.DATABASE_URL || '',
        },
      },
      betterAuth: {
        secret: output.parsed?.BETTER_AUTH_SECRET || '',
        url: output.parsed?.BETTER_AUTH_URL || 'http://localhost:3000/api/auth',
      },
      cors: {
        origin: output.parsed?.CORS_ORIGIN || '*',
      },
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

