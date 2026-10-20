import type { Env } from './env';
import { badRequest } from './http';

export async function verifyTurnstile(
  env: Env,
  token: string | undefined,
  ip: string | undefined,
  options: { required: boolean; action?: string },
): Promise<void> {
  if (!env.TURNSTILE_SECRET) {
    if (options.required) throw badRequest('Verificação anti-bot não configurada.');
    return;
  }
  if (!token) {
    if (options.required) throw badRequest('Confirme que você não é um robô.');
    return;
  }
  const body = new FormData();
  body.set('secret', env.TURNSTILE_SECRET);
  body.set('response', token);
  if (ip) body.set('remoteip', ip);
  const response = await fetch(
    'https://challenges.cloudflare.com/turnstile/v0/siteverify',
    { method: 'POST', body },
  );
  if (!response.ok) throw badRequest('Não foi possível validar a verificação anti-bot.');
  const result = (await response.json()) as {
    success?: boolean;
    action?: string;
    'error-codes'?: string[];
  };
  if (!result.success || (options.action && result.action !== options.action)) {
    throw badRequest('Não foi possível validar a verificação anti-bot.');
  }
}
