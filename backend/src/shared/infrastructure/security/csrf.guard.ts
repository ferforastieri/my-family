import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import type { Request } from 'express';
import { CSRF_COOKIE, cookieValue, equalSecret } from './auth-cookies';

const SAFE_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);
const PUBLIC_POST_PATHS = new Set([
  '/auth/phone/request-code',
  '/auth/phone/verify-code',
  '/public/demo-sessions',
]);

@Injectable()
export class CsrfGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    if (context.getType() !== 'http') return true;
    const request = context.switchToHttp().getRequest<Request>();
    if (SAFE_METHODS.has(request.method.toUpperCase())) return true;
    const path = normalizePath(request.path);
    if (PUBLIC_POST_PATHS.has(path)) return true;
    const cookie = cookieValue(request, CSRF_COOKIE);
    const header = request.headers['x-csrf-token'];
    const token = Array.isArray(header) ? header[0] : header;
    if (!cookie || !token || !equalSecret(cookie, token)) {
      throw new ForbiddenException('Token CSRF inválido ou ausente.');
    }
    return true;
  }
}

function normalizePath(path: string) {
  return path.startsWith('/api/') ? path.substring(4) : path;
}
