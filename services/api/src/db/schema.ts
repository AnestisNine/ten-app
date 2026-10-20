/**
 * Database schema (PostgreSQL). Money columns are integer cents.
 * Auth tables follow the field names Better Auth expects (see src/auth.ts).
 */
import { sql } from 'drizzle-orm';
import {
  boolean,
  date,
  doublePrecision,
  index,
  integer,
  jsonb,
  pgTable,
  serial,
  text,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core';

const timestamps = {
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date()),
};

// ---------------------------------------------------------------- auth

export const user = pgTable('user', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  emailVerified: boolean('email_verified').notNull().default(false),
  image: text('image'),
  twoFactorEnabled: boolean('two_factor_enabled').default(false),
  /** Comma separated app roles, see @tbn/shared roles.ts. */
  roles: text('roles').notNull().default(''),
  /** Deactivated users cannot sign in and their sessions are revoked. */
  active: boolean('active').notNull().default(true),
  locale: text('locale').notNull().default('el'),
  ...timestamps,
});

export const session = pgTable(
  'session',
  {
    id: text('id').primaryKey(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    token: text('token').notNull().unique(),
    ipAddress: text('ip_address'),
    userAgent: text('user_agent'),
    userId: text('user_id')
      .notNull()
      .references(() => user.id, { onDelete: 'cascade' }),
    ...timestamps,
  },
  (t) => [index('session_user_idx').on(t.userId)],
);

export const account = pgTable('account', {
  id: text('id').primaryKey(),
  accountId: text('account_id').notNull(),
  providerId: text('provider_id').notNull(),
  userId: text('user_id')
    .notNull()
    .references(() => user.id, { onDelete: 'cascade' }),
  accessToken: text('access_token'),
  refreshToken: text('refresh_token'),
  idToken: text('id_token'),
  accessTokenExpiresAt: timestamp('access_token_expires_at', { withTimezone: true }),
  refreshTokenExpiresAt: timestamp('refresh_token_expires_at', { withTimezone: true }),
  scope: text('scope'),
  password: text('password'),
  ...timestamps,
});

export const verification = pgTable('verification', {
  id: text('id').primaryKey(),
  identifier: text('identifier').notNull(),
  value: text('value').notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  ...timestamps,
});

export const twoFactor = pgTable('two_factor', {
  id: text('id').primaryKey(),
  secret: text('secret').notNull(),
  backupCodes: text('backup_codes').notNull(),
  userId: text('user_id')
    .notNull()
    .references(() => user.id, { onDelete: 'cascade' }),
  verified: boolean('verified').default(true),
  failedVerificationCount: integer('failed_verification_count').default(0),
  lockedUntil: timestamp('locked_until', { withTimezone: true }),
});

// ---------------------------------------------------------------- bookings

export const tours = pgTable('tours', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull(),
  startDate: date('start_date').notNull(),
  endDate: date('end_date').notNull(),
  vanId: text('van_id'),
  consumption: doublePrecision('consumption'),
  ...timestamps,
});

export const lives = pgTable(
  'lives',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    venue: text('venue').notNull(),
    city: text('city').notNull().default(''),
    country: text('country').notNull().default(''),
    countryCode: text('country_code'),
    lat: doublePrecision('lat'),
    lon: doublePrecision('lon'),
    date: date('date').notNull(),
    status: text('status').notNull(),
    tourId: uuid('tour_id').references(() => tours.id, { onDelete: 'set null' }),
    cashIncomeCents: integer('cash_income_cents').notNull().default(0),
    merchIncomeCents: integer('merch_income_cents').notNull().default(0),
    soundExpensesCents: integer('sound_expenses_cents').notNull().default(0),
    extraExpensesCents: integer('extra_expenses_cents').notNull().default(0),
    doorDealCents: integer('door_deal_cents').notNull().default(0),
    fixCents: integer('fix_cents').notNull().default(0),
    soundEngineerFeeCents: integer('sound_engineer_fee_cents').notNull().default(0),
    technicianFeeCents: integer('technician_fee_cents').notNull().default(0),
    supportBandFeeCents: integer('support_band_fee_cents').notNull().default(0),
    mainAct: text('main_act').notNull().default(''),
    support: text('support').notNull().default(''),
    contactPerson: text('contact_person').notNull().default(''),
    soundEngineer: text('sound_engineer').notNull().default(''),
    ticketsPresale: integer('tickets_presale').notNull().default(0),
    ticketsDoor: integer('tickets_door').notNull().default(0),
    generalInfo: text('general_info').notNull().default(''),
    ticketUrl: text('ticket_url'),
    /** Poster / artwork shown on the website. */
    posterFileId: uuid('poster_file_id').references(() => files.id, { onDelete: 'set null' }),
    ...timestamps,
  },
  (t) => [index('lives_date_idx').on(t.date)],
);

