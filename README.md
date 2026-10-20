# TBN Platform

Internal management app of **The Bonnie Nettles** (bookings, tours, merch, finance) and, from
Phase 3, the band's public website. One source of truth: a PostgreSQL database behind a TypeScript API.

| Part | Path | Stack |
|---|---|---|
| Internal app (web only) | `apps/manager` | Flutter 3.47 / Dart, built for the web |
| API | `services/api` | Node 22, Hono, Drizzle ORM, Better Auth, zod |
| Shared contract | `packages/shared` | TypeScript: zod schemas, roles/permissions, money helpers |
| Public website | `apps/web` | Phase 3 (Astro) |
| Ops | `Dockerfile`, `docker-compose.yml`, `.github/workflows` | Docker, Cloudflare Tunnel, GitHub Actions → GHCR |

Docs: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · [`docs/OPERATIONS.md`](docs/OPERATIONS.md) (install on the server,
tunnel, backups, security) · [`docs/PHASE0_AUDIT.md`](docs/PHASE0_AUDIT.md) · [`docs/PHASE1_REPORT.md`](docs/PHASE1_REPORT.md)

## Development setup

Requirements: Node 22 + pnpm 10, PostgreSQL 16 (or Docker), Flutter 3.47.

```bash
pnpm install
cp .env.example .env
# fill AUTH_SECRET (openssl rand -base64 48) and DATA_ENCRYPTION_KEY (openssl rand -base64 32)
# point DATABASE_URL at a local database, e.g. postgres://tbn:tbn@localhost:5432/tbn

pnpm --filter @tbn/shared build
pnpm db:migrate
pnpm db:seed          # sample data + one user per role, password "tbn-dev-password"
pnpm dev              # API on http://localhost:8080 (emails are printed to the console)
```

Flutter app against the local API:

```bash
cd apps/manager
flutter pub get
flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:8080
```

(`TRUSTED_ORIGINS=http://localhost:5000` in `.env` allows the dev server's origin.)
Or build it once and let the API serve it from the same origin:
`flutter build web` and set `WEB_APP_DIR=apps/manager/build/web`.

Seeded users: `admin@`, `manager@`, `member@`, `accountant@`, `merch@`, `pos@`, `social@` — all `@tbn.local`.
Admin, manager, accountant and social are asked to set up 2FA on first sign-in.

### Tests

```bash
pnpm -r test                       # shared unit tests + API integration tests (needs Postgres, see TEST_DATABASE_URL)
cd apps/manager && flutter test    # money, rent, finance logic, login screen, payload contract
```

The API tests run against a real database (`postgres://tbn:tbn@localhost:5432/tbn_test` by default) and
drop/recreate its schema.

### Changing the data model

1. Edit the zod schema in `packages/shared/src/schemas.ts` and the table in `services/api/src/db/schema.ts`.
2. `pnpm --filter @tbn/api db:generate` → review the SQL migration in `services/api/drizzle/`.
3. `pnpm gen:dart` → regenerates `apps/manager/lib/api/models.g.dart`.
4. If the app sends the entity: `cd apps/manager && UPDATE_CONTRACT=1 flutter test test/contract_test.dart`.

CI fails when the generated Dart models or the payload contract are out of date.

## Conventions

- **Money is integer cents** everywhere (`...Cents` fields). Parse/format with `parseMoney`/`formatMoney` (TS) or
  `parseCents`/`formatCents` (Dart). Never floats.
- Calendar dates are `YYYY-MM-DD`; instants are ISO-8601 with offset.
- IDs are UUIDs; clients may create them (the app does, so the UI updates before the server answers).
- Every API change is permission-checked on the server and written to the append-only audit log.
- No secrets in the repo: `.env` is ignored, `.env.example` documents every variable.

## Modules (status after Phase 1)

| Module | State |
|---|---|
| Auth & roles | Invite-only accounts, email + password, TOTP 2FA required for admin/manager/accountant/social, 7 roles, admin user management |
| Bookings (lives, tours, calendar) | Existing screens on the shared database; personal iCal subscription feed; private calendar events |
| Merch (products, orders, customers) | Existing screens on the shared database; product images uploaded to the server |
| Finance (rent, streaming, expenses, cashbox) | Existing screens on the shared database; amounts in cents; rent shares add up exactly |
| Members | Basic info for the team; sensitive fields (ΑΦΜ, ΑΜΚΑ, IBAN…) encrypted, admin-only, every read audited |
| CRM, Social, Website, POS, budgets | Later phases — see `docs/PHASE0_AUDIT.md` §7 |
