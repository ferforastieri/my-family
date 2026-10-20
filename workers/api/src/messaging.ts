import type { Env } from './env';
import { badRequest, unavailable } from './http';

export type PhoneChannel = 'whatsapp' | 'sms';

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

export function whatsappConfigured(env: Env): boolean {
  return Boolean(
    env.WHATSAPP_ACCESS_TOKEN &&
      env.WHATSAPP_PHONE_NUMBER_ID &&
      env.WHATSAPP_OTP_TEMPLATE,
  );
}

export function smsConfigured(env: Env): boolean {
  return Boolean(
    env.TWILIO_ACCOUNT_SID && env.TWILIO_AUTH_TOKEN && env.TWILIO_FROM_NUMBER,
  );
}

export function channelConfigured(env: Env, channel: PhoneChannel): boolean {
  return channel === 'whatsapp' ? whatsappConfigured(env) : smsConfigured(env);
}

export async function sendOtp(
  env: Env,
  phoneNumber: string,
  code: string,
  channel: PhoneChannel,
): Promise<void> {
  if (channel === 'whatsapp') {
    await sendWhatsAppTemplate(env, phoneNumber, env.WHATSAPP_OTP_TEMPLATE, code);
    return;
  }
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
  channel: PhoneChannel,
): Promise<void> {
  const url = env.INVITATION_URL
    ? `${env.INVITATION_URL}?invitation=${encodeURIComponent(token)}`
    : token;
  if (channel === 'whatsapp') {
    if (!env.WHATSAPP_INVITATION_TEMPLATE) {
      throw unavailable('Template de convite do WhatsApp não configurado.');
    }
    await sendWhatsAppTemplate(
      env,
      phoneNumber,
      env.WHATSAPP_INVITATION_TEMPLATE,
      familyName,
      url,
    );
    return;
  }
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
    console.error(JSON.stringify({ level: 'error', message: 'Falha ao enviar SMS', status: response.status }));
    throw unavailable('Não foi possível enviar o SMS.');
  }
}

async function sendWhatsAppTemplate(
  env: Env,
  phoneNumber: string,
  template: string | undefined,
  ...parameters: string[]
): Promise<void> {
  if (!whatsappConfigured(env) || !template) {
    throw unavailable('Envio por WhatsApp não configurado.');
  }
  const response = await fetch(
    `https://graph.facebook.com/${env.WHATSAPP_API_VERSION ?? 'v23.0'}/${env.WHATSAPP_PHONE_NUMBER_ID}/messages`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.WHATSAPP_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to: phoneNumber.substring(1),
        type: 'template',
        template: {
          name: template,
          language: { code: 'pt_BR' },
          components: [
            {
              type: 'body',
              parameters: parameters.map((text) => ({ type: 'text', text })),
            },
          ],
        },
      }),
    },
  );
  if (!response.ok) {
    console.error(
      JSON.stringify({
        level: 'error',
        message: 'Falha ao enviar WhatsApp',
        status: response.status,
        body: await response.text(),
      }),
    );
    throw unavailable('Não foi possível enviar a mensagem pelo WhatsApp.');
  }
}
