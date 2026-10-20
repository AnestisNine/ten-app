import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { inquiries, lives, newsletterSubscribers, notifications } from '../db/schema.js';
import { Client, createTestApp } from './harness.js';

const SITE = 'https://thebonnienettles.test';
let t: Awaited<ReturnType<typeof createTestApp>>;
let site: Client;
beforeAll(async () => {
  t = await createTestApp();
  site = new Client(t.app, SITE);
});
afterAll(async () => t.close());

describe('public website API', () => {
  it('lists only confirmed upcoming shows, with CORS for the site', async () => {
    await t.db.update(lives).set({ ticketUrl: 'https://tickets.example/gagarin' }).where(eq(lives.venue, 'Gagarin 205'));
    const res = await site.get('/api/public/shows');
    expect(res.status).toBe(200);
    expect(res.headers.get('access-control-allow-origin')).toBe(SITE);
    expect(res.json.items.map((s: { venue: string }) => s.venue)).toEqual(['Gagarin 205']);
    expect(res.json.items[0].ticketUrl).toBe('https://tickets.example/gagarin');
    // No money or internal fields leak.
    expect(Object.keys(res.json.items[0]).sort()).toEqual(['city', 'country', 'countryCode', 'date', 'id', 'posterUrl', 'support', 'ticketUrl', 'venue']);
  });

  it('serves the poster of a confirmed show to the public', async () => {
    const { signInWith2fa } = await import('./harness.js');
    const manager = (await signInWith2fa(t.app, 'manager@tbn.local')).client;
    const live = (await site.get('/api/public/shows')).json.items[0];
    const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', 'base64');
    const form = new FormData();
    form.append('file', new File([png], 'poster.png', { type: 'image/png' }));
    const up = await manager.put(`/api/v1/lives/${live.id}/poster`, form);
    expect(up.status).toBe(200);
    expect((await manager.get(`/api/v1/lives/${live.id}`)).json.posterUrl).toBe(up.json.posterUrl);
    const shows = (await site.get('/api/public/shows')).json.items;
    expect(shows[0].posterUrl).toBe(`/api/public/shows/${live.id}/poster`);
    const img = await site.get(shows[0].posterUrl);
    expect(img.status).toBe(200);
    expect(img.headers.get('content-type')).toBe('image/png');
  });

  it('lists products without cost or stock numbers', async () => {
    const res = await site.get('/api/public/products');
    const tee = res.json.items.find((p: { name: string }) => p.name === 'TBN T-Shirt');
    expect(tee).toEqual({
      id: tee.id, name: 'TBN T-Shirt', priceCents: 2000, inStock: true, imageUrl: null,
      sizes: [
        { label: 'S', inStock: true }, { label: 'M', inStock: true }, { label: 'L', inStock: true }, { label: 'XL', inStock: false },
      ],
    });
    expect(res.json.items.find((p: { name: string }) => p.name === 'TBN Hoodie').inStock).toBe(false);
    // A single "One size" is not shown as a size.
    expect(res.json.items.find((p: { name: string }) => p.name === 'TBN Vinyl LP').sizes).toEqual([]);
  });

  it('stores contact messages and notifies admins/managers', async () => {
    const res = await site.post('/api/public/contact', {
      type: 'booking', name: 'Promoter', email: 'promo@example.com', message: 'Θέλουμε live τον Μάρτιο', locale: 'el',
    });
    expect(res.status).toBe(200);
    const rows = await t.db.select().from(inquiries);
    expect(rows).toHaveLength(1);
    const notes = await t.db.select().from(notifications);
    expect(notes.length).toBe(2); // admin + manager in the seed
    expect(notes[0]!.title).toContain('Booking');
  });

  it('rejects the honeypot, foreign origins and floods', async () => {
    const body = { type: 'general', name: 'Bot', email: 'b@example.com', message: 'spam' };
    expect((await site.post('/api/public/contact', { ...body, website: 'http://spam' })).status).toBe(422);
    expect((await new Client(t.app, 'https://evil.example').post('/api/public/contact', body)).status).toBe(403);
    const flood = new Client(t.app, SITE);
    const codes = [];
    for (let i = 0; i < 6; i++) codes.push((await flood.post('/api/public/contact', body)).status);
    expect(codes).toContain(429);
  });

  it('newsletter needs explicit consent and records it', async () => {
    expect((await site.post('/api/public/newsletter', { email: 'fan@example.com', consent: false })).status).toBe(422);
    expect((await site.post('/api/public/newsletter', { email: 'Fan@Example.com', consent: true, locale: 'en' })).status).toBe(200);
    expect((await site.post('/api/public/newsletter', { email: 'fan@example.com', consent: true, locale: 'en' })).status).toBe(200);
    const rows = await t.db.select().from(newsletterSubscribers);
    expect(rows).toHaveLength(1);
    expect(rows[0]!.email).toBe('fan@example.com');
    expect(rows[0]!.consentText).toMatch(/unsubscribe/);
  });
});
