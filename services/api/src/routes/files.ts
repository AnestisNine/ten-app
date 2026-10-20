import { createRoute, z } from '@hono/zod-openapi';
import { can, type Resource } from '@tbn/shared';
import { eq } from 'drizzle-orm';
import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import type { App } from '../context.js';
import { files, products } from '../db/schema.js';
import { writeAudit } from '../audit.js';
import { ApiError } from '../errors.js';
import { clientIp, requirePermission } from '../middleware.js';

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

/** Identify images by content, not by the client-supplied type or name. */
export function sniffImage(buf: Uint8Array): 'image/jpeg' | 'image/png' | 'image/webp' | null {
  if (buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return 'image/jpeg';
  if (buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47) return 'image/png';
  if (
    buf[0] === 0x52 && buf[1] === 0x49 && buf[2] === 0x46 && buf[3] === 0x46 &&
    buf[8] === 0x57 && buf[9] === 0x45 && buf[10] === 0x42 && buf[11] === 0x50
  ) {
    return 'image/webp';
  }
  return null;
}

export function registerFileRoutes(app: App) {
  app.openapi(
    createRoute({
      method: 'put',
      path: '/api/v1/products/{id}/image',
      tags: ['products'],
      middleware: [requirePermission('merch', 'write')] as const,
      request: {
        params: z.object({ id: z.uuid() }),
        body: { content: { 'multipart/form-data': { schema: z.object({ file: z.any() }) } }, required: true },
      },
      responses: { 200: { description: 'Image stored', content: { 'application/json': { schema: z.object({ imageUrl: z.string() }) } } } },
    }),
    async (c) => {
      const { db, config } = c.var.deps;
      const { id } = c.req.valid('param');
      const product = await db.query.products.findFirst({ where: eq(products.id, id) });
      if (!product) throw new ApiError('not_found');
      const body = await c.req.parseBody();
      const file = body.file;
      if (!(file instanceof File)) throw new ApiError('validation_failed', 'Missing file');
      if (file.size > MAX_IMAGE_BYTES) throw new ApiError('validation_failed', 'Image larger than 5 MB');
      const buf = new Uint8Array(await file.arrayBuffer());
      const mime = sniffImage(buf);
      if (!mime) throw new ApiError('validation_failed', 'Only JPEG, PNG or WebP images');

      const fileId = randomUUID();
      const key = join('products', `${fileId}.${mime.split('/')[1]}`);
      const dir = resolve(config.FILES_DIR);
      await mkdir(join(dir, 'products'), { recursive: true });
      await writeFile(join(dir, key), buf);
      const oldFileId = product.imageFileId;
      await db.transaction(async (tx) => {
        await tx.insert(files).values({
          id: fileId,
          ownerId: c.var.user!.id,
          resource: 'merch',
          mimeType: mime,
          sizeBytes: buf.length,
          storageKey: key,
          originalName: file.name.slice(0, 200),
        });
        await tx.update(products).set({ imageFileId: fileId }).where(eq(products.id, id));
        await writeAudit(tx, { user: c.var.user, entity: 'products', entityId: id, action: 'update', summary: 'image', ip: clientIp(c) });
      });
      if (oldFileId) {
        const old = await db.query.files.findFirst({ where: eq(files.id, oldFileId) });
        if (old) {
          await db.delete(files).where(eq(files.id, oldFileId));
          await unlink(join(dir, old.storageKey)).catch(() => {});
        }
      }
      return c.json({ imageUrl: `/api/v1/files/${fileId}` }, 200);
    },
  );

  app.get('/api/v1/files/:id', async (c) => {
    const id = c.req.param('id');
    if (!z.uuid().safeParse(id).success) throw new ApiError('not_found');
    const { db, config } = c.var.deps;
    const row = await db.query.files.findFirst({ where: eq(files.id, id) });
    if (!row) throw new ApiError('not_found');
    if (!can(c.var.user!.roles, row.resource as Resource, 'read')) throw new ApiError('forbidden');
    const data = await readFile(join(resolve(config.FILES_DIR), row.storageKey));
    c.header('Content-Type', row.mimeType);
    c.header('Cache-Control', 'private, max-age=86400, immutable');
    c.header('X-Content-Type-Options', 'nosniff');
    return c.body(data);
  });
}
