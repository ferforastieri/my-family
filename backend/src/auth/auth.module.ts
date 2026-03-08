import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { DatabaseModule } from '@shared/infrastructure/database/database.module';
import { EnvironmentModule } from '@shared/infrastructure/environment/environment.module';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { UserService } from './user.service';
import { UsersController } from './users.controller';
import { LocalStrategy } from './strategies/local.strategy';
import { JwtStrategy } from './strategies/jwt.strategy';
import { RolesGuard } from './guards/roles.guard';

@Module({
  imports: [
    DatabaseModule,
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
  providers: [AuthService, UserService, LocalStrategy, JwtStrategy, RolesGuard],
  exports: [AuthService, UserService, RolesGuard],
})
export class AuthModule {}
