import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthService } from '../application/services/auth.service';
import { Environment } from '@shared/infrastructure/environment/environment.module';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private auth: AuthService,
    env: Environment,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: env.jwt.secret,
    });
  }

  async validate(payload: { sub: string; tenantId: string; type?: string }) {
    if (payload.type === 'refresh') throw new UnauthorizedException();
    if (!payload.tenantId) throw new UnauthorizedException();
    const user = await this.auth.findAuthenticatedUser(
      payload.sub,
      payload.tenantId,
    );
    if (!user) throw new UnauthorizedException();
    return user;
  }
}
