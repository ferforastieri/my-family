import type { Env } from './env';
import { badRequest, unavailable } from './http';

export type PhoneChannel = 'sms';

export function normalizePhoneNumber(env: Env, value: string): string {
  const raw = value?.trim() ?? '';
  let digits = raw.replace(/\D/g, '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  const defaultCountryCode = env.DEFAULT_PHONE_COUNTRY_CODE ?? '55';
  if (!raw.startsWith('+') && (digits.length === 10 || digits.length === 11)) {
    digits = `${defaultCountryCode}${digits}`;
  }
  if (!/^[1-9]\d{9,14}$/.test(digits)) {
    throw badRequest(
      'Número inválido. Informe DDD e celular, ou use o formato internacional.',
    );
  }
  return `+${digits}`;
}

export function invalidPhoneNumber(env: Env, value: string): string | null {
  try {
    return normalizePhoneNumber(env, value);
  } catch {
    return null;
  }
}

export function smsConfigured(env: Env): boolean {
  return Boolean(
    env.TWILIO_ACCOUNT_SID && env.TWILIO_AUTH_TOKEN && env.TWILIO_FROM_NUMBER,
  );
}

export function channelConfigured(env: Env): boolean {
  return smsConfigured(env);
}

export async function sendOtp(
  env: Env,
  phoneNumber: string,
  code: string,
  _channel: PhoneChannel,
): Promise<void> {
  await sendSms(
    env,
    phoneNumber,
    `Seu código Nossa Família é ${code}. Ele expira em 5 minutos.`,
  );
}

export async function sendInvitation(
  env: Env,
  phoneNumber: string,
  familyName: string,
  token: string,
  _channel: PhoneChannel,
): Promise<void> {
  const url = env.INVITATION_URL
    ? `${env.INVITATION_URL}?invitation=${encodeURIComponent(token)}`
    : token;
  await sendSms(
    env,
    phoneNumber,
    `Você foi convidado para ${familyName} no Nossa Família: ${url}`,
  );
}

async function sendSms(env: Env, phoneNumber: string, body: string): Promise<void> {
  if (!smsConfigured(env)) {
    throw unavailable('Envio por SMS não configurado.');
  }
  const accountSid = env.TWILIO_ACCOUNT_SID!;
  const params = new URLSearchParams({
    To: phoneNumber,
    From: env.TWILIO_FROM_NUMBER!,
    Body: body,
  });
  const authorization = btoa(`${accountSid}:${env.TWILIO_AUTH_TOKEN!}`);
  const response = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
    {
      method: 'POST',
      headers: {
        Authorization: `Basic ${authorization}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    },
  );
  if (!response.ok) {
    console.error(
      JSON.stringify({
        level: 'error',
        message: 'Falha ao enviar SMS',
        status: response.status,
        body: (await response.text()).substring(0, 200),
      }),
    );
    throw unavailable('Não foi possível enviar o SMS.');
  }
}