export const calendarEvents = pgTable('calendar_events', {
  id: uuid('id').primaryKey().defaultRandom(),
  startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
  title: text('title').notNull(),
  type: text('type').notNull().default(''),
  location: text('location').notNull().default(''),
  notes: text('notes').notNull().default(''),
  visibility: text('visibility').notNull().default('team'),
  ownerId: text('owner_id').references(() => user.id, { onDelete: 'set null' }),
  ...timestamps,
});

/** Secret per-user iCalendar subscription URL. Only a hash of the token is stored. */
export const calendarFeeds = pgTable('calendar_feeds', {
  userId: text('user_id')
    .primaryKey()
    .references(() => user.id, { onDelete: 'cascade' }),
  tokenHash: text('token_hash').notNull().unique(),
  ...timestamps,
});

// ---------------------------------------------------------------- merch

export const products = pgTable('products', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull(),
  stock: integer('stock').notNull().default(0),
  unitCostCents: integer('unit_cost_cents').notNull().default(0),
  salePriceCents: integer('sale_price_cents').notNull().default(0),
  imageFileId: uuid('image_file_id').references(() => files.id, { onDelete: 'set null' }),
  ...timestamps,
});

export const customers = pgTable('customers', {
  id: uuid('id').primaryKey().defaultRandom(),
  firstName: text('first_name').notNull().default(''),
  lastName: text('last_name').notNull().default(''),
  email: text('email').notNull().default(''),
  phone: text('phone').notNull().default(''),
  address: text('address').notNull().default(''),
  city: text('city').notNull().default(''),
  postalCode: text('postal_code').notNull().default(''),
  country: text('country').notNull().default(''),
  ...timestamps,
});

export const orders = pgTable('orders', {
  id: uuid('id').primaryKey().defaultRandom(),
  number: serial('number').notNull().unique(),
  customerId: uuid('customer_id')
    .notNull()
    .references(() => customers.id, { onDelete: 'restrict' }),
  productId: uuid('product_id')
    .notNull()
    .references(() => products.id, { onDelete: 'restrict' }),
  quantity: integer('quantity').notNull(),
  shippingCostCents: integer('shipping_cost_cents').notNull().default(0),
  shippingMethod: text('shipping_method').notNull(),
  status: text('status').notNull(),
  source: text('source').notNull(),
  context: text('context').notNull(),
  trackingNumber: text('tracking_number').notNull().default(''),
  notes: text('notes').notNull().default(''),
  ...timestamps,
});

// ---------------------------------------------------------------- people

export const members = pgTable('members', {
  id: uuid('id').primaryKey().defaultRandom(),
  role: text('role').notNull(),
  name: text('name').notNull().default(''),
  surname: text('surname').notNull().default(''),
  mobile: text('mobile').notNull().default(''),
  email: text('email').notNull().default(''),
  userId: text('user_id').references(() => user.id, { onDelete: 'set null' }),
  ...timestamps,
});

/** Encrypted (AES-256-GCM) JSON of MemberSensitive. Never selected outside src/routes/members.ts. */
export const memberSensitive = pgTable('member_sensitive', {
  memberId: uuid('member_id')
    .primaryKey()
    .references(() => members.id, { onDelete: 'cascade' }),
  ciphertext: text('ciphertext').notNull(),
  keyVersion: integer('key_version').notNull().default(1),
  ...timestamps,
});

// ---------------------------------------------------------------- finance

export const streamingIncomes = pgTable('streaming_incomes', {
  id: uuid('id').primaryKey().defaultRandom(),
  platform: text('platform').notNull(),
  amountCents: integer('amount_cents').notNull(),
  date: date('date').notNull(),
  notes: text('notes').notNull().default(''),
  ...timestamps,
});

