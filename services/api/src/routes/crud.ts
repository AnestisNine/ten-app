/**
 * Generic CRUD routes for the Phase 1 entities. Every route checks the role permission for the
 * entity's resource, validates input with the shared zod schema, and writes an audit entry in the
 * same transaction as the change.
 */
import { createRoute, z } from '@hono/zod-openapi';
import type { Action, Resource } from '@tbn/shared';
import { can } from '@tbn/shared';
import { and, asc, eq, type SQL } from 'drizzle-orm';
import type { PgColumn, PgTable } from 'drizzle-orm/pg-core';
import type { App, CurrentUser } from '../context.js';
import { diffObjects, writeAudit } from '../audit.js';
import { ApiError, mapDbError } from '../errors.js';
import { clientIp, requirePermission } from '../middleware.js';

type Row = Record<string, unknown>;
type DbOrTx = Parameters<typeof writeAudit>[0];
type ApiObject = Record<string, unknown> & { id: string };
// Drizzle's generic table types do not survive being passed around as values; the factory
// works on rows as plain records and relies on zod for the shape of what goes in and out.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyTable = PgTable & { id: PgColumn } & Record<string, any>;

export interface EntityDef {
  /** OpenAPI component name, e.g. "Live". */
  name: string;
  /** URL segment, e.g. "lives". */
  path: string;
  table: AnyTable;
  resource: Resource;
  schema: z.ZodObject;
  create: z.ZodObject;
  /** Short human label for audit summaries. */
  label: (obj: ApiObject) => string;
  /** Default ordering column. */
  orderBy?: PgColumn;
  toApi?: (row: Row) => Row | Promise<Row>;
  toDb?: (input: Row, user: CurrentUser, existing?: ApiObject) => Row;
  /** Extra row filter for reads (e.g. hide other users' private events). */
  readScope?: (user: CurrentUser) => SQL | undefined;
  /**
   * Per-row authorization. For 'write' it applies on top of the role's write permission; for
   * 'delete' it replaces the role check entirely, so it must include it.
   */
  canModify?: (user: CurrentUser, obj: ApiObject, action: Exclude<Action, 'read'>) => boolean;
}

/** Dates → ISO strings so the API schema can validate (and strip) the row. */
export function rowToPlain(row: Row): Row {
  const out: Row = {};
  for (const [k, v] of Object.entries(row)) out[k] = v instanceof Date ? v.toISOString() : v;
  return out;
}

const IdParam = z.object({ id: z.uuid() });
const errorSchema = z.object({ error: z.string(), message: z.string(), details: z.unknown().optional() });
const errors = {
  401: { description: 'Not signed in', content: { 'application/json': { schema: errorSchema } } },
  403: { description: 'Not allowed', content: { 'application/json': { schema: errorSchema } } },
};

/** Read helpers for one entity, shared by the CRUD routes and the bootstrap endpoint. */
export function entityReader(def: EntityDef) {
  const schema = def.schema.meta({ id: def.name });
  const t = def.table;

  const toApi = async (row: Row): Promise<ApiObject> => {
    const mapped = def.toApi ? await def.toApi(row) : row;
    return schema.parse(rowToPlain(mapped)) as ApiObject;
  };

  const whereFor = (user: CurrentUser, extra?: SQL) => {
    const scope = def.readScope?.(user);
    return scope && extra ? and(scope, extra) : (scope ?? extra);
  };

  const list = async (db: DbOrTx, user: CurrentUser) => {
    const q = db.select().from(t).where(whereFor(user));
    const rows = (await (def.orderBy ? q.orderBy(asc(def.orderBy)) : q)) as Row[];
    return Promise.all(rows.map(toApi));
  };

  const findOne = async (db: DbOrTx, user: CurrentUser, id: string) => {
    const rows = (await db.select().from(t).where(whereFor(user, eq(t.id, id))).limit(1)) as Row[];
    const row = rows[0];
    if (!row) throw new ApiError('not_found');
    return toApi(row);
  };

  return { schema, toApi, list, findOne };
}

