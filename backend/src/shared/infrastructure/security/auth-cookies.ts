import { Injectable } from '@nestjs/common';
import { randomBytes, timingSafeEqual } from 'node:crypto';
import type { Request, Response } from 'express';
import { Environment } from '../environment/environment.module';

export const ACCESS_COOKIE = 'fmf_access';
export const REFRESH_COOKIE = 'fmf_refresh';
export const CSRF_COOKIE = 'fmf_csrf';

export interface SessionTokens {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class AuthCookieService {
  constructor(private environment: Environment) {}

  setSession(response: Response, tokens: SessionTokens): string {
    response.cookie(ACCESS_COOKIE, tokens.accessToken, {
      ...this.baseOptions(),
      httpOnly: true,
      priority: 'high',
      maxAge: 15 * 60 * 1000,
    });
    response.cookie(REFRESH_COOKIE, tokens.refreshToken, {
      ...this.baseOptions(),
      httpOnly: true,
      priority: 'high',
      maxAge: 90 * 24 * 60 * 60 * 1000,
    });
    return this.rotateCsrf(response);
  }

  rotateCsrf(response: Response): string {
    const token = randomBytes(32).toString('base64url');
    response.cookie(CSRF_COOKIE, token, {
      ...this.baseOptions(),
      httpOnly: false,
      priority: 'high',
      maxAge: 90 * 24 * 60 * 60 * 1000,
    });
    return token;
  }

  clear(response: Response) {
    for (const name of [ACCESS_COOKIE, REFRESH_COOKIE, CSRF_COOKIE]) {
      response.clearCookie(name, this.baseOptions());
    }
  }

  private baseOptions() {
    return {
      secure: this.environment.cookies.secure,
      sameSite: this.environment.cookies.sameSite,
      path: '/',
    } as const;
  }
}

export function cookieValue(
  request: Pick<Request, 'headers'> | { headers: { cookie?: string } },
  name: string,
): string | null {
  const header = request.headers.cookie;
  if (!header) return null;
  for (const part of header.split(';')) {
    const separator = part.indexOf('=');
    if (separator < 0) continue;
    const key = part.substring(0, separator).trim();
    if (key !== name) continue;
    try {
      return decodeURIComponent(part.substring(separator + 1).trim());
    } catch {
      return null;
    }
  }
  return null;
}

export function equalSecret(left: string, right: string): boolean {
  const leftBytes = Buffer.from(left);
  const rightBytes = Buffer.from(right);
  return (
    leftBytes.length === rightBytes.length &&
    timingSafeEqual(leftBytes, rightBytes)
  );
}
