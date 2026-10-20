/**
 * Access control for the internal app. This is the single source of truth:
 * the API enforces it on every endpoint, and the Flutter app receives a generated
 * copy only to hide controls the user cannot use.
 */
export const ROLES = [
  'admin',
  'manager',
  'member',
  'accountant',
  'merchManager',
  'merchStaff',
  'socialManager',
] as const;
export type Role = (typeof ROLES)[number];

/** Roles whose users must enable two-factor authentication before using the app. */
export const TWO_FACTOR_REQUIRED_ROLES: readonly Role[] = ['admin', 'manager', 'accountant', 'socialManager'];

export const RESOURCES = [
  'bookings', // lives, tours
  'calendar',
  'merch', // products, stock
  'orders',
  'customers',
  'finance', // income, expenses, rent, cashbox
  'members', // basic member info (name, role, phone, email)
  'membersSensitive', // ΑΦΜ, ΑΜΚΑ, IBAN, passport, ...
  'settings',
  'audit',
  'users',
] as const;
export type Resource = (typeof RESOURCES)[number];

export const ACTIONS = ['read', 'write', 'delete'] as const;
export type Action = (typeof ACTIONS)[number];

type Grants = Partial<Record<Resource, readonly Action[]>>;

const R = ['read'] as const;
const RW = ['read', 'write'] as const;
const RWD = ['read', 'write', 'delete'] as const;

export const PERMISSIONS: Record<Role, Grants> = {
  admin: Object.fromEntries(RESOURCES.map((r) => [r, RWD])) as Grants,
  manager: {
    bookings: RW,
    calendar: RW,
    merch: RW,
    orders: RW,
    customers: RW,
    finance: RW,
    members: R,
    settings: RW,
    audit: R,
  },
  member: {
    bookings: R,
    calendar: RW,
    merch: R,
    orders: R,
    finance: R,
    members: R,
  },
  accountant: {
    bookings: R,
    calendar: R,
    merch: R,
    orders: R,
    finance: R,
    members: R,
    audit: R,
  },
  merchManager: {
    bookings: R,
    calendar: R,
    merch: RW,
    orders: RW,
    customers: RW,
  },
  merchStaff: {
    bookings: R,
    merch: R,
  },
  socialManager: {
    bookings: R,
    calendar: R,
    merch: R,
  },
};

export function isRole(value: string): value is Role {
  return (ROLES as readonly string[]).includes(value);
}

/** Parses the comma separated role list stored on a user, ignoring unknown values. */
export function parseRoles(value: string | null | undefined): Role[] {
  if (!value) return [];
  return value
    .split(',')
    .map((r) => r.trim())
    .filter(isRole);
}

export function can(roles: readonly Role[], resource: Resource, action: Action): boolean {
  return roles.some((role) => PERMISSIONS[role][resource]?.includes(action) ?? false);
}

export function requiresTwoFactor(roles: readonly Role[]): boolean {
  return roles.some((r) => TWO_FACTOR_REQUIRED_ROLES.includes(r));
}
