import { eq, sql } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLog, memberSensitive } from '../db/schema.js';
import { Client, createTestApp, signInWith2fa } from './harness.js';

let t: Awaited<ReturnType<typeof createTestApp>>;
let manager: Client;
let admin: Client;
let member: Client;
beforeAll(async () => {
  t = await createTestApp();
  manager = (await signInWith2fa(t.app, 'manager@tbn.local')).client;
  admin = (await signInWith2fa(t.app, 'admin@tbn.local')).client;
  member = new Client(t.app);
  await member.signIn('member@tbn.local');
});
afterAll(async () => t.close());

const newLive = {
  venue: 'Temple', city: 'Athens', country: 'Greece', countryCode: 'GR', lat: null, lon: null, date: '2026-12-12',
  status: 'proposal', tourId: null, cashIncomeCents: 0, merchIncomeCents: 0, soundExpensesCents: 0,
  extraExpensesCents: 0, doorDealCents: 0, fixCents: 50000, soundEngineerFeeCents: 0, technicianFeeCents: 0,
  supportBandFeeCents: 0, mainAct: 'TBN', support: '', contactPerson: '', soundEngineer: '', ticketsPresale: 0,
  ticketsDoor: 0, generalInfo: '', ticketUrl: null,
};

describe('CRUD with permissions and audit', () => {
  it('manager creates and updates a live; both are audited with the user', async () => {
    const created = await manager.post('/api/v1/lives', newLive);
    expect(created.status).toBe(201);
    const id = created.json.id;

    const updated = await manager.patch(`/api/v1/lives/${id}`, { status: 'confirmed', fixCents: 60000 });
    expect(updated.status).toBe(200);
    expect(updated.json.fixCents).toBe(60000);

    const entries = await t.db.select().from(auditLog).where(eq(auditLog.entityId, id));
    expect(entries.map((e) => e.action).sort()).toEqual(['create', 'update']);
    const upd = entries.find((e) => e.action === 'update')!;
    expect(upd.userName).toBe('Manager');
    expect(upd.diff).toEqual({ status: ['proposal', 'confirmed'], fixCents: [50000, 60000] });
  });

  it('rejects money as a float and unknown statuses', async () => {
    expect((await manager.post('/api/v1/lives', { ...newLive, fixCents: 500.5 })).status).toBe(422);
    expect((await manager.post('/api/v1/lives', { ...newLive, status: 'maybe' })).status).toBe(422);
  });

  it('members can read but not write bookings, and cannot see customers', async () => {
    expect((await member.get('/api/v1/lives')).status).toBe(200);
    expect((await member.post('/api/v1/lives', newLive)).status).toBe(403);
    expect((await member.get('/api/v1/customers')).status).toBe(403);
  });

  it('only admins delete; deleting a referenced product is a conflict', async () => {
    const lives = (await manager.get('/api/v1/lives')).json.items;
    expect((await manager.del(`/api/v1/lives/${lives[0].id}`)).status).toBe(403);
    expect((await admin.del(`/api/v1/lives/${lives[0].id}`)).status).toBe(204);

    const products = (await admin.get('/api/v1/products')).json.items;
    const tshirt = products.find((p: { name: string }) => p.name === 'TBN T-Shirt');
    expect((await admin.del(`/api/v1/products/${tshirt.id}`)).status).toBe(409);
  });

  it('assigns sequential order numbers', async () => {
    const orders = (await manager.get('/api/v1/orders')).json.items;
    expect(orders.map((o: { number: number }) => o.number)).toEqual([1001, 1002, 1003]);
    const o = orders[0];
    const created = await manager.post('/api/v1/orders', {
      customerId: o.customerId, productId: o.productId, quantity: 1, shippingCostCents: 0, shippingMethod: 'acs',
      status: 'waitingContact', source: 'organic', context: 'afterLive', trackingNumber: '', notes: '',
    });
    expect(created.status).toBe(201);
    expect(created.json.number).toBe(1004);
  });

  it('audit log is append-only even for the database owner', async () => {
    await expect(t.db.execute(sql`UPDATE audit_log SET summary = 'x'`)).rejects.toThrow();
    await expect(t.db.execute(sql`DELETE FROM audit_log`)).rejects.toThrow();
  });
});

