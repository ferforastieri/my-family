import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthService } from '../application/services/auth.service';
import { Environment } from '@shared/infrastructure/environment/environment.module';
import {
  ACCESS_COOKIE,
  cookieValue,
} from '@shared/infrastructure/security/auth-cookies';
import type { Request } from 'express';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private auth: AuthService,
    env: Environment,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromExtractors([
        (request: Request) => cookieValue(request, ACCESS_COOKIE),
      ]),
      ignoreExpiration: false,
      secretOrKey: env.jwt.secret,
      algorithms: ['HS256'],
      issuer: 'nossa-familia-api',
      audience: 'nossa-familia-app',
    });
  }

  async validate(payload: { sub: string; tenantId?: string }) {
    const user = await this.auth.findById(payload.sub);
    if (!user) throw new UnauthorizedException();
    if (!payload.tenantId) return user;
    return this.auth.tenantPrincipal(payload.sub, payload.tenantId);
  }
}
