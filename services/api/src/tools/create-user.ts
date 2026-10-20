/**
 * Creates the first admin on a fresh installation and emails them an invitation link
 * (printed to the log when SMTP is not configured).
 *   pnpm user:create --email you@example.com --name "Your Name" [--roles admin]
 */
import { ROLES, isRole } from '@tbn/shared';
import { eq } from 'drizzle-orm';
import { randomUUID } from 'node:crypto';
import { parseArgs } from 'node:util';
import { createAuth } from '../auth.js';
import { loadConfig } from '../config.js';
import { createDb } from '../db/client.js';
import { runMigrations } from '../db/migrate.js';
import { user } from '../db/schema.js';
import { createMailer } from '../mailer.js';

const { values } = parseArgs({
  options: { email: { type: 'string' }, name: { type: 'string' }, roles: { type: 'string', default: 'admin' } },
});
if (!values.email || !values.name) {
  console.error('Usage: pnpm user:create --email you@example.com --name "Your Name" [--roles admin,member]');
  process.exit(1);
}
const roles = values.roles!.split(',').map((r) => r.trim());
const bad = roles.filter((r) => !isRole(r));
if (bad.length) {
  console.error(`Unknown role(s): ${bad.join(', ')}. Valid: ${ROLES.join(', ')}`);
  process.exit(1);
}

const config = loadConfig();
await runMigrations(config.DATABASE_URL);
const { db, sql } = createDb(config.DATABASE_URL);
const email = values.email.toLowerCase();
const existing = await db.query.user.findFirst({ where: eq(user.email, email) });
if (!existing) {
  await db.insert(user).values({ id: randomUUID(), name: values.name, email, roles: roles.join(','), emailVerified: false });
}
const auth = createAuth(config, db, createMailer(config));
await auth.api.requestPasswordReset({ body: { email } });
console.log(existing ? `User exists; sent a new password link to ${email}.` : `Created ${email} (${roles.join(', ')}) and sent the invitation.`);
await sql.end();
