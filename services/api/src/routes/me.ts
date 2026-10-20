import { createRoute, z } from '@hono/zod-openapi';
import { ACTIONS, RESOURCES, Settings, can, requiresTwoFactor, type Action, type Resource } from '@tbn/shared';
import { eq } from 'drizzle-orm';
import type { App, CurrentUser } from '../context.js';
import type { Db } from '../db/client.js';
import { settings, user as userTable } from '../db/schema.js';
import { clientIp, requirePermission, requireUser } from '../middleware.js';
import { ENTITY_DEFS } from './entities.js';
import { entityReader, rowToPlain } from './crud.js';
import { writeAudit } from '../audit.js';

const Me = z
  .object({
    id: z.string(),
    name: z.string(),
    email: z.string(),
    locale: z.string(),
    roles: z.array(z.string()),
    twoFactorEnabled: z.boolean(),
    twoFactorRequired: z.boolean(),
    /** resource → allowed actions, for hiding UI the user cannot use. The API enforces it regardless. */
    permissions: z.record(z.string(), z.array(z.string())),
  })
  .meta({ id: 'Me' });

function permissionsFor(user: CurrentUser) {
  const out: Partial<Record<Resource, Action[]>> = {};
  for (const r of RESOURCES) {
    const actions = ACTIONS.filter((a) => can(user.roles, r, a));
    if (actions.length) out[r] = actions;
  }
  return out;
}

export function meOf(user: CurrentUser, enforce2fa = true) {
  return {
    ...user,
    twoFactorRequired: enforce2fa && requiresTwoFactor(user.roles),
    permissions: permissionsFor(user),
  };
}

export async function loadSettings(db: Db) {
  const row = await db.query.settings.findFirst({ where: eq(settings.id, 1) });
  return Settings.parse(rowToPlain(row ?? {}));
}

const SettingsSchema = Settings.meta({ id: 'Settings' });

export function registerMeRoutes(app: App) {
  // Reachable before 2FA enrollment so the app can show the "enable 2FA" screen.
  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/v1/me',
      tags: ['me'],
      middleware: [requireUser({ allowWithout2fa: true })] as const,
      responses: { 200: { description: 'Current user', content: { 'application/json': { schema: Me } } } },
    }),
    (c) => c.json(meOf(c.var.user!, c.var.deps.config.REQUIRE_TWO_FACTOR), 200),
  );

  app.openapi(
    createRoute({
      method: 'patch',
      path: '/api/v1/me',
      tags: ['me'],
      middleware: [requireUser({ allowWithout2fa: true })] as const,
      request: {
        body: { content: { 'application/json': { schema: z.object({ locale: z.enum(['el', 'en']) }) } }, required: true },
      },
      responses: { 200: { description: 'Updated', content: { 'application/json': { schema: Me } } } },
    }),
    async (c) => {
      const { locale } = c.req.valid('json');
      const { db } = c.var.deps;
      await db.update(userTable).set({ locale }).where(eq(userTable.id, c.var.user!.id));
      return c.json(meOf({ ...c.var.user!, locale }, c.var.deps.config.REQUIRE_TWO_FACTOR), 200);
    },
  );

  /** Everything the user may read, in one request. The app loads this at start. */
  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/v1/bootstrap',
      tags: ['me'],
      responses: {
        200: {
          description: 'All readable data',
          content: {
            'application/json': {
              schema: z
                .object({
                  me: Me,
                  settings: SettingsSchema.nullable(),
                  data: z.record(z.string(), z.array(z.unknown())),
                })
                .meta({ id: 'Bootstrap' }),
            },
          },
        },
      },
    }),
    async (c) => {
      const user = c.var.user!;
      const { db } = c.var.deps;
      const data: Record<string, unknown[]> = {};
      for (const def of ENTITY_DEFS) {
        if (can(user.roles, def.resource, 'read')) data[def.path] = await entityReader(def).list(db, user);
      }
      const s = can(user.roles, 'settings', 'read') || can(user.roles, 'bookings', 'read') ? await loadSettings(db) : null;
      return c.json({ me: meOf(user, c.var.deps.config.REQUIRE_TWO_FACTOR), settings: s, data }, 200);
    },
  );

  // Settings hold trip-cost defaults (needed by anyone planning tours) and finance figures.
  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/v1/settings',
      tags: ['settings'],
      middleware: [requirePermission('bookings', 'read')] as const,
      responses: { 200: { description: 'Settings', content: { 'application/json': { schema: SettingsSchema } } } },
    }),
    async (c) => c.json(await loadSettings(c.var.deps.db), 200),
  );

  app.openapi(
    createRoute({
      method: 'patch',
      path: '/api/v1/settings',
      tags: ['settings'],
      middleware: [requirePermission('settings', 'write')] as const,
      request: { body: { content: { 'application/json': { schema: Settings.partial() } }, required: true } },
      responses: { 200: { description: 'Settings', content: { 'application/json': { schema: SettingsSchema } } } },
    }),
    async (c) => {
      const { db } = c.var.deps;
      const input = c.req.valid('json');
      const before = await loadSettings(db);
      await db.transaction(async (tx) => {
        await tx.update(settings).set(input).where(eq(settings.id, 1));
        await writeAudit(tx, {
          user: c.var.user,
          entity: 'settings',
          action: 'update',
          summary: Object.keys(input).join(', '),
          diff: Object.fromEntries(Object.entries(input).map(([k, v]) => [k, [before[k as keyof typeof before], v]])),
          ip: clientIp(c),
        });
      });
      return c.json(await loadSettings(db), 200);
    },
  );

}
