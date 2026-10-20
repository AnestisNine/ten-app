/**
 * API contract for the entities that exist in the app today (Phase 1 lift-and-shift).
 * These zod schemas are used for server validation and OpenAPI, and the Dart models
 * in apps/manager are generated from them (`pnpm gen:dart`).
 *
 * Conventions: ids are UUIDs, money is integer cents (`...Cents`), calendar dates are
 * `YYYY-MM-DD`, instants are ISO-8601 strings with offset.
 */
import { z } from 'zod';

export const id = z.uuid();
export const isoDate = z.iso.date();
export const isoDateTime = z.iso.datetime({ offset: true });
export const cents = z.number().int().min(-1_000_000_000).max(1_000_000_000);
export const nonNegCents = cents.min(0);
const text = (max = 200) => z.string().trim().max(max);
const longText = z.string().max(10_000);

// ---------- enums (values must stay in sync with the Dart enum names) ----------

export const LiveStatus = z.enum(['proposal', 'negotiation', 'confirmed', 'completed', 'cancelled']);
export const OrderStatus = z.enum(['waitingContact', 'waitingRestock', 'sent', 'completed', 'cancelled']);
export const ShippingMethod = z.enum(['boxNow', 'elta', 'acs', 'geniki']);
export const OrderSource = z.enum(['organic', 'bandcamp']);
export const OrderContext = z.enum(['afterLive', 'outsideLive']);
export const RentPaymentMethod = z.enum(['cash', 'bankTransfer', 'iris', 'revolut', 'other']);
export const GeneralExpenseCategory = z.enum(['recordingFee', 'rentFee']);
export const MemberRole = z.enum(['musician', 'driver', 'soundEngineer', 'technician']);
export const CalendarVisibility = z.enum(['team', 'private']);
export const AuditAction = z.enum(['create', 'update', 'delete', 'read', 'login', 'export']);

// ---------- entities ----------

export const Tour = z.object({
  id,
  name: text().min(1),
  startDate: isoDate,
  endDate: isoDate,
  vanId: text(50).nullable(),
  /** L/100km, null = default from settings. */
  consumption: z.number().min(0).max(50).nullable(),
});

export const Live = z.object({
  id,
  venue: text().min(1),
  city: text(),
  country: text(),
  countryCode: z.string().length(2).nullable(),
  lat: z.number().min(-90).max(90).nullable(),
  lon: z.number().min(-180).max(180).nullable(),
  date: isoDate,
  status: LiveStatus,
  tourId: id.nullable(),
  cashIncomeCents: nonNegCents,
  merchIncomeCents: nonNegCents,
  soundExpensesCents: nonNegCents,
  extraExpensesCents: nonNegCents,
  doorDealCents: nonNegCents,
  fixCents: nonNegCents,
  soundEngineerFeeCents: nonNegCents,
  technicianFeeCents: nonNegCents,
  supportBandFeeCents: nonNegCents,
  mainAct: text(),
  support: text(),
  contactPerson: text(),
  soundEngineer: text(),
  ticketsPresale: z.number().int().min(0),
  ticketsDoor: z.number().int().min(0),
  generalInfo: longText,
  /** Public ticket link shown on the website for confirmed shows. */
  ticketUrl: z.union([z.url({ protocol: /^https?$/ }).max(500), z.literal('')]).nullable(),
});

export const Product = z.object({
  id,
  name: text().min(1),
  stock: z.number().int().min(0),
  unitCostCents: nonNegCents,
  salePriceCents: nonNegCents,
  /** Server path of the uploaded image, e.g. /api/v1/files/<id>; null when none. */
  imageUrl: z.string().max(500).nullable(),
});

export const Customer = z.object({
  id,
  firstName: text(100),
  lastName: text(100),
  email: z.union([z.email().max(200), z.literal('')]),
  phone: text(50),
  address: text(),
  city: text(100),
  postalCode: text(20),
  country: text(100),
});

export const Order = z.object({
  id,
  /** Human readable, sequential, assigned by the server (shown as "#1001"). */
  number: z.number().int(),
  customerId: id,
  productId: id,
  quantity: z.number().int().min(1),
  shippingCostCents: nonNegCents,
  shippingMethod: ShippingMethod,
  status: OrderStatus,
  source: OrderSource,
  context: OrderContext,
  trackingNumber: text(100),
  notes: longText,
  createdAt: isoDateTime,
});

export const CalendarEvent = z.object({
  id,
  startsAt: isoDateTime,
  title: text().min(1),
  type: text(50),
  location: text(),
  notes: longText,
  visibility: CalendarVisibility,
  /** User who created the event. Private events are only visible to their owner. */
  ownerId: z.string().nullable(),
});

export const Member = z.object({
  id,
  role: MemberRole,
  name: text(100),
  surname: text(100),
  mobile: text(50),
  email: z.union([z.email().max(200), z.literal('')]),
  /** Linked login account, if this member uses the app. */
  userId: z.string().nullable(),
});

