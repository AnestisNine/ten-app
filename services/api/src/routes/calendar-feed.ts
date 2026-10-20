/**
 * Personal calendar subscription: each user can create a secret iCal URL and add it to Google
 * Calendar / Apple Calendar / Outlook. The feed shows what that user may see in the app
 * (lives + team events + their own private events). Only a hash of the token is stored;
 * rotating or deleting the feed invalidates the old URL.
 */
import { createRoute, z } from '@hono/zod-openapi';
import { can, parseRoles } from '@tbn/shared';
import { and, eq, gte, ne, or } from 'drizzle-orm';
import type { App } from '../context.js';
import { randomToken, sha256 } from '../crypto.js';
import { calendarEvents, calendarFeeds, lives, user } from '../db/schema.js';
import { buildCalendar, type IcsEvent } from '../ical.js';
import { requirePermission } from '../middleware.js';
import { writeAudit } from '../audit.js';

const STATUS_LABEL: Record<string, string> = {
  proposal: 'Πρόταση',
  negotiation: 'Διαπραγμάτευση',
  confirmed: '',
  completed: '',
  cancelled: 'Ακυρώθηκε',
};

const FeedOut = z.object({ active: z.boolean(), url: z.string().nullable() }).meta({ id: 'CalendarFeed' });

export function registerCalendarFeedRoutes(app: App) {
  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/v1/calendar/feed',
      tags: ['calendar'],
      middleware: [requirePermission('calendar', 'read')] as const,
      responses: { 200: { description: 'Feed status (URL is only shown when created)', content: { 'application/json': { schema: FeedOut } } } },
    }),
    async (c) => {
      const feed = await c.var.deps.db.query.calendarFeeds.findFirst({ where: eq(calendarFeeds.userId, c.var.user!.id) });
      return c.json({ active: Boolean(feed), url: null }, 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'post',
      path: '/api/v1/calendar/feed',
      tags: ['calendar'],
      middleware: [requirePermission('calendar', 'read')] as const,
      responses: { 200: { description: 'New feed URL (replaces any previous one)', content: { 'application/json': { schema: FeedOut } } } },
    }),
    async (c) => {
      const { db, config } = c.var.deps;
      const token = randomToken(32);
      const userId = c.var.user!.id;
      await db
        .insert(calendarFeeds)
        .values({ userId, tokenHash: sha256(token) })
        .onConflictDoUpdate({ target: calendarFeeds.userId, set: { tokenHash: sha256(token) } });
      await writeAudit(db, { user: c.var.user, entity: 'calendar.feed', entityId: userId, action: 'create', summary: 'rotate feed URL' });
      return c.json({ active: true, url: `${config.APP_URL}/ical/${token}.ics` }, 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'delete',
      path: '/api/v1/calendar/feed',
      tags: ['calendar'],
      middleware: [requirePermission('calendar', 'read')] as const,
      responses: { 204: { description: 'Feed disabled' } },
    }),
    async (c) => {
      await c.var.deps.db.delete(calendarFeeds).where(eq(calendarFeeds.userId, c.var.user!.id));
      return c.body(null, 204);
    },
  );
}

/** Public (token-authenticated) feed. Mounted outside the session-protected API. */
export function registerIcalFeed(app: App) {
  app.get('/ical/:file', async (c) => {
    const file = c.req.param('file');
    const token = file.endsWith('.ics') ? file.slice(0, -4) : '';
    if (!/^[A-Za-z0-9_-]{40,60}$/.test(token)) return c.notFound();
    const { db } = c.var.deps;
    const feed = await db.query.calendarFeeds.findFirst({ where: eq(calendarFeeds.tokenHash, sha256(token)) });
    if (!feed) return c.notFound();
    const owner = await db.query.user.findFirst({ where: eq(user.id, feed.userId) });
    if (!owner || !owner.active) return c.notFound();
    const roles = parseRoles(owner.roles);

    const since = new Date();
    since.setUTCFullYear(since.getUTCFullYear() - 1);
    const sinceDate = since.toISOString().slice(0, 10);
    const events: IcsEvent[] = [];

    if (can(roles, 'bookings', 'read')) {
      const rows = await db
        .select()
        .from(lives)
        .where(and(gte(lives.date, sinceDate), ne(lives.status, 'cancelled')));
      for (const l of rows) {
        const label = STATUS_LABEL[l.status] ?? '';
        events.push({
          uid: `live-${l.id}@tbn`,
          summary: `${label ? `[${label}] ` : ''}Live: ${l.venue}`,
          location: [l.venue, l.city, l.country].filter(Boolean).join(', '),
          date: l.date,
          updatedAt: l.updatedAt,
          status: l.status === 'confirmed' || l.status === 'completed' ? 'CONFIRMED' : 'TENTATIVE',
        });
      }
    }
    if (can(roles, 'calendar', 'read')) {
      const rows = await db
        .select()
        .from(calendarEvents)
        .where(
          and(
            gte(calendarEvents.startsAt, since),
            or(eq(calendarEvents.visibility, 'team'), eq(calendarEvents.ownerId, owner.id)),
          ),
        );
      for (const e of rows) {
        events.push({
          uid: `event-${e.id}@tbn`,
          summary: e.title,
          location: e.location,
          description: e.notes,
          start: e.startsAt,
          updatedAt: e.updatedAt,
        });
      }
    }
    c.header('Content-Type', 'text/calendar; charset=utf-8');
    c.header('Cache-Control', 'private, max-age=300');
    return c.body(buildCalendar('The Bonnie Nettles', events));
  });
}
