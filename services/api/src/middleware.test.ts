import { describe, expect, it } from 'vitest';
import { originAllowed } from './middleware.js';

describe('originAllowed', () => {
  const patterns = ['http://localhost:8080', 'https://*.trycloudflare.com'];
  it.each([
    ['http://localhost:8080', true],
    ['https://blue-sky-123.trycloudflare.com', true],
    ['https://trycloudflare.com', false],
    ['https://a.b.trycloudflare.com', false],
    ['http://blue-sky.trycloudflare.com', false],
    ['https://evil.com', false],
    ['https://trycloudflare.com.evil.com', false],
    ['https://x.trycloudflare.com:444', false],
  ])('%s → %s', (origin, ok) => {
    expect(originAllowed(origin, patterns)).toBe(ok);
  });
});
