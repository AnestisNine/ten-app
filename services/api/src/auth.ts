import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';
import { twoFactor } from 'better-auth/plugins';
import { and, eq } from 'drizzle-orm';
import { splitList, type Config } from './config.js';
import type { Db } from './db/client.js';
import { account, session, twoFactor as twoFactorTable, user, verification } from './db/schema.js';
import type { Mailer } from './mailer.js';
import { inviteEmail, resetPasswordEmail } from './emails.js';

/** Invitation / reset links stay valid for 48 hours. */
export const PASSWORD_TOKEN_TTL_SECONDS = 60 * 60 * 48;

export function createAuth(config: Config, db: Db, mailer: Mailer) {
  const secure = config.APP_URL.startsWith('https://');
  return betterAuth({
    appName: 'TBN Manager',
    baseURL: config.APP_URL,
    basePath: '/api/auth',
    secret: config.AUTH_SECRET,
    trustedOrigins: [config.APP_URL, ...splitList(config.TRUSTED_ORIGINS)],
    database: drizzleAdapter(db, {
      provider: 'pg',
      schema: { user, session, account, verification, twoFactor: twoFactorTable },
    }),
    emailAndPassword: {
      enabled: true,
      // Invite-only: accounts are created by an admin (POST /api/v1/users).
      disableSignUp: true,
      minPasswordLength: 12,
      maxPasswordLength: 128,
      resetPasswordTokenExpiresIn: PASSWORD_TOKEN_TTL_SECONDS,
      revokeSessionsOnPasswordReset: true,
      async sendResetPassword({ user: u, token }) {
        const link = `${config.APP_URL}/auth/set-password?token=${encodeURIComponent(token)}`;
        // A user without a password yet is completing an invitation.
        const credential = await db.query.account.findFirst({
          where: and(eq(account.userId, u.id), eq(account.providerId, 'credential')),
        });
        await mailer.send(credential ? resetPasswordEmail(u.name, u.email, link) : inviteEmail(u.name, u.email, link));
      },
      async onPasswordReset({ user: u }) {
        // Setting a password from an emailed link proves the address.
        await db.update(user).set({ emailVerified: true }).where(eq(user.id, u.id));
      },
    },
    user: {
      additionalFields: {
        roles: { type: 'string', input: false, defaultValue: '' },
        active: { type: 'boolean', input: false, defaultValue: true },
        locale: { type: 'string', input: true, defaultValue: 'el' },
      },
    },
    session: {
      expiresIn: 60 * 60 * 24 * 14,
      updateAge: 60 * 60 * 24,
    },
    rateLimit: {
      enabled: config.NODE_ENV !== 'test',
      window: 60,
      max: 100,
      customRules: {
        '/sign-in/email': { window: 60, max: 5 },
        '/two-factor/verify-totp': { window: 60, max: 5 },
        '/two-factor/verify-backup-code': { window: 60, max: 5 },
        '/request-password-reset': { window: 300, max: 3 },
        '/reset-password': { window: 300, max: 5 },
      },
    },
    advanced: {
      cookiePrefix: 'tbn',
      useSecureCookies: secure,
      // Behind Cloudflare Tunnel the client IP arrives in this header.
      ipAddress: { ipAddressHeaders: ['cf-connecting-ip', 'x-forwarded-for'] },
    },
    databaseHooks: {
      session: {
        create: {
          async before(s) {
            const u = await db.query.user.findFirst({ where: eq(user.id, s.userId) });
            // Deactivated users cannot start a session.
            if (!u || !u.active) return false;
            return { data: s };
          },
        },
      },
    },
    plugins: [twoFactor({ issuer: 'TBN Manager' })],
  });
}

export type Auth = ReturnType<typeof createAuth>;
