# Architecture

## Overview

```
apps/manager (Flutter)  ─┐                       ┌─ PostgreSQL 16
                         ├─ HTTPS ─ services/api ┤
apps/web (Phase 3)  ─────┘   (Hono on Node 22)   └─ files on disk (FILES_DIR)
                                   │
                         packages/shared (zod schemas, roles, money)
                                   │  pnpm gen:dart
                         apps/manager/lib/api/models.g.dart
```

- **One image, one origin.** The Docker image contains the API and the Flutter web build; the API serves the app
  at `/` and the API under `/api`. Same origin means first-party `httpOnly` session cookies and no CORS in production.
- **Self-hostable.** Everything runs in `docker compose` (app, Postgres, backups, optional `cloudflared`). No managed
  services are required.

## Shared contract

`packages/shared/src/schemas.ts` defines every entity with zod. The API uses them to validate input, strip unknown
fields and build the OpenAPI document (`/api/openapi.json`). `services/api/src/tools/gen-dart.ts` turns the same
schemas into the Dart classes the app uses (`LiveItem`, `ProductItem`, …), so a field renamed on one side breaks the
build on the other instead of silently losing data. `contract/app-payloads.json` (written by a Flutter test) is posted
to the API by an integration test to prove the app's JSON is accepted.

## API (`services/api`)

| File | Responsibility |
|---|---|
| `src/app.ts` | Composition: security headers, CORS (dev only), auth handler, middleware order, static app |
| `src/auth.ts` | Better Auth: email/password, sign-up disabled, invitations via the reset-password flow, TOTP 2FA, rate limits, deactivated users cannot create sessions |
| `src/middleware.ts` | Session loading, `requireUser` (incl. 2FA enforcement by role), `requirePermission`, Origin check |
| `src/routes/crud.ts` | Generic list/get/create/update/delete for the Phase 1 entities, with per-entity read scopes and row rules |
| `src/routes/entities.ts` | Entity definitions (table, permission resource, labels, special rules e.g. private calendar events) |
| `src/routes/users.ts` | Admin user management: invite, roles, deactivate, resend invite, revoke sessions |
| `src/routes/member-sensitive.ts` | Encrypted member fields (AES-256-GCM, row-bound AAD), admin-only, every read audited |
| `src/routes/calendar-feed.ts` + `src/ical.ts` | Per-user secret iCal subscription URL (only the token's SHA-256 is stored) |
| `src/routes/files.ts` | Product image upload (content-sniffed, 5 MB), permission-checked download |
| `src/routes/me.ts` | `/me`, `/bootstrap` (everything the user may read in one call), settings |
| `src/db/schema.ts`, `drizzle/` | Tables and SQL migrations (applied on start) |

### Authorization

Roles and their permissions live in `packages/shared/src/roles.ts` (`resource → read/write/delete`). Users can have
several roles; permissions are the union. The API checks them on every route; the app receives the computed
permissions from `/me` only to hide buttons. Some rules are per row (private calendar events are visible only to their
owner; owners may delete their own events).

Roles: `admin`, `manager`, `member`, `accountant` (read-only), `merchManager`, `merchStaff` (POS only, later),
`socialManager`. 2FA is required for `admin`, `manager`, `accountant`, `socialManager`: until enabled, only `/me` and
the auth endpoints work.

### Audit log

Every create/update/delete writes `audit_log` in the same transaction: user, entity, id, summary and a field-level diff
(sensitive member fields are never included). A database trigger rejects UPDATE/DELETE/TRUNCATE on `audit_log`.

### Security measures

- Invite-only accounts; passwords ≥ 12 characters, scrypt hashed; reset/invite tokens single-use, 48 h.
- Rate limits on sign-in, 2FA verification and password reset (by client IP, Cloudflare header aware).
- Cookies `httpOnly`, `Secure` on HTTPS, `SameSite=Lax`; state-changing requests with a foreign `Origin` are rejected.
- Strict security headers; CSP on the app and on the password page; `no-store` on API responses.
- Field-level encryption for ΑΦΜ/ΑΜΚΑ/IBAN/passport etc.; nothing sensitive cached in the browser.
- Deactivating a user or changing roles ends all their sessions immediately.

## App (`apps/manager`)

- `lib/api/` — `ApiClient` (cookies via the browser on web, Keychain-stored cookie jar on iOS), generated models.
- `lib/data/app_store.dart` — in-memory cache filled from `/bootstrap`; `create/update/remove` call the API, then
  replace the cached item with the server's version (or roll back and show the error). Screens are unchanged in
  structure; they now call these methods instead of writing to local storage.
- `lib/core/money.dart`, `rent.dart`, `finance.dart` — pure, unit-tested business logic in cents.
- `lib/l10n/` — ARB files (el, en) and generated `AppLocalizations`. Phase 1 translated the shell, sign-in, 2FA,
  settings and user management; module screens are translated as each module is reworked.

## Decisions

| Decision | Why |
|---|---|
| Keep Flutter for the internal app | ~10k lines of working UI; iOS app; approved by the owner |
| PostgreSQL, not SQLite/D1 | transactions and row locks for stock reservations, constraints, reporting |
| Better Auth inside the API | self-hostable, no external identity provider, 2FA built in |
| Hono + zod-openapi | small, typed, runs on Node (and Workers if ever needed) |
| Integer cents | no rounding errors; myDATA-friendly |
| Generated Dart models instead of OpenAPI generator | no Java toolchain; output matches the app's existing class names |
| Text columns + zod enums instead of Postgres enums | statuses will change in later phases (bookings, orders) without enum migrations |
