import { createCipheriv, createDecipheriv, createHash, randomBytes, timingSafeEqual } from 'node:crypto';

/**
 * Field encryption for sensitive data (AES-256-GCM). Output: "v1:<iv>:<tag>:<ciphertext>" (base64 parts).
 * `aad` binds the ciphertext to its row so it cannot be copied onto another member.
 */
export function encryptJson(value: unknown, keyB64: string, aad: string): string {
  const key = Buffer.from(keyB64, 'base64');
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  cipher.setAAD(Buffer.from(aad));
  const enc = Buffer.concat([cipher.update(JSON.stringify(value), 'utf8'), cipher.final()]);
  return ['v1', iv.toString('base64'), cipher.getAuthTag().toString('base64'), enc.toString('base64')].join(':');
}

export function decryptJson<T = unknown>(payload: string, keyB64: string, aad: string): T {
  const [version, ivB64, tagB64, dataB64] = payload.split(':');
  if (version !== 'v1' || !ivB64 || !tagB64 || dataB64 === undefined) throw new Error('Unsupported ciphertext');
  const decipher = createDecipheriv('aes-256-gcm', Buffer.from(keyB64, 'base64'), Buffer.from(ivB64, 'base64'));
  decipher.setAAD(Buffer.from(aad));
  decipher.setAuthTag(Buffer.from(tagB64, 'base64'));
  const dec = Buffer.concat([decipher.update(Buffer.from(dataB64, 'base64')), decipher.final()]);
  return JSON.parse(dec.toString('utf8')) as T;
}

export const randomToken = (bytes = 32) => randomBytes(bytes).toString('base64url');

export const sha256 = (value: string) => createHash('sha256').update(value).digest('hex');

export function safeEqual(a: string, b: string): boolean {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}
