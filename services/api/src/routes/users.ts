/**
 * Admin-only user management. There is no public sign-up: an admin invites a user by email,
 * the user sets a password from the emailed link. Deactivating a user revokes all sessions.
 */
import { createRoute, z } from '@hono/zod-openapi';
import { ROLES } from '@tbn/shared';
import { asc, eq } from 'drizzle-orm';
import { randomUUID } from 'node:crypto';
import type { App } from '../context.js';
import { session, user } from '../db/schema.js';
import { writeAudit } from '../audit.js';
import { ApiError } from '../errors.js';
import { clientIp, requirePermission } from '../middleware.js';

const UserOut = z
  .object({
    id: z.string(),
    name: z.string(),
    email: z.string(),
    roles: z.array(z.enum(ROLES)),
    active: z.boolean(),
    twoFactorEnabled: z.boolean(),
    /** False until the invitation is accepted (password set). */
    emailVerified: z.boolean(),
    createdAt: z.string(),
  })
  .meta({ id: 'User' });

const Invite = z
  .object({
    name: z.string().trim().min(1).max(100),
    email: z.email().max(200),
    roles: z.array(z.enum(ROLES)).min(1),
  })
  .meta({ id: 'UserInvite' });

const UserUpdate = z
  .object({
    name: z.string().trim().min(1).max(100).optional(),
    roles: z.array(z.enum(ROLES)).min(1).optional(),
    active: z.boolean().optional(),
  })
  .meta({ id: 'UserUpdate' });

type UserRow = typeof user.$inferSelect;
const toOut = (u: UserRow) =>
  UserOut.parse({
    ...u,
    roles: u.roles.split(',').filter(Boolean),
    twoFactorEnabled: Boolean(u.twoFactorEnabled),
    createdAt: u.createdAt.toISOString(),
  });

const IdParam = z.object({ id: z.string().min(1) });

export function registerUserRoutes(app: App) {
  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/v1/users',
      tags: ['users'],
      middleware: [requirePermission('users', 'read')] as const,
      responses: { 200: { description: 'Users', content: { 'application/json': { schema: z.object({ items: z.array(UserOut) }) } } } },
    }),
    async (c) => {
      const rows = await c.var.deps.db.select().from(user).orderBy(asc(user.name));
      return c.json({ items: rows.map(toOut) }, 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'post',
      path: '/api/v1/users',
      tags: ['users'],
      middleware: [requirePermission('users', 'write')] as const,
      request: { body: { content: { 'application/json': { schema: Invite } }, required: true } },
      responses: { 201: { description: 'Invited', content: { 'application/json': { schema: UserOut } } } },
    }),
    async (c) => {
      const { db, auth } = c.var.deps;
      const input = c.req.valid('json');
      const email = input.email.toLowerCase();
      const existing = await db.query.user.findFirst({ where: eq(user.email, email) });
      if (existing) throw new ApiError('conflict', 'A user with this email already exists');
      const [created] = await db
        .insert(user)
        .values({ id: randomUUID(), name: input.name, email, roles: input.roles.join(','), emailVerified: false })
        .returning();
      await writeAudit(db, {
        user: c.var.user,
        entity: 'users',
        entityId: created!.id,
        action: 'create',
        summary: `invite ${email} (${input.roles.join(', ')})`,
        ip: clientIp(c),
      });
      // Sends the invitation email (user has no password yet, see sendResetPassword in auth.ts).
      await auth.api.requestPasswordReset({ body: { email } });
      return c.json(toOut(created!), 201);
    },
  );

  app.openapi(
    createRoute({
      method: 'patch',
      path: '/api/v1/users/{id}',
      tags: ['users'],
      middleware: [requirePermission('users', 'write')] as const,
      request: { params: IdParam, body: { content: { 'application/json': { schema: UserUpdate } }, required: true } },
      responses: { 200: { description: 'Updated', content: { 'application/json': { schema: UserOut } } } },
    }),
    async (c) => {
      const { db } = c.var.deps;
      const { id } = c.req.valid('param');
      const input = c.req.valid('json');
      const me = c.var.user!;
      if (id === me.id && (input.active === false || (input.roles && !input.roles.includes('admin')))) {
        throw new ApiError('conflict', 'You cannot deactivate yourself or remove your own admin role');
      }
      const updated = await db.transaction(async (tx) => {
        const before = await tx.query.user.findFirst({ where: eq(user.id, id) });
        if (!before) throw new ApiError('not_found');
        const [row] = await tx
          .update(user)
          .set({
            ...(input.name !== undefined && { name: input.name }),
            ...(input.roles !== undefined && { roles: input.roles.join(',') }),
            ...(input.active !== undefined && { active: input.active }),
          })
          .where(eq(user.id, id))
          .returning();
        // Role or status changes take effect immediately: end the user's sessions.
        if (input.active === false || input.roles !== undefined) {
          await tx.delete(session).where(eq(session.userId, id));
        }
        await writeAudit(tx, {
          user: me,
          entity: 'users',
          entityId: id,
          action: 'update',
          summary: before.email,
          diff: {
            ...(input.roles && { roles: [before.roles, input.roles.join(',')] }),
            ...(input.active !== undefined && { active: [before.active, input.active] }),
            ...(input.name !== undefined && { name: [before.name, input.name] }),
          },
          ip: clientIp(c),
        });
        return row!;
      });
      return c.json(toOut(updated), 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'post',
      path: '/api/v1/users/{id}/resend-invite',
      tags: ['users'],
      middleware: [requirePermission('users', 'write')] as const,
      request: { params: IdParam },
      responses: { 204: { description: 'Sent' } },
    }),
    async (c) => {
      const { db, auth } = c.var.deps;
      const target = await db.query.user.findFirst({ where: eq(user.id, c.req.valid('param').id) });
      if (!target) throw new ApiError('not_found');
      if (!target.active) throw new ApiError('conflict', 'User is deactivated');
      await auth.api.requestPasswordReset({ body: { email: target.email } });
      return c.body(null, 204);
    },
  );

  app.openapi(
    createRoute({
      method: 'post',
      path: '/api/v1/users/{id}/revoke-sessions',
      tags: ['users'],
      middleware: [requirePermission('users', 'write')] as const,
      request: { params: IdParam },
      responses: { 204: { description: 'Revoked' } },
    }),
    async (c) => {
      const { db } = c.var.deps;
      const { id } = c.req.valid('param');
      await db.delete(session).where(eq(session.userId, id));
      await writeAudit(db, { user: c.var.user, entity: 'users', entityId: id, action: 'update', summary: 'revoke sessions', ip: clientIp(c) });
      return c.body(null, 204);
    },
  );
}
