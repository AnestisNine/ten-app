import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Client, createTestApp } from './harness.js';

describe('preview mode (REQUIRE_TWO_FACTOR=false)', () => {
  let t: Awaited<ReturnType<typeof createTestApp>>;
  beforeAll(async () => {
    t = await createTestApp({ REQUIRE_TWO_FACTOR: 'false' });
  });
  afterAll(async () => t.close());

  it('lets admin work without enrolling 2FA', async () => {
    const admin = new Client(t.app);
    await admin.signIn('admin@tbn.local');
    const me = await admin.get('/api/v1/me');
    expect(me.json.twoFactorRequired).toBe(false);
    expect((await admin.get('/api/v1/bootstrap')).status).toBe(200);
    expect((await admin.get('/api/v1/users')).status).toBe(200);
  });
});
