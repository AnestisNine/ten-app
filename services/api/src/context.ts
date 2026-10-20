import type { OpenAPIHono } from '@hono/zod-openapi';
import type { Role } from '@tbn/shared';
import type { Auth } from './auth.js';
import type { Config } from './config.js';
import type { Db } from './db/client.js';
import type { Mailer } from './mailer.js';

export interface CurrentUser {
  id: string;
  name: string;
  email: string;
  roles: Role[];
  twoFactorEnabled: boolean;
  locale: string;
}

export interface Deps {
  config: Config;
  db: Db;
  auth: Auth;
  mailer: Mailer;
}

export type AppEnv = {
  Variables: {
    deps: Deps;
    user: CurrentUser | null;
    sessionId: string | null;
  };
};

export type App = OpenAPIHono<AppEnv>;
