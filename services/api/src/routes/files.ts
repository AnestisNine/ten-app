import { createRoute, z } from '@hono/zod-openapi';
import { can, type Resource } from '@tbn/shared';
import { eq } from 'drizzle-orm';
import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import type { App } from '../context.js';
import { files, lives, products } from '../db/schema.js';
import { writeAudit } from '../audit.js';
import { ApiError } from '../errors.js';
import { clientIp, requirePermission } from '../middleware.js';

const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

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

interface ImageTarget {
  /** e.g. /api/v1/products/{id}/image */
  path: string;
  tag: string;
  table: typeof products | typeof lives;
  column: 'imageFileId' | 'posterFileId';
  resource: Resource;
  /** Sub-folder under FILES_DIR and audit entity name. */
  folder: string;
  responseKey: 'imageUrl' | 'posterUrl';
}

/** PUT multipart image for one row: stores the file, points the row at it, removes the old file. */
function registerImageUpload(app: App, target: ImageTarget) {
  app.openapi(
    createRoute({
      method: 'put',
      path: target.path,
      tags: [target.tag],
      middleware: [requirePermission(target.resource, 'write')] as const,
      request: {
        params: z.object({ id: z.uuid() }),
        body: { content: { 'multipart/form-data': { schema: z.object({ file: z.any() }) } }, required: true },
      },
      responses: {
        200: {
          description: 'Image stored',
          content: { 'application/json': { schema: z.record(z.string(), z.string()) } },
        },
      },
    }),
    async (c) => {
      const { db, config } = c.var.deps;
      const { id } = c.req.valid('param');
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const table = target.table as any;
      const [row] = (await db.select().from(table).where(eq(table.id, id)).limit(1)) as Record<string, unknown>[];
      if (!row) throw new ApiError('not_found');
      const body = await c.req.parseBody();
      const file = body.file;
      if (!(file instanceof File)) throw new ApiError('validation_failed', 'Missing file');
      if (file.size > MAX_IMAGE_BYTES) throw new ApiError('validation_failed', 'Image larger than 10 MB');
      const buf = new Uint8Array(await file.arrayBuffer());
      const mime = sniffImage(buf);
      if (!mime) throw new ApiError('validation_failed', 'Only JPEG, PNG or WebP images');

      const fileId = randomUUID();
      const key = join(target.folder, `${fileId}.${mime.split('/')[1]}`);
      const dir = resolve(config.FILES_DIR);
      await mkdir(join(dir, target.folder), { recursive: true });
      await writeFile(join(dir, key), buf);
      const oldFileId = row[target.column] as string | null;
      await db.transaction(async (tx) => {
        await tx.insert(files).values({
          id: fileId,
          ownerId: c.var.user!.id,
          resource: target.resource,
          mimeType: mime,
          sizeBytes: buf.length,
          storageKey: key,
          originalName: file.name.slice(0, 200),
        });
        await tx.update(table).set({ [target.column]: fileId }).where(eq(table.id, id));
        await writeAudit(tx, { user: c.var.user, entity: target.folder, entityId: id, action: 'update', summary: target.responseKey, ip: clientIp(c) });
      });
      if (oldFileId) {
        const old = await db.query.files.findFirst({ where: eq(files.id, oldFileId) });
        if (old) {
          await db.delete(files).where(eq(files.id, oldFileId));
          await unlink(join(dir, old.storageKey)).catch(() => {});
        }
      }
      return c.json({ [target.responseKey]: `/api/v1/files/${fileId}` }, 200);
    },
  );
}

export function registerFileRoutes(app: App) {
  registerImageUpload(app, {
    path: '/api/v1/products/{id}/image',
    tag: 'products',
    table: products,
    column: 'imageFileId',
    resource: 'merch',
    folder: 'products',
    responseKey: 'imageUrl',
  });
  registerImageUpload(app, {
    path: '/api/v1/lives/{id}/poster',
    tag: 'lives',
    table: lives,
    column: 'posterFileId',
    resource: 'bookings',
    folder: 'lives',
    responseKey: 'posterUrl',
  });

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
