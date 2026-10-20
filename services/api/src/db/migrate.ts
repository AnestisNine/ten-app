import { fileURLToPath } from 'node:url';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import { createDb } from './client.js';

export const MIGRATIONS_DIR = fileURLToPath(new URL('../../drizzle', import.meta.url));

export async function runMigrations(url: string) {
  const { db, sql } = createDb(url);
  try {
    await migrate(db, { migrationsFolder: MIGRATIONS_DIR });
  } finally {
    await sql.end();
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error('DATABASE_URL is not set');
  await runMigrations(url);
  console.log('Migrations applied.');
}
