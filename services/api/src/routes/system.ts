import { createRoute, z } from '@hono/zod-openapi';
import { AuditEntry, Notification } from '@tbn/shared';
import { and, desc, eq, lt } from 'drizzle-orm';
import type { App } from '../context.js';
import { auditLog, notifications } from '../db/schema.js';
import { requirePermission, requireUser } from '../middleware.js';
import { rowToPlain } from './crud.js';

const AuditOut = AuditEntry.meta({ id: 'AuditEntry' });
const NotificationOut = Notification.meta({ id: 'Notification' });

export function registerSystemRoutes(app: App) {
  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/v1/audit',
      tags: ['audit'],
      middleware: [requirePermission('audit', 'read')] as const,
      request: {
        query: z.object({
          before: z.iso.datetime({ offset: true }).optional(),
          limit: z.coerce.number().int().min(1).max(500).default(100),
        }),
      },
      responses: { 200: { description: 'Newest first', content: { 'application/json': { schema: z.object({ items: z.array(AuditOut) }) } } } },
    }),
    async (c) => {
      const { before, limit } = c.req.valid('query');
      const rows = await c.var.deps.db
        .select()
        .from(auditLog)
        .where(before ? lt(auditLog.at, new Date(before)) : undefined)
        .orderBy(desc(auditLog.at))
        .limit(limit);
      return c.json({ items: rows.map((r) => AuditOut.parse(rowToPlain(r))) }, 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/v1/notifications',
      tags: ['notifications'],
      middleware: [requireUser()] as const,
      responses: { 200: { description: 'Own notifications', content: { 'application/json': { schema: z.object({ items: z.array(NotificationOut) }) } } } },
    }),
    async (c) => {
      const rows = await c.var.deps.db
        .select()
        .from(notifications)
        .where(eq(notifications.userId, c.var.user!.id))
        .orderBy(desc(notifications.at))
        .limit(200);
      return c.json({ items: rows.map((r) => NotificationOut.parse(rowToPlain(r))) }, 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'post',
      path: '/api/v1/notifications/{id}/read',
      tags: ['notifications'],
      middleware: [requireUser()] as const,
      request: { params: z.object({ id: z.uuid() }) },
      responses: { 204: { description: 'Marked read' } },
    }),
    async (c) => {
      await c.var.deps.db
        .update(notifications)
        .set({ read: true })
        .where(and(eq(notifications.id, c.req.valid('param').id), eq(notifications.userId, c.var.user!.id)));
      return c.body(null, 204);
    },
  );
}