export function registerCrud(app: App, def: EntityDef) {
  const { schema, toApi, list, findOne } = entityReader(def);
  const createSchema = def.create.meta({ id: `${def.name}Create` });
  const updateSchema = def.create.omit({ id: true }).partial().meta({ id: `${def.name}Update` });
  const t = def.table;

  const assertModify = (user: CurrentUser, obj: ApiObject, action: 'write' | 'delete') => {
    if (def.canModify && !def.canModify(user, obj, action)) throw new ApiError('forbidden');
  };

  const tag = [def.path];

  app.openapi(
    createRoute({
      method: 'get',
      path: `/api/v1/${def.path}`,
      tags: tag,
      middleware: [requirePermission(def.resource, 'read')] as const,
      responses: {
        200: { description: 'List', content: { 'application/json': { schema: z.object({ items: z.array(schema) }) } } },
        ...errors,
      },
    }),
    async (c) => {
      return c.json({ items: await list(c.var.deps.db, c.var.user!) }, 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'get',
      path: `/api/v1/${def.path}/{id}`,
      tags: tag,
      middleware: [requirePermission(def.resource, 'read')] as const,
      request: { params: IdParam },
      responses: { 200: { description: 'One', content: { 'application/json': { schema } } }, ...errors },
    }),
    async (c) => {
      const obj = await findOne(c.var.deps.db, c.var.user!, c.req.valid('param').id);
      return c.json(obj, 200);
    },
  );

  app.openapi(
    createRoute({
      method: 'post',
      path: `/api/v1/${def.path}`,
      tags: tag,
      middleware: [requirePermission(def.resource, 'write')] as const,
      request: { body: { content: { 'application/json': { schema: createSchema } }, required: true } },
      responses: { 201: { description: 'Created', content: { 'application/json': { schema } } }, ...errors },
    }),
    async (c) => {
      const { db } = c.var.deps;
      const user = c.var.user!;
      const input = c.req.valid('json') as Row;
      const values = def.toDb ? def.toDb(input, user) : input;
      try {
        const created = await db.transaction(async (tx) => {
          const [row] = (await tx.insert(t).values(values).returning()) as Row[];
          const obj = await toApi(row!);
          assertModify(user, obj, 'write');
          await writeAudit(tx, {
            user,
            entity: def.path,
            entityId: obj.id,
            action: 'create',
            summary: def.label(obj),
            ip: clientIp(c),
          });
          return obj;
        });
        return c.json(created, 201);
      } catch (err) {
        throw mapDbError(err) ?? err;
      }
    },
  );

  app.openapi(
    createRoute({
      method: 'patch',
      path: `/api/v1/${def.path}/{id}`,
      tags: tag,
      middleware: [requirePermission(def.resource, 'write')] as const,
      request: {
        params: IdParam,
        body: { content: { 'application/json': { schema: updateSchema } }, required: true },
      },
      responses: { 200: { description: 'Updated', content: { 'application/json': { schema } } }, ...errors },
    }),
    async (c) => {
      const { db } = c.var.deps;
      const user = c.var.user!;
      const { id } = c.req.valid('param');
      const input = c.req.valid('json') as Row;
      try {
        const updated = await db.transaction(async (tx) => {
          const before = await findOne(tx, user, id);
          assertModify(user, before, 'write');
          const values = def.toDb ? def.toDb(input, user, before) : input;
          const [row] = (await tx.update(t).set(values).where(eq(t.id, id)).returning()) as Row[];
          const after = await toApi(row!);
          const changes = diffObjects(before, after);
          if (Object.keys(changes).length > 0) {
            await writeAudit(tx, {
              user,
              entity: def.path,
              entityId: id,
              action: 'update',
              summary: def.label(after),
              diff: changes,
              ip: clientIp(c),
            });
          }
          return after;
        });
        return c.json(updated, 200);
      } catch (err) {
        throw mapDbError(err) ?? err;
      }
    },
  );

  app.openapi(
    createRoute({
      method: 'delete',
      path: `/api/v1/${def.path}/{id}`,
      tags: tag,
      request: { params: IdParam },
      responses: { 204: { description: 'Deleted' }, ...errors },
    }),
    async (c) => {
      const { db } = c.var.deps;
      const user = c.var.user!;
      const { id } = c.req.valid('param');
      if (!can(user.roles, def.resource, 'read')) throw new ApiError('forbidden');
      try {
        await db.transaction(async (tx) => {
          const before = await findOne(tx, user, id);
          // Entities with per-row rules decide delete themselves (they include the role check).
          const allowed = def.canModify
            ? def.canModify(user, before, 'delete')
            : can(user.roles, def.resource, 'delete');
          if (!allowed) throw new ApiError('forbidden');
          await tx.delete(t).where(eq(t.id, id));
          await writeAudit(tx, {
            user,
            entity: def.path,
            entityId: id,
            action: 'delete',
            summary: def.label(before),
            diff: before,
            ip: clientIp(c),
          });
        });
      } catch (err) {
        throw mapDbError(err) ?? err;
      }
      return c.body(null, 204);
    },
  );
}
