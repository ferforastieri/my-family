import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
import { Environment } from '@shared/infrastructure/environment/environment.module';

@Injectable()
export class EmailService {
  private transporter: nodemailer.Transporter | null = null;

  constructor(private env: Environment) {
    if (this.env.smtp) {
      this.transporter = nodemailer.createTransport({
        host: this.env.smtp.host,
        port: this.env.smtp.port,
        secure: this.env.smtp.port === 465,
        auth: { user: this.env.smtp.user, pass: this.env.smtp.pass },
        tls: { rejectUnauthorized: false },
      });
    }
  }

  get isEnabled(): boolean {
    return !!this.transporter;
  }

  async sendPasswordReset(to: string, token: string): Promise<void> {
    if (!this.transporter) throw new Error('Email não configurado. Configure SMTP_HOST, SMTP_PORT, SMTP_USER e SMTP_PASS.');
    const resetLink = this.env.passwordResetUrl
      ? `${this.env.passwordResetUrl}?token=${encodeURIComponent(token)}`
      : null;
    const from = this.env.emailFrom && this.env.emailFromName
      ? `"${this.env.emailFromName}" <${this.env.emailFrom}>`
      : this.env.emailFrom || 'noreply@nossafamilia.local';
    const html = resetLink
      ? `<p>Use o link para redefinir sua senha:</p><p><a href="${resetLink}">Redefinir senha</a></p><p>Ou use o token: ${token}</p>`
      : `<p>Use o token abaixo para redefinir sua senha:</p><p><strong>${token}</strong></p>`;
    await this.transporter.sendMail({
      from,
      to,
      subject: 'Recuperação de senha - Nossa Família',
      html,
      text: html.replace(/<[^>]*>/g, ''),
    });
  }
}