describe('calendar privacy', () => {
  it('creates and moves an event (timestamps from ISO strings), owned by the creator', async () => {
    const created = await member.post('/api/v1/calendar-events', {
      startsAt: '2026-12-01T10:00:00.000Z', title: 'Ραντεβού', type: 'Personal', location: '', notes: '', visibility: 'private',
    });
    expect(created.status).toBe(201);
    expect(created.json.startsAt).toBe('2026-12-01T10:00:00.000Z');
    const me = await member.get('/api/v1/me');
    expect(created.json.ownerId).toBe(me.json.id);
    const moved = await member.patch(`/api/v1/calendar-events/${created.json.id}`, { startsAt: '2026-12-02T09:30:00+02:00' });
    expect(moved.status).toBe(200);
    expect(moved.json.startsAt).toBe('2026-12-02T07:30:00.000Z');
  });


  it('private events are visible and deletable only by their owner', async () => {
    const memberEvents = (await member.get('/api/v1/calendar-events')).json.items;
    const priv = memberEvents.find((e: { visibility: string }) => e.visibility === 'private');
    expect(priv).toBeDefined();

    const managerEvents = (await manager.get('/api/v1/calendar-events')).json.items;
    expect(managerEvents.some((e: { id: string }) => e.id === priv.id)).toBe(false);
    expect((await manager.get(`/api/v1/calendar-events/${priv.id}`)).status).toBe(404);

    // A member may delete their own event but not someone else's team event.
    const team = memberEvents.find((e: { visibility: string }) => e.visibility === 'team');
    expect((await member.del(`/api/v1/calendar-events/${team.id}`)).status).toBe(403);
    expect((await member.del(`/api/v1/calendar-events/${priv.id}`)).status).toBe(204);
  });
});

describe('sensitive member data', () => {
  it('is admin-only, encrypted at rest and every read is audited', async () => {
    const members = (await admin.get('/api/v1/members')).json.items;
    const m = members.find((x: { email: string }) => x.email === 'member@tbn.local');
    expect((await manager.get(`/api/v1/members/${m.id}/sensitive`)).status).toBe(403);
    expect((await member.get(`/api/v1/members/${m.id}/sensitive`)).status).toBe(403);

    const res = await admin.get(`/api/v1/members/${m.id}/sensitive`);
    expect(res.status).toBe(200);
    expect(res.json.amka).toBe('01019000000');
    expect(res.headers.get('cache-control')).toBe('no-store');

    const row = await t.db.query.memberSensitive.findFirst({ where: eq(memberSensitive.memberId, m.id) });
    expect(row!.ciphertext).not.toContain('01019000000');

    const reads = await t.db.select().from(auditLog).where(eq(auditLog.entity, 'members.sensitive'));
    expect(reads.some((r) => r.action === 'read' && r.entityId === m.id)).toBe(true);
    expect(JSON.stringify(reads)).not.toContain('01019000000');

    expect((await admin.put(`/api/v1/members/${m.id}/sensitive`, { ...res.json, iban: 'GR11' })).status).toBe(204);
    expect((await admin.get(`/api/v1/members/${m.id}/sensitive`)).json.iban).toBe('GR11');
  });
});

describe('calendar subscription feed', () => {
  it('serves lives and team events, hides others\' private events, and rotates', async () => {
    const created = await manager.post('/api/v1/calendar/feed');
    expect(created.status).toBe(200);
    const path = new URL(created.json.url).pathname;

    const anon = new Client(t.app, null);
    const feed = await anon.get(path);
    expect(feed.status).toBe(200);
    expect(feed.headers.get('content-type')).toMatch(/text\/calendar/);
    expect(feed.text).toContain('BEGIN:VCALENDAR');
    expect(feed.text).toContain('Live: Gagarin 205');
    expect(feed.text).toContain('Studio Session');
    expect(feed.text).not.toContain('Γιατρός');

    const rotated = await manager.post('/api/v1/calendar/feed');
    expect((await anon.get(path)).status).toBe(404);
    expect((await anon.get(new URL(rotated.json.url).pathname)).status).toBe(200);
    expect((await anon.get('/ical/not-a-token.ics')).status).toBe(404);
  });
});

describe('product images', () => {
  it('accepts real images only and serves them to readers', async () => {
    const products = (await manager.get('/api/v1/products')).json.items;
    const id = products[0].id;
    const fake = new FormData();
    fake.append('file', new File([new TextEncoder().encode('<script>alert(1)</script>')], 'x.png', { type: 'image/png' }));
    expect((await manager.put(`/api/v1/products/${id}/image`, fake)).status).toBe(422);

    const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', 'base64');
    const form = new FormData();
    form.append('file', new File([png], 'p.png', { type: 'image/png' }));
    const up = await manager.put(`/api/v1/products/${id}/image`, form);
    expect(up.status).toBe(200);
    const img = await member.get(up.json.imageUrl);
    expect(img.status).toBe(200);
    expect(img.headers.get('content-type')).toBe('image/png');
    expect((await member.get(`/api/v1/products/${id}`)).json.imageUrl).toBe(up.json.imageUrl);
  });
});
