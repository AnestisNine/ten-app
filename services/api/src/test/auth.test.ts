import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { session, user } from '../db/schema.js';
import { Client, createTestApp, signInWith2fa, totp } from './harness.js';

let t: Awaited<ReturnType<typeof createTestApp>>;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(async () => t.close());

describe('authentication', () => {
  it('rejects anonymous API access', async () => {
    const c = new Client(t.app);
    expect((await c.get('/api/v1/lives')).status).toBe(401);
    expect((await c.get('/api/v1/me')).status).toBe(401);
  });

  it('has no public sign-up', async () => {
    const c = new Client(t.app);
    const res = await c.post('/api/auth/sign-up/email', { email: 'x@example.com', password: 'long-enough-password', name: 'X' });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(await t.db.query.user.findFirst({ where: eq(user.email, 'x@example.com') })).toBeUndefined();
  });

  it('rejects a wrong password', async () => {
    const c = new Client(t.app);
    expect((await c.signIn('member@tbn.local', 'wrong-password')).status).toBe(401);
  });

  it('lets a member in without 2FA', async () => {
    const c = new Client(t.app);
    expect((await c.signIn('member@tbn.local')).status).toBe(200);
    const me = await c.get('/api/v1/me');
    expect(me.json.roles).toEqual(['member']);
    expect(me.json.twoFactorRequired).toBe(false);
    expect((await c.get('/api/v1/bootstrap')).status).toBe(200);
  });

  it('blocks roles that need 2FA until it is enabled, then requires the code at sign-in', async () => {
    const c = new Client(t.app);
    await c.signIn('accountant@tbn.local');
    const me = await c.get('/api/v1/me');
    expect(me.status).toBe(200);
    expect(me.json.twoFactorRequired).toBe(true);
    const blocked = await c.get('/api/v1/bootstrap');
    expect(blocked.status).toBe(403);
    expect(blocked.json.error).toBe('two_factor_required');

    const { client, secret } = await signInWith2fa(t.app, 'accountant@tbn.local');
    expect((await client.get('/api/v1/bootstrap')).status).toBe(200);

    // A fresh sign-in now stops at the second factor.
    const fresh = new Client(t.app);
    const res = await fresh.signIn('accountant@tbn.local');
    expect(res.json.twoFactorRedirect).toBe(true);
    expect((await fresh.get('/api/v1/me')).status).toBe(401);
    expect((await fresh.post('/api/auth/two-factor/verify-totp', { code: '000000' })).status).toBe(401);
    const ok = await fresh.post('/api/auth/two-factor/verify-totp', { code: totp(secret) });
    expect(ok.status).toBe(200);
    expect((await fresh.get('/api/v1/bootstrap')).status).toBe(200);
  });
});

describe('invitations and user management', () => {
  it('admin invites a user who sets a password from the email link', async () => {
    const { client: admin } = await signInWith2fa(t.app, 'admin@tbn.local');
    const invite = await admin.post('/api/v1/users', { name: 'Νέο Μέλος', email: 'New@Example.com', roles: ['member'] });
    expect(invite.status).toBe(201);
    expect(invite.json.emailVerified).toBe(false);

    const mail = t.mailer.sent.at(-1)!;
    expect(mail.to).toBe('new@example.com');
    expect(mail.subject).toMatch(/Πρόσκληση/);
    const token = new URL(mail.text.match(/http\S+/)![0]).searchParams.get('token')!;

    const anon = new Client(t.app);
    expect((await anon.post('/api/auth/reset-password', { token, newPassword: 'short' })).status).toBe(400);
    expect((await anon.post('/api/auth/reset-password', { token, newPassword: 'a-very-good-password' })).status).toBe(200);
    // Tokens are single use.
    expect((await anon.post('/api/auth/reset-password', { token, newPassword: 'another-good-password' })).status).toBe(400);

    const c = new Client(t.app);
    expect((await c.signIn('new@example.com', 'a-very-good-password')).status).toBe(200);
    const me = await c.get('/api/v1/me');
    expect(me.json.roles).toEqual(['member']);
    const row = await t.db.query.user.findFirst({ where: eq(user.email, 'new@example.com') });
    expect(row!.emailVerified).toBe(true);

    // Deactivation ends sessions and blocks sign-in.
    const deact = await admin.patch(`/api/v1/users/${row!.id}`, { active: false });
    expect(deact.status).toBe(200);
    expect((await c.get('/api/v1/me')).status).toBe(401);
    expect((await new Client(t.app).signIn('new@example.com', 'a-very-good-password')).status).not.toBe(200);
    expect(await t.db.select().from(session).where(eq(session.userId, row!.id))).toHaveLength(0);
  });

  it('only admins manage users, and roles cannot be self-assigned', async () => {
    const c = new Client(t.app);
    await c.signIn('member@tbn.local');
    expect((await c.get('/api/v1/users')).status).toBe(403);
    expect((await c.post('/api/v1/users', { name: 'x', email: 'y@example.com', roles: ['admin'] })).status).toBe(403);
    // Better Auth's update-user must not accept roles/active.
    await c.post('/api/auth/update-user', { roles: 'admin', active: true });
    expect((await c.get('/api/v1/me')).json.roles).toEqual(['member']);
  });

  it('rejects state-changing requests from a foreign origin', async () => {
    const c = new Client(t.app, 'https://evil.example');
    await new Client(t.app).signIn('member@tbn.local');
    await c.signIn('member@tbn.local');
    const res = await c.post('/api/v1/calendar-events', {
      startsAt: '2026-12-01T10:00:00Z', title: 'x', type: '', location: '', notes: '', visibility: 'team',
    });
    expect(res.status).toBe(403);
  });
});
