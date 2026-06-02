import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { AuthService } from './application/auth.service';
import { AuthController } from './interfaces/controllers/auth.controller';
import { UserService } from './application/user.service';
import { UsersController } from './interfaces/controllers/users.controller';
import { LocalStrategy } from './strategies/local.strategy';
import { JwtStrategy } from './strategies/jwt.strategy';
import { RolesGuard } from './guards/roles.guard';
import { UserRepository } from './infrastructure/repositories/user.repository';
import { PasswordResetRepository } from './infrastructure/repositories/password-reset.repository';
import { AuthGateway } from './interfaces/gateways/auth.gateway';
import { WsSessionService } from './application/ws-session.service';

@Module({
  imports: [
    DatabaseModule,
    MongoModelsModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [EnvironmentModule],
      inject: [Environment],
      useFactory: (env: Environment) => ({
        secret: env.jwt.secret,
        signOptions: { expiresIn: env.jwt.expiresIn },
      } as any),
    }),
  ],
  controllers: [AuthController, UsersController],
  providers: [
    AuthService,
    UserService,
    UserRepository,
    PasswordResetRepository,
    WsSessionService,
    AuthGateway,
    LocalStrategy,
    JwtStrategy,
    RolesGuard,
  ],
  exports: [AuthService, UserService, WsSessionService, RolesGuard],
})
export class AuthModule {}
