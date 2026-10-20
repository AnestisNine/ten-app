import nodemailer from 'nodemailer';
import type { Config } from './config.js';

export interface Mail {
  to: string;
  subject: string;
  text: string;
  html?: string;
}

export interface Mailer {
  send(mail: Mail): Promise<void>;
}

/** Keeps sent mail in memory; used by tests. */
export class MemoryMailer implements Mailer {
  readonly sent: Mail[] = [];
  async send(mail: Mail) {
    this.sent.push(mail);
  }
}

export function createMailer(config: Config): Mailer {
  if (!config.SMTP_URL) {
    return {
      async send(mail) {
        // Development fallback: no SMTP configured, print the email (contains links with tokens).
        console.log(`\n--- email to ${mail.to}: ${mail.subject}\n${mail.text}\n---\n`);
      },
    };
  }
  const transport = nodemailer.createTransport(config.SMTP_URL);
  return {
    async send(mail) {
      await transport.sendMail({ from: config.MAIL_FROM, ...mail });
    },
  };
}