/** Sensitive personal data. Encrypted at rest, admin-only, every read is audited. */
export const MemberSensitive = z.object({
  fatherSurname: text(100),
  fatherName: text(100),
  motherName: text(100),
  birthDate: text(20),
  birthPlace: text(100),
  nationality: text(100),
  address: text(),
  maritalStatus: text(50),
  children: text(50),
  idNumber: text(50),
  passport: text(50),
  issueDateAndAuthority: text(),
  ama: text(50),
  afm: text(20),
  doy: text(100),
  amka: text(20),
  contactPhone: text(50),
  iban: text(40),
  bank: text(100),
});

export const StreamingIncome = z.object({
  id,
  platform: text(100).min(1),
  amountCents: cents,
  date: isoDate,
  notes: longText,
});

export const GeneralExpense = z.object({
  id,
  category: GeneralExpenseCategory,
  amountCents: nonNegCents,
  date: isoDate,
  notes: longText,
});

export const RentPerson = z.object({
  id,
  name: text(100).min(1),
});

export const RentPayment = z.object({
  id,
  personId: id,
  amountCents: nonNegCents,
  paymentDate: isoDate,
  method: RentPaymentMethod,
  /** First day of the month the payment is for. */
  month: isoDate,
});

export const Settings = z.object({
  monthlyRentCents: nonNegCents,
  cashboxBalanceCents: cents,
  dieselPriceCents: nonNegCents,
  fuelConsumption: z.number().min(0).max(50),
  vanId: text(50),
  lowStockThreshold: z.number().int().min(0),
});

export const AuditEntry = z.object({
  id,
  at: isoDateTime,
  userId: z.string().nullable(),
  userName: z.string().nullable(),
  entity: z.string(),
  entityId: z.string().nullable(),
  action: AuditAction,
  summary: z.string(),
});

export const Notification = z.object({
  id,
  title: z.string(),
  body: z.string(),
  at: isoDateTime,
  read: z.boolean(),
});

// ---------- public website ----------

export const PublicShow = z.object({
  id,
  date: isoDate,
  venue: z.string(),
  city: z.string(),
  country: z.string(),
  countryCode: z.string().nullable(),
  support: z.string(),
  ticketUrl: z.string().nullable(),
});

export const PublicProduct = z.object({
  id,
  name: z.string(),
  priceCents: cents,
  inStock: z.boolean(),
  imageUrl: z.string().nullable(),
});

export const InquiryType = z.enum(['booking', 'press', 'general']);

export const ContactRequest = z.object({
  type: InquiryType,
  name: z.string().trim().min(1).max(100),
  email: z.email().max(200),
  phone: z.string().trim().max(50).default(''),
  subject: z.string().trim().max(200).default(''),
  message: z.string().trim().min(1).max(5000),
  locale: z.enum(['el', 'en']).default('el'),
  /** Honeypot: real people leave it empty. */
  website: z.string().max(0).default(''),
});

export const NewsletterRequest = z.object({
  email: z.email().max(200),
  locale: z.enum(['el', 'en']).default('el'),
  /** Explicit opt-in (GDPR): the checkbox must be ticked. */
  consent: z.literal(true),
  website: z.string().max(0).default(''),
});

export type PublicShow = z.infer<typeof PublicShow>;
export type PublicProduct = z.infer<typeof PublicProduct>;

/** Create payloads: everything except server-assigned fields; `id` is optional so offline clients can pick one. */
const createOf = <T extends z.ZodRawShape>(s: z.ZodObject<T>, omit: string[] = []) =>
  s.omit(Object.fromEntries([...omit].map((k) => [k, true])) as never).extend({ id: id.optional() });

export const entities = {
  tours: { schema: Tour, create: createOf(Tour) },
  lives: { schema: Live, create: createOf(Live) },
  products: { schema: Product, create: createOf(Product, ['imageUrl']) },
  customers: { schema: Customer, create: createOf(Customer) },
  orders: { schema: Order, create: createOf(Order, ['number', 'createdAt']) },
  calendarEvents: { schema: CalendarEvent, create: createOf(CalendarEvent, ['ownerId']) },
  members: { schema: Member, create: createOf(Member) },
  streamingIncomes: { schema: StreamingIncome, create: createOf(StreamingIncome) },
  generalExpenses: { schema: GeneralExpense, create: createOf(GeneralExpense) },
  rentPeople: { schema: RentPerson, create: createOf(RentPerson) },
  rentPayments: { schema: RentPayment, create: createOf(RentPayment) },
} as const;
export type EntityName = keyof typeof entities;

export type Tour = z.infer<typeof Tour>;
export type Live = z.infer<typeof Live>;
export type Product = z.infer<typeof Product>;
export type Customer = z.infer<typeof Customer>;
export type Order = z.infer<typeof Order>;
export type CalendarEvent = z.infer<typeof CalendarEvent>;
export type Member = z.infer<typeof Member>;
export type MemberSensitive = z.infer<typeof MemberSensitive>;
export type StreamingIncome = z.infer<typeof StreamingIncome>;
export type GeneralExpense = z.infer<typeof GeneralExpense>;
export type RentPerson = z.infer<typeof RentPerson>;
export type RentPayment = z.infer<typeof RentPayment>;
export type Settings = z.infer<typeof Settings>;
export type AuditEntry = z.infer<typeof AuditEntry>;
export type Notification = z.infer<typeof Notification>;
