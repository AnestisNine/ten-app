import { OpenAPIHono } from '@hono/zod-openapi';
import { serveStatic } from '@hono/node-server/serve-static';
import { cors } from 'hono/cors';
import { HTTPException } from 'hono/http-exception';
import { secureHeaders } from 'hono/secure-headers';
import { splitList } from './config.js';
import type { AppEnv, Deps } from './context.js';
import { ApiError } from './errors.js';
import { checkOrigin, loadSession, requireUser } from './middleware.js';
import { authCss, setPasswordHtml, setPasswordJs } from './pages/set-password.js';
import { registerCalendarFeedRoutes, registerIcalFeed } from './routes/calendar-feed.js';
import { registerEntityRoutes } from './routes/entities.js';
import { registerFileRoutes } from './routes/files.js';
import { registerMeRoutes } from './routes/me.js';
import { registerMemberSensitiveRoutes } from './routes/member-sensitive.js';
import { registerPublicRoutes } from './routes/public.js';
import { registerSystemRoutes } from './routes/system.js';
import { registerUserRoutes } from './routes/users.js';

/** Paths under /api/v1 reachable by signed-in users who still have to enable 2FA. */
const PRE_2FA_PATHS = new Set(['/api/v1/me']);

export function createApp(deps: Deps) {
  const app = new OpenAPIHono<AppEnv>({
    defaultHook: (result) => {
      if (!result.success) {
        throw new ApiError('validation_failed', 'Invalid input', result.error.issues);
      }
    },
  });

  app.use('*', async (c, next) => {
    c.set('deps', deps);
    await next();
  });

  app.use(
    '*',
    secureHeaders({
      strictTransportSecurity: 'max-age=63072000; includeSubDomains',
      referrerPolicy: 'no-referrer',
      xFrameOptions: 'DENY',
      permissionsPolicy: { camera: [], microphone: [], geolocation: [] },
    }),
  );

  const trusted = splitList(deps.config.TRUSTED_ORIGINS);
  if (trusted.length > 0) {
    // Only needed when the app is served from a different origin (e.g. Flutter dev server).
    app.use('/api/v1/*', cors({ origin: trusted, credentials: true, allowMethods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE'] }));
    app.use('/api/auth/*', cors({ origin: trusted, credentials: true, allowMethods: ['GET', 'POST'] }));
  }

  app.onError((err, c) => {
    if (err instanceof ApiError) {
      return c.json({ error: err.code, message: err.message, details: err.details }, err.status);
    }
    if (err instanceof HTTPException) return err.getResponse();
    console.error(err);
    return c.json({ error: 'internal', message: 'Internal error' }, 500);
  });

  app.get('/healthz', (c) => c.json({ ok: true }));

  // Better Auth: sign-in, sign-out, session, 2FA, password reset.
  app.on(['GET', 'POST'], '/api/auth/*', (c) => deps.auth.handler(c.req.raw));

  registerPublicRoutes(app);

  app.use('/api/v1/*', checkOrigin, loadSession);
  app.use('/api/v1/*', async (c, next) => {
    if (PRE_2FA_PATHS.has(c.req.path)) return next();
    return requireUser()(c, next);
  });
  app.use('/api/v1/*', async (c, next) => {
    await next();
    c.header('Cache-Control', 'no-store');
  });

  registerMeRoutes(app);
  registerUserRoutes(app);
  registerEntityRoutes(app);
  registerMemberSensitiveRoutes(app);
  registerFileRoutes(app);
  registerSystemRoutes(app);
  registerCalendarFeedRoutes(app);
  registerIcalFeed(app);

  app.doc31('/api/openapi.json', {
    openapi: '3.1.0',
    info: { title: 'TBN Manager API', version: '1.0.0' },
  });

  const pageCsp = "default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'";
  app.get('/auth/set-password', (c) => {
    c.header('Content-Security-Policy', pageCsp);
    return c.html(setPasswordHtml);
  });
  app.get('/auth/set-password.js', (c) => {
    c.header('Content-Type', 'text/javascript; charset=utf-8');
    return c.body(setPasswordJs);
  });
  app.get('/auth/auth.css', (c) => {
    c.header('Content-Type', 'text/css; charset=utf-8');
    return c.body(authCss);
  });

  if (deps.config.WEB_APP_DIR) {
    // The Flutter web build, served from the same origin as the API so auth cookies stay first-party.
    app.use('/*', async (c, next) => {
      await next();
      c.header(
        'Content-Security-Policy',
        [
          "default-src 'self'",
          "script-src 'self' 'wasm-unsafe-eval' 'unsafe-inline'",
          "style-src 'self' 'unsafe-inline'",
          "img-src 'self' data: blob:",
          "font-src 'self' data:",
          "connect-src 'self' https://router.project-osrm.org https://routing.openstreetmap.de https://geocoding-api.open-meteo.com",
          "worker-src 'self' blob:",
          "frame-ancestors 'none'",
          "base-uri 'self'",
        ].join('; '),
      );
    });
    app.use('/*', serveStatic({ root: deps.config.WEB_APP_DIR }));
    app.get('*', serveStatic({ root: deps.config.WEB_APP_DIR, path: 'index.html' }));
  }

  return app;
}
