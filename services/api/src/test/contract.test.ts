/**
 * Posts the exact JSON the Flutter app produces (contract/app-payloads.json, written by
 * apps/manager/test/contract_test.dart) to the real endpoints, then PATCHes it back the way the app
 * does (everything except id). Order matters because of foreign keys.
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { Client, createTestApp, signInWith2fa } from './harness.js';

const payloads = JSON.parse(
  readFileSync(fileURLToPath(new URL('../../../../contract/app-payloads.json', import.meta.url)), 'utf8'),
) as Record<string, Record<string, unknown>>;

const ORDER = [
  'tours', 'lives', 'calendar-events', 'products', 'customers', 'orders', 'members',
  'streaming-incomes', 'general-expenses', 'rent-people', 'rent-payments',
];

let t: Awaited<ReturnType<typeof createTestApp>>;
let admin: Client;
beforeAll(async () => {
  t = await createTestApp();
  admin = (await signInWith2fa(t.app, 'admin@tbn.local')).client;
});
afterAll(async () => t.close());

describe('Flutter payload contract', () => {
  it('covers every entity the app writes', () => {
    expect(Object.keys(payloads).sort()).toEqual([...ORDER].sort());
  });

  for (const path of ORDER) {
    it(`POST and PATCH /api/v1/${path} accept the app's JSON`, async () => {
      const body = payloads[path]!;
      const created = await admin.post(`/api/v1/${path}`, body);
      expect(created.status, created.text).toBe(201);
      expect(created.json.id).toBe(body.id);
      const { id, ...rest } = body;
      const updated = await admin.patch(`/api/v1/${path}/${String(id)}`, rest);
      expect(updated.status, updated.text).toBe(200);
      for (const [k, v] of Object.entries(rest)) {
        if (k === 'startsAt') expect(new Date(updated.json[k]).getTime()).toBe(new Date(v as string).getTime());
        else expect(updated.json[k], k).toEqual(v);
      }
    });
  }
});
