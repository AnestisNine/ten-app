import { z } from 'zod';

const Env = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().default(8080),
  DATABASE_URL: z.string().min(1),
  /** Public origin of the internal app/API, e.g. https://app.thebonnienettles.com */
  APP_URL: z.url().default('http://localhost:8080'),
  /** Extra origins allowed to call the API with cookies (comma separated), e.g. the Flutter dev server. */
  TRUSTED_ORIGINS: z.string().default(''),
  /** Origins of the public website, allowed to call /api/public/* only. */
  PUBLIC_SITE_ORIGINS: z.string().default(''),
  /** ≥32 random bytes, base64. Signs sessions. */
  AUTH_SECRET: z.string().min(32),
  /** 32 random bytes, base64. Encrypts sensitive member data. Losing it = losing that data. */
  DATA_ENCRYPTION_KEY: z.string().refine((v) => Buffer.from(v, 'base64').length === 32, {
    message: 'DATA_ENCRYPTION_KEY must be 32 bytes, base64 encoded (openssl rand -base64 32)',
  }),
  FILES_DIR: z.string().default('./data/files'),
  /** SMTP connection string, e.g. smtps://user:pass@smtp.example.com:465. Empty = print emails to the log. */
  SMTP_URL: z.string().default(''),
  MAIL_FROM: z.string().default('TBN Manager <no-reply@localhost>'),
  /** Directory with the built Flutter web app to serve at /. Empty = don't serve. */
  WEB_APP_DIR: z.string().default(''),
});

export type Config = z.infer<typeof Env>;

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const parsed = Env.safeParse(env);
  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => `  ${i.path.join('.')}: ${i.message}`).join('\n');
    throw new Error(`Invalid environment:\n${issues}`);
  }
  return parsed.data;
}

export const splitList = (v: string) =>
  v
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