export const generalExpenses = pgTable('general_expenses', {
  id: uuid('id').primaryKey().defaultRandom(),
  category: text('category').notNull(),
  amountCents: integer('amount_cents').notNull(),
  date: date('date').notNull(),
  notes: text('notes').notNull().default(''),
  ...timestamps,
});

export const rentPeople = pgTable('rent_people', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull(),
  ...timestamps,
});

export const rentPayments = pgTable('rent_payments', {
  id: uuid('id').primaryKey().defaultRandom(),
  personId: uuid('person_id')
    .notNull()
    .references(() => rentPeople.id, { onDelete: 'cascade' }),
  amountCents: integer('amount_cents').notNull(),
  paymentDate: date('payment_date').notNull(),
  method: text('method').notNull(),
  month: date('month').notNull(),
  ...timestamps,
});

// ---------------------------------------------------------------- system

/** Single-row table (id = 1). */
export const settings = pgTable('settings', {
  id: integer('id').primaryKey().default(1),
  monthlyRentCents: integer('monthly_rent_cents').notNull().default(35000),
  cashboxBalanceCents: integer('cashbox_balance_cents').notNull().default(0),
  dieselPriceCents: integer('diesel_price_cents').notNull().default(175),
  fuelConsumption: doublePrecision('fuel_consumption').notNull().default(9.1),
  vanId: text('van_id').notNull().default('vw_t61'),
  lowStockThreshold: integer('low_stock_threshold').notNull().default(3),
  ...timestamps,
});

export const files = pgTable('files', {
  id: uuid('id').primaryKey().defaultRandom(),
  ownerId: text('owner_id').references(() => user.id, { onDelete: 'set null' }),
  /** Permission resource that guards reading this file (e.g. 'merch' for product images). */
  resource: text('resource').notNull(),
  mimeType: text('mime_type').notNull(),
  sizeBytes: integer('size_bytes').notNull(),
  /** Path relative to FILES_DIR. */
  storageKey: text('storage_key').notNull(),
  originalName: text('original_name').notNull().default(''),
  ...timestamps,
});

/** Append-only. The app role has no UPDATE/DELETE on this table in production (see migrations). */
export const auditLog = pgTable(
  'audit_log',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    at: timestamp('at', { withTimezone: true }).notNull().defaultNow(),
    userId: text('user_id'),
    userName: text('user_name'),
    entity: text('entity').notNull(),
    entityId: text('entity_id'),
    action: text('action').notNull(),
    summary: text('summary').notNull().default(''),
    /** Before/after values for updates; never contains sensitive member fields. */
    diff: jsonb('diff'),
    ip: text('ip'),
  },
  (t) => [index('audit_at_idx').on(t.at), index('audit_entity_idx').on(t.entity, t.entityId)],
);

export const notifications = pgTable(
  'notifications',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: text('user_id')
      .notNull()
      .references(() => user.id, { onDelete: 'cascade' }),
    title: text('title').notNull(),
    body: text('body').notNull().default(''),
    read: boolean('read').notNull().default(false),
    at: timestamp('at', { withTimezone: true }).notNull().default(sql`now()`),
  },
  (t) => [index('notifications_user_idx').on(t.userId, t.read)],
);

// ---------------------------------------------------------------- public website

/** Messages from the website's contact / booking form. Becomes part of the CRM later. */
export const inquiries = pgTable('inquiries', {
  id: uuid('id').primaryKey().defaultRandom(),
  type: text('type').notNull(),
  name: text('name').notNull(),
  email: text('email').notNull(),
  phone: text('phone').notNull().default(''),
  subject: text('subject').notNull().default(''),
  message: text('message').notNull(),
  locale: text('locale').notNull().default('el'),
  status: text('status').notNull().default('new'),
  ...timestamps,
});

/** Newsletter sign-ups with the consent that was given (GDPR). */
export const newsletterSubscribers = pgTable('newsletter_subscribers', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  locale: text('locale').notNull().default('el'),
  consentAt: timestamp('consent_at', { withTimezone: true }).notNull(),
  consentText: text('consent_text').notNull(),
  /** Set after double opt-in, once outgoing email is configured. */
  confirmedAt: timestamp('confirmed_at', { withTimezone: true }),
  unsubscribedAt: timestamp('unsubscribed_at', { withTimezone: true }),
  ...timestamps,
});
