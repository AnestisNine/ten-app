/**
 * Read-only data and forms for the public website (thebonnienettles.com). No authentication;
 * exposes only what is meant to be public: confirmed upcoming shows, product names/prices/images.
 * Forms are rate limited per IP and have a honeypot field.
 */
import { createRoute, z } from '@hono/zod-openapi';
import { ContactRequest, NewsletterRequest, PublicProduct, PublicShow, parseRoles } from '@tbn/shared';
import { and, asc, eq, gte, isNull } from 'drizzle-orm';
import { readFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { cors } from 'hono/cors';
import { createMiddleware } from 'hono/factory';
import { splitList } from '../config.js';
import type { App, AppEnv } from '../context.js';
import { files, inquiries, lives, newsletterSubscribers, notifications, products, user } from '../db/schema.js';
import { ApiError } from '../errors.js';
import { clientIp } from '../middleware.js';

/** Fixed-window limiter in memory (one API process). */
export function rateLimit(max: number, windowMs: number) {
  const hits = new Map<string, { count: number; reset: number }>();
  return createMiddleware<AppEnv>(async (c, next) => {
    const key = `${c.req.path}:${clientIp(c) ?? 'unknown'}`;
    const now = Date.now();
    const entry = hits.get(key);
    if (!entry || entry.reset < now) {
      hits.set(key, { count: 1, reset: now + windowMs });
    } else if (++entry.count > max) {
      c.header('Retry-After', String(Math.ceil((entry.reset - now) / 1000)));
      return c.json({ error: 'rate_limited', message: 'Too many requests' }, 429);
    }
    if (hits.size > 10_000) for (const [k, v] of hits) if (v.reset < now) hits.delete(k);
    await next();
  });
}

const today = () => new Date().toISOString().slice(0, 10);
const ShowOut = PublicShow.meta({ id: 'PublicShow' });
const ProductOut = PublicProduct.meta({ id: 'PublicProduct' });
const Ok = z.object({ ok: z.literal(true) });

const NEWSLETTER_CONSENT = {
  el: 'Θέλω να λαμβάνω email από τους The Bonnie Nettles για νέα, συναυλίες και merch. Μπορώ να διαγραφώ οποτεδήποτε.',
  en: 'I want to receive emails from The Bonnie Nettles about news, shows and merch. I can unsubscribe at any time.',
};

export function registerPublicRoutes(app: App) {
  app.use('/api/public/*', async (c, next) => {
    const { config } = c.var.deps;
    const origins = splitList(config.PUBLIC_SITE_ORIGINS);
    return cors({ origin: origins, allowMethods: ['GET', 'POST'], maxAge: 86400 })(c, next);
  });
  // Browsers always send Origin on cross-site POSTs: only the website may submit the forms.
  app.use('/api/public/*', async (c, next) => {
    if (c.req.method === 'POST') {
      const origin = c.req.header('origin');
      const allowed = splitList(c.var.deps.config.PUBLIC_SITE_ORIGINS);
      if (origin && !allowed.includes(origin)) throw new ApiError('bad_origin');
    }
    await next();
  });

  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/public/shows',
      tags: ['public'],
      responses: { 200: { description: 'Upcoming confirmed shows', content: { 'application/json': { schema: z.object({ items: z.array(ShowOut) }) } } } },
    }),
    async (c) => {
      const rows = await c.var.deps.db
        .select()
        .from(lives)
        .where(and(eq(lives.status, 'confirmed'), gte(lives.date, today())))
        .orderBy(asc(lives.date));
      c.header('Cache-Control', 'public, max-age=300');
      return c.json(
        {
          items: rows.map((l) =>
            ShowOut.parse({
              id: l.id,
              date: l.date,
              venue: l.venue,
              city: l.city,
              country: l.country,
              countryCode: l.countryCode,
              support: l.support,
              ticketUrl: l.ticketUrl || null,
            }),
          ),
        },
        200,
      );
    },
  );

  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/public/products',
      tags: ['public'],
      responses: { 200: { description: 'Merch catalogue', content: { 'application/json': { schema: z.object({ items: z.array(ProductOut) }) } } } },
    }),
    async (c) => {
      const rows = await c.var.deps.db.select().from(products).orderBy(asc(products.name));
      c.header('Cache-Control', 'public, max-age=300');
      return c.json(
        {
          items: rows.map((p) =>
            ProductOut.parse({
              id: p.id,
              name: p.name,
              priceCents: p.salePriceCents,
              inStock: p.stock > 0,
              imageUrl: p.imageFileId ? `/api/public/products/${p.id}/image` : null,
            }),
          ),
        },
        200,
      );
    },
  );

  app.get('/api/public/products/:id/image', async (c) => {
    const id = c.req.param('id');
    if (!z.uuid().safeParse(id).success) return c.notFound();
    const { db, config } = c.var.deps;
    const product = await db.query.products.findFirst({ where: eq(products.id, id) });
    if (!product?.imageFileId) return c.notFound();
    const file = await db.query.files.findFirst({ where: eq(files.id, product.imageFileId) });
    if (!file) return c.notFound();
    const data = await readFile(join(resolve(config.FILES_DIR), file.storageKey));
    c.header('Content-Type', file.mimeType);
    c.header('Cache-Control', 'public, max-age=86400');
    c.header('Cross-Origin-Resource-Policy', 'cross-origin');
    return c.body(data);
  });

  app.openapi(
    createRoute({
      method: 'post',
      path: '/api/public/contact',
      tags: ['public'],
      middleware: [rateLimit(5, 10 * 60_000)] as const,
      request: { body: { content: { 'application/json': { schema: ContactRequest } }, required: true } },
      responses: { 200: { description: 'Received', content: { 'application/json': { schema: Ok } } } },
    }),
    async (c) => {
      const input = c.req.valid('json');
      const { db } = c.var.deps;
      await db.transaction(async (tx) => {
        await tx.insert(inquiries).values({
          type: input.type,
          name: input.name,
          email: input.email,
          phone: input.phone,
          subject: input.subject,
          message: input.message,
          locale: input.locale,
        });
        // Tell the people who handle bookings.
        const staff = (await tx.select().from(user).where(eq(user.active, true))).filter((u) =>
          parseRoles(u.roles).some((r) => r === 'admin' || r === 'manager'),
        );
        const label = { booking: 'Booking', press: 'Press', general: 'Μήνυμα' }[input.type];
        for (const u of staff) {
          await tx.insert(notifications).values({
            userId: u.id,
            title: `${label} από το site: ${input.name}`,
            body: `${input.email}${input.phone ? ` · ${input.phone}` : ''}\n${input.subject ? `${input.subject}\n` : ''}${input.message}`,
          });
        }
      });
      return c.json({ ok: true as const }, 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'post',
      path: '/api/public/newsletter',
      tags: ['public'],
      middleware: [rateLimit(5, 10 * 60_000)] as const,
      request: { body: { content: { 'application/json': { schema: NewsletterRequest } }, required: true } },
      responses: { 200: { description: 'Subscribed (same answer whether or not the email was already there)', content: { 'application/json': { schema: Ok } } } },
    }),
    async (c) => {
      const input = c.req.valid('json');
      const email = input.email.toLowerCase();
      const now = new Date();
      await c.var.deps.db
        .insert(newsletterSubscribers)
        .values({ email, locale: input.locale, consentAt: now, consentText: NEWSLETTER_CONSENT[input.locale] })
        .onConflictDoUpdate({
          target: newsletterSubscribers.email,
          set: { locale: input.locale, consentAt: now, consentText: NEWSLETTER_CONSENT[input.locale], unsubscribedAt: null },
          where: isNull(newsletterSubscribers.confirmedAt),
        });
      return c.json({ ok: true as const }, 200);
    },
  );
}
