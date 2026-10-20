import type { Db, Tx } from './db/client.js';
import { auditLog } from './db/schema.js';
import type { CurrentUser } from './context.js';

export type AuditAction = 'create' | 'update' | 'delete' | 'read' | 'login' | 'export';

export interface AuditInput {
  user: CurrentUser | null;
  entity: string;
  entityId?: string | null;
  action: AuditAction;
  summary?: string;
  diff?: unknown;
  ip?: string | null;
}

export async function writeAudit(db: Db | Tx, input: AuditInput) {
  await db.insert(auditLog).values({
    userId: input.user?.id ?? null,
    userName: input.user?.name ?? null,
    entity: input.entity,
    entityId: input.entityId ?? null,
    action: input.action,
    summary: input.summary ?? '',
    diff: input.diff ?? null,
    ip: input.ip ?? null,
  });
}

/** Field-level changes between two API objects: { field: [before, after] }. */
export function diffObjects(before: Record<string, unknown>, after: Record<string, unknown>) {
  const changes: Record<string, [unknown, unknown]> = {};
  for (const key of new Set([...Object.keys(before), ...Object.keys(after)])) {
    if (JSON.stringify(before[key]) !== JSON.stringify(after[key])) changes[key] = [before[key], after[key]];
  }
  return changes;
}
