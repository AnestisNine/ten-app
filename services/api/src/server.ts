import { serve } from '@hono/node-server';
import { createApp } from './app.js';
import { createAuth } from './auth.js';
import { loadConfig } from './config.js';
import { createDb } from './db/client.js';
import { runMigrations } from './db/migrate.js';
import { createMailer } from './mailer.js';

const config = loadConfig();
if (config.NODE_ENV === 'production' && !config.REQUIRE_TWO_FACTOR && process.env.ALLOW_DEMO_SEED !== '1') {
  throw new Error('REQUIRE_TWO_FACTOR=false is only allowed for the demo preview (ALLOW_DEMO_SEED=1)');
}
await runMigrations(config.DATABASE_URL);
const { db, sql } = createDb(config.DATABASE_URL);
const mailer = createMailer(config);
const auth = createAuth(config, db, mailer);
const app = createApp({ config, db, auth, mailer });

if (config.NODE_ENV === 'production' && !config.SMTP_URL) {
  console.warn('SMTP_URL is not set: invitation and reset emails will only be printed to the log.');
}

const server = serve({ fetch: app.fetch, port: config.PORT }, (info) => {
  console.log(`TBN API listening on :${info.port}`);
});

const shutdown = () => {
  server.close();
  void sql.end({ timeout: 5 }).then(() => process.exit(0));
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
