import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { APP_GUARD } from '@nestjs/core';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { MongoModelsModule } from '@shared/infrastructure/database/database.providers';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { AuthService } from './application/services/auth.service';
import { AuthController } from './interfaces/controllers/auth.controller';
import { UserService } from './application/services/user.service';
import { UsersController } from './interfaces/controllers/users.controller';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';
import { UserRepository } from './infrastructure/repositories/user.repository';
import { PasswordResetRepository } from './infrastructure/repositories/password-reset.repository';
import { UsersGateway } from './interfaces/gateways/users.gateway';
import { WsSessionService } from './application/services/ws-session.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [
    DatabaseModule,
    MongoModelsModule,
    AuditModule,
    JwtModule.registerAsync({
      imports: [EnvironmentModule],
      inject: [Environment],
      useFactory: (env: Environment) =>
        ({
          secret: env.jwt.secret,
          signOptions: { expiresIn: env.jwt.expiresIn },
        }) as any,
    }),
  ],
  controllers: [AuthController, UsersController],
  providers: [
    AuthService,
    UserService,
    UserRepository,
    PasswordResetRepository,
    WsSessionService,
    UsersGateway,
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    RolesGuard,
  ],
  exports: [AuthService, UserService, WsSessionService, RolesGuard],
})
export class AuthModule {}
