import { createHmac } from 'node:crypto';
import postgres from 'postgres';
import { createApp } from '../app.js';
import { createAuth } from '../auth.js';
import { loadConfig } from '../config.js';
import { createDb } from '../db/client.js';
import { runMigrations } from '../db/migrate.js';
import { DEV_PASSWORD, seed } from '../db/seed.js';
import { MemoryMailer } from '../mailer.js';

export const TEST_DB_URL = process.env.TEST_DATABASE_URL ?? 'postgres://tbn:tbn@localhost:5432/tbn_test';
export const APP_URL = 'http://tbn.test';
export { DEV_PASSWORD };

export async function createTestApp() {
  // Fresh schema for every test file.
  const admin = postgres(TEST_DB_URL, { onnotice: () => {} });
  await admin.unsafe('DROP SCHEMA IF EXISTS public CASCADE; DROP SCHEMA IF EXISTS drizzle CASCADE; CREATE SCHEMA public;');
  await admin.end();
  await runMigrations(TEST_DB_URL);

  const config = loadConfig({
    NODE_ENV: 'test',
    DATABASE_URL: TEST_DB_URL,
    APP_URL,
    AUTH_SECRET: 'test-secret-test-secret-test-secret-0123456789',
    DATA_ENCRYPTION_KEY: Buffer.alloc(32, 7).toString('base64'),
    FILES_DIR: '/tmp/tbn-test-files',
    PUBLIC_SITE_ORIGINS: 'https://thebonnienettles.test',
  });
  const { db, sql } = createDb(TEST_DB_URL);
  await seed(db, config.DATA_ENCRYPTION_KEY);
  const mailer = new MemoryMailer();
  const auth = createAuth(config, db, mailer);
  const app = createApp({ config, db, auth, mailer });
  return { app, db, sql, mailer, config, close: () => sql.end() };
}

type App = Awaited<ReturnType<typeof createTestApp>>['app'];

/** A tiny cookie-jar client so tests behave like a browser on the app's origin. */
export class Client {
  private cookies = new Map<string, string>();
  constructor(
    private readonly app: App,
    private readonly origin: string | null = APP_URL,
  ) {}

  async request(method: string, path: string, body?: unknown, headers: Record<string, string> = {}) {
    const h: Record<string, string> = { ...headers };
    if (this.origin) h.origin = this.origin;
    if (this.cookies.size) h.cookie = [...this.cookies].map(([k, v]) => `${k}=${v}`).join('; ');
    let payload: BodyInit | undefined;
    if (body instanceof FormData) payload = body;
    else if (body !== undefined) {
      h['content-type'] = 'application/json';
      payload = JSON.stringify(body);
    }
    const res = await this.app.request(`${APP_URL}${path}`, { method, headers: h, body: payload });
    for (const c of res.headers.getSetCookie()) {
      const [pair] = c.split(';');
      const idx = pair!.indexOf('=');
      const name = pair!.slice(0, idx);
      const value = pair!.slice(idx + 1);
      if (value === '' || /max-age=0/i.test(c)) this.cookies.delete(name);
      else this.cookies.set(name, value);
    }
    const text = await res.text();
    let json: any = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = null;
    }
    return { status: res.status, json, text, headers: res.headers };
  }

  get = (p: string) => this.request('GET', p);
  post = (p: string, b?: unknown) => this.request('POST', p, b);
  patch = (p: string, b?: unknown) => this.request('PATCH', p, b);
  put = (p: string, b?: unknown) => this.request('PUT', p, b);
  del = (p: string) => this.request('DELETE', p);

  async signIn(email: string, password = DEV_PASSWORD) {
    return this.post('/api/auth/sign-in/email', { email, password });
  }
}

/** RFC 6238 TOTP (SHA-1, 30s, 6 digits) for driving the 2FA flow in tests. */
export function totp(secretBase32: string, now = Date.now()): string {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const ch of secretBase32.replace(/=+$/, '').toUpperCase()) bits += alphabet.indexOf(ch).toString(2).padStart(5, '0');
  const key = Buffer.from(bits.match(/.{8}/g)!.map((b) => parseInt(b, 2)));
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(now / 1000 / 30)));
  const hmac = createHmac('sha1', key).update(counter).digest();
  const offset = hmac[hmac.length - 1]! & 0xf;
  const code = (hmac.readUInt32BE(offset) & 0x7fffffff) % 1_000_000;
  return code.toString().padStart(6, '0');
}

/** Signs in a user whose role requires 2FA and enrolls TOTP. Returns the client and secret. */
export async function signInWith2fa(app: App, email: string) {
  const c = new Client(app);
  await c.signIn(email);
  const enable = await c.post('/api/auth/two-factor/enable', { password: DEV_PASSWORD });
  if (enable.status !== 200) throw new Error(`2FA enable failed: ${enable.text}`);
  const secret = new URL(enable.json.totpURI).searchParams.get('secret')!;
  const verify = await c.post('/api/auth/two-factor/verify-totp', { code: totp(secret) });
  if (verify.status !== 200) throw new Error(`2FA verify failed: ${verify.text}`);
  return { client: c, secret };
}
