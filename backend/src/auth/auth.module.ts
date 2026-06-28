import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { APP_GUARD } from '@nestjs/core';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
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
import { WsSessionService } from './application/services/ws-session.service';
import { AuditModule } from '../audit/audit.module';
import { SupportSessionService } from './application/services/support-session.service';
import {
  PasswordResetDocument,
  PasswordResetSchema,
} from './infrastructure/persistence/password-reset.schema';
import {
  SupportSessionDocument,
  SupportSessionSchema,
} from './infrastructure/persistence/support-session.schema';
import { UserDocument, UserSchema } from './infrastructure/persistence/user.schema';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: UserDocument.name, schema: UserSchema },
      { name: PasswordResetDocument.name, schema: PasswordResetSchema },
      { name: SupportSessionDocument.name, schema: SupportSessionSchema },
    ]),
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
    SupportSessionService,
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    RolesGuard,
  ],
  exports: [
    AuthService,
    UserService,
    WsSessionService,
    SupportSessionService,
    RolesGuard,
  ],
})
export class AuthModule {}
