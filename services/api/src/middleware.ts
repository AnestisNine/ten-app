import type { Action, Resource } from '@tbn/shared';
import { can, parseRoles, requiresTwoFactor } from '@tbn/shared';
import { createMiddleware } from 'hono/factory';
import { splitList } from './config.js';
import type { AppEnv, CurrentUser } from './context.js';
import { ApiError } from './errors.js';

interface SessionUser {
  id: string;
  name: string;
  email: string;
  roles?: string;
  active?: boolean;
  twoFactorEnabled?: boolean | null;
  locale?: string;
}

/** Loads the session (if any) into c.var.user. Never rejects. */
export const loadSession = createMiddleware<AppEnv>(async (c, next) => {
  const { auth } = c.var.deps;
  const result = await auth.api.getSession({ headers: c.req.raw.headers });
  const u = result?.user as SessionUser | undefined;
  if (result && u && u.active !== false) {
    const user: CurrentUser = {
      id: u.id,
      name: u.name,
      email: u.email,
      roles: parseRoles(u.roles),
      twoFactorEnabled: Boolean(u.twoFactorEnabled),
      locale: u.locale ?? 'el',
    };
    c.set('user', user);
    c.set('sessionId', result.session.id);
  } else {
    c.set('user', null);
    c.set('sessionId', null);
  }
  await next();
});

/**
 * Rejects anonymous users, and users whose role requires 2FA but who have not enabled it yet.
 * `allowWithout2fa` is for the few endpoints needed to finish 2FA enrollment (e.g. GET /me).
 */
export function requireUser(opts: { allowWithout2fa?: boolean } = {}) {
  return createMiddleware<AppEnv>(async (c, next) => {
    const user = c.var.user;
    if (!user) throw new ApiError('unauthenticated');
    if (!opts.allowWithout2fa && requiresTwoFactor(user.roles) && !user.twoFactorEnabled) {
      throw new ApiError('two_factor_required', 'Your role requires two-factor authentication. Enable it first.');
    }
    await next();
  });
}

export function requirePermission(resource: Resource, action: Action) {
  return createMiddleware<AppEnv>(async (c, next) => {
    const user = c.var.user;
    if (!user) throw new ApiError('unauthenticated');
    if (!can(user.roles, resource, action)) throw new ApiError('forbidden');
    await next();
  });
}

/**
 * Exact origins, or a single-level wildcard host such as `https://*.trycloudflare.com`
 * (used only by the preview setup).
 */
export function originAllowed(origin: string, patterns: readonly string[]): boolean {
  for (const raw of patterns) {
    const pattern = raw.replace(/\/$/, '');
    if (pattern === origin) return true;
    const m = /^(https?):\/\/\*\.([a-z0-9.-]+)$/i.exec(pattern);
    if (m) {
      try {
        const u = new URL(origin);
        const label = u.hostname.slice(0, -(m[2]!.length + 1));
        if (u.protocol === `${m[1]}:` && u.hostname.endsWith(`.${m[2]}`) && /^[a-z0-9-]+$/i.test(label) && !u.port) {
          return true;
        }
      } catch {
        // not a URL
      }
    }
  }
  return false;
}

/**
 * CSRF defence for cookie-authenticated requests: browsers always send Origin on cross-site
 * POST/PUT/PATCH/DELETE, so any state-changing request with a foreign Origin is rejected.
 * Native apps send no Origin and are unaffected.
 */
export const checkOrigin = createMiddleware<AppEnv>(async (c, next) => {
  const method = c.req.method;
  if (method !== 'GET' && method !== 'HEAD' && method !== 'OPTIONS') {
    const origin = c.req.header('origin');
    const { config } = c.var.deps;
    const allowed = [config.APP_URL, ...splitList(config.TRUSTED_ORIGINS)];
    if (origin && !originAllowed(origin, allowed)) throw new ApiError('bad_origin');
  }
  await next();
});

export const clientIp = (c: { req: { header(name: string): string | undefined } }) =>
  c.req.header('cf-connecting-ip') ?? c.req.header('x-forwarded-for')?.split(',')[0]?.trim() ?? null;
