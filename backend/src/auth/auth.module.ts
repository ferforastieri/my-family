import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { AuthService } from './application/services/auth.service';
import { AuthController } from './interfaces/controllers/auth.controller';
import { UsersController } from './interfaces/controllers/users.controller';
import { JwtStrategy } from './strategies/jwt.strategy';
import { UserRepository } from './infrastructure/repositories/user.repository';
import { WsSessionService } from './application/services/ws-session.service';
import { TenancyModule } from '@tenancy/tenancy.module';
import { TurnstileService } from '@shared/infrastructure/security/turnstile.service';
import { PhoneChallengeRepository } from './infrastructure/repositories/phone-challenge.repository';
import { PhoneMessagingService } from './application/services/phone-messaging.service';
import { AuthCookieService } from '@shared/infrastructure/security/auth-cookies';

@Module({
  imports: [
    DatabaseModule,
    MongoModelsModule,
    TenancyModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [EnvironmentModule],
      inject: [Environment],
      useFactory: (env: Environment) =>
        ({
          secret: env.jwt.secret,
          signOptions: {
            algorithm: 'HS256',
            issuer: 'nossa-familia-api',
            audience: 'nossa-familia-app',
            expiresIn: env.jwt.expiresIn,
          },
        }) as any,
    }),
  ],
  controllers: [AuthController, UsersController],
  providers: [
    AuthService,
    UserRepository,
    PhoneChallengeRepository,
    PhoneMessagingService,
    WsSessionService,
    JwtStrategy,
    TurnstileService,
    AuthCookieService,
  ],
  exports: [AuthService, WsSessionService, AuthCookieService],
})
export class AuthModule {}
