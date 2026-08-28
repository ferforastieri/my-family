import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { Environment } from '@shared/infrastructure/environment/environment.module';

export type PhoneChannel = 'whatsapp' | 'sms';

@Injectable()
export class PhoneMessagingService {
  constructor(private env: Environment) {}

  normalizePhoneNumber(value: string) {
    const raw = value?.trim() ?? '';
    let digits = raw.replace(/\D/g, '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (
      !raw.startsWith('+') &&
      (digits.length === 10 || digits.length === 11)
    ) {
      digits = `${this.env.phoneAuth.defaultCountryCode}${digits}`;
    }
    if (!/^[1-9]\d{9,14}$/.test(digits)) return null;
    return `+${digits}`;
  }

  isConfigured(channel: PhoneChannel) {
    return channel === 'whatsapp'
      ? this.env.phoneAuth.whatsapp != null
      : this.env.phoneAuth.sms != null;
  }

  async sendOtp(phoneNumber: string, code: string, channel: PhoneChannel) {
    if (channel === 'whatsapp') {
      await this.sendWhatsAppTemplate(
        phoneNumber,
        this.env.phoneAuth.whatsapp?.otpTemplate,
        code,
      );
      return;
    }
    await this.sendSms(
      phoneNumber,
      `Seu código Nossa Família é ${code}. Ele expira em 5 minutos.`,
    );
  }

  async sendInvitation(
    phoneNumber: string,
    familyName: string,
    token: string,
    channel: PhoneChannel,
  ) {
    const url = this.env.invitationUrl
      ? `${this.env.invitationUrl}?invitation=${encodeURIComponent(token)}`
      : token;
    if (channel === 'whatsapp') {
      const template = this.env.phoneAuth.whatsapp?.invitationTemplate;
      if (!template) {
        throw new ServiceUnavailableException(
          'Template de convite do WhatsApp não configurado.',
        );
      }
      await this.sendWhatsAppTemplate(phoneNumber, template, familyName, url);
      return;
    }
    await this.sendSms(
      phoneNumber,
      `Você foi convidado para ${familyName} no Nossa Família: ${url}`,
    );
  }

  private async sendSms(phoneNumber: string, body: string) {
    const config = this.env.phoneAuth.sms;
    if (!config) {
      throw new ServiceUnavailableException('Envio por SMS não configurado.');
    }
    const params = new URLSearchParams({
      To: phoneNumber,
      From: config.from,
      Body: body,
    });
    const authorization = Buffer.from(
      `${config.accountSid}:${config.authToken}`,
    ).toString('base64');
    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${config.accountSid}/Messages.json`,
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
      throw new ServiceUnavailableException('Não foi possível enviar o SMS.');
    }
  }

  private async sendWhatsAppTemplate(
    phoneNumber: string,
    template: string | undefined,
    ...parameters: string[]
  ) {
    const config = this.env.phoneAuth.whatsapp;
    if (!config || !template) {
      throw new ServiceUnavailableException(
        'Envio por WhatsApp não configurado.',
      );
    }
    const response = await fetch(
      `https://graph.facebook.com/${config.apiVersion}/${config.phoneNumberId}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${config.accessToken}`,
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
      throw new ServiceUnavailableException(
        'Não foi possível enviar a mensagem pelo WhatsApp.',
      );
    }
  }
}
