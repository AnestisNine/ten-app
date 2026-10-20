/**
 * Sensitive member data (ΑΦΜ, ΑΜΚΑ, IBAN, passport...). Admin only, encrypted at rest,
 * and every read and write is recorded in the audit log (without the values).
 */
import { createRoute, z } from '@hono/zod-openapi';
import { MemberSensitive } from '@tbn/shared';
import { eq } from 'drizzle-orm';
import type { App } from '../context.js';
import { decryptJson, encryptJson } from '../crypto.js';
import { memberSensitive, members } from '../db/schema.js';
import { writeAudit } from '../audit.js';
import { ApiError } from '../errors.js';
import { clientIp, requirePermission } from '../middleware.js';

const Schema = MemberSensitive.meta({ id: 'MemberSensitive' });
const EMPTY = MemberSensitive.parse(Object.fromEntries(Object.keys(MemberSensitive.shape).map((k) => [k, ''])));
const IdParam = z.object({ id: z.uuid() });
const aadFor = (memberId: string) => `member_sensitive:${memberId}`;

export function registerMemberSensitiveRoutes(app: App) {
  app.openapi(
    createRoute({
      method: 'get',
      path: '/api/v1/members/{id}/sensitive',
      tags: ['members'],
      middleware: [requirePermission('membersSensitive', 'read')] as const,
      request: { params: IdParam },
      responses: { 200: { description: 'Sensitive data', content: { 'application/json': { schema: Schema } } } },
    }),
    async (c) => {
      const { db, config } = c.var.deps;
      const { id } = c.req.valid('param');
      const member = await db.query.members.findFirst({ where: eq(members.id, id) });
      if (!member) throw new ApiError('not_found');
      const row = await db.query.memberSensitive.findFirst({ where: eq(memberSensitive.memberId, id) });
      const data = row ? MemberSensitive.parse(decryptJson(row.ciphertext, config.DATA_ENCRYPTION_KEY, aadFor(id))) : EMPTY;
      await writeAudit(db, {
        user: c.var.user,
        entity: 'members.sensitive',
        entityId: id,
        action: 'read',
        summary: `${member.name} ${member.surname}`.trim(),
        ip: clientIp(c),
      });
      c.header('Cache-Control', 'no-store');
      return c.json(data, 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'put',
      path: '/api/v1/members/{id}/sensitive',
      tags: ['members'],
      middleware: [requirePermission('membersSensitive', 'write')] as const,
      request: { params: IdParam, body: { content: { 'application/json': { schema: Schema } }, required: true } },
      responses: { 204: { description: 'Saved' } },
    }),
    async (c) => {
      const { db, config } = c.var.deps;
      const { id } = c.req.valid('param');
      const input = c.req.valid('json');
      const member = await db.query.members.findFirst({ where: eq(members.id, id) });
      if (!member) throw new ApiError('not_found');
      const ciphertext = encryptJson(input, config.DATA_ENCRYPTION_KEY, aadFor(id));
      await db.transaction(async (tx) => {
        await tx
          .insert(memberSensitive)
          .values({ memberId: id, ciphertext })
          .onConflictDoUpdate({ target: memberSensitive.memberId, set: { ciphertext } });
        await writeAudit(tx, {
          user: c.var.user,
          entity: 'members.sensitive',
          entityId: id,
          action: 'update',
          // Only which fields are filled in, never the values.
          summary: `fields set: ${Object.entries(input).filter(([, v]) => v !== '').map(([k]) => k).join(', ') || 'none'}`,
          ip: clientIp(c),
        });
      });
      return c.body(null, 204);
    },
  );
}
