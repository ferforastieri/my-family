import { BadRequestException, Injectable } from '@nestjs/common';
import { Environment } from '@shared/infrastructure/environment/environment.module';

@Injectable()
export class TurnstileService {
  constructor(private env: Environment) {}

  async verify(
    token?: string,
    remoteIp?: string,
    options: { required?: boolean; action?: string } = {},
  ): Promise<void> {
    const secret = this.env.turnstileSecret;
    if (!secret) return;
    if (!token && options.required !== false)
      throw new BadRequestException('Confirme que você não é um robô.');
    if (!token) return;

    const body = new URLSearchParams({ secret, response: token });
    if (remoteIp) body.set('remoteip', remoteIp);
    try {
      const response = await fetch(
        'https://challenges.cloudflare.com/turnstile/v0/siteverify',
        {
          method: 'POST',
          headers: { 'content-type': 'application/x-www-form-urlencoded' },
          body,
          signal: AbortSignal.timeout(5000),
        },
      );
      const result = (await response.json()) as {
        success?: boolean;
        action?: string;
      };
      if (
        !response.ok ||
        result.success !== true ||
        (options.action && result.action !== options.action)
      ) {
        throw new BadRequestException(
          'Validação anti-robô inválida ou expirada.',
        );
      }
    } catch (error) {
      if (error instanceof BadRequestException) throw error;
      throw new BadRequestException(
        'Não foi possível validar o desafio. Tente novamente.',
      );
    }
  }
}
