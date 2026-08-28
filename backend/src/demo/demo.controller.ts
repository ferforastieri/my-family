import { Body, Controller, Post, Req, Res } from '@nestjs/common';
import { DemoService } from './demo.service';
import { TurnstileService } from '@shared/infrastructure/security/turnstile.service';
import { AuthCookieService } from '@shared/infrastructure/security/auth-cookies';
import type { Response } from 'express';
@Controller('public/demo-sessions')
export class DemoController {
  constructor(
    private demo: DemoService,
    private turnstile: TurnstileService,
    private cookies: AuthCookieService,
  ) {}
  @Post() async create(
    @Body('turnstileToken') token: string | undefined,
    @Req() req: { ip?: string },
    @Res({ passthrough: true }) response: Response,
  ) {
    await this.turnstile.verify(token, req.ip, { action: 'demo' });
    const result = await this.demo.create();
    const csrfToken = this.cookies.setSession(response, result.session);
    return { slug: result.slug, expiresAt: result.expiresAt, csrfToken };
  }
}
