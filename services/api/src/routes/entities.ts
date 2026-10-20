import { can, entities } from '@tbn/shared';
import { eq, or } from 'drizzle-orm';
import type { App } from '../context.js';
import * as s from '../db/schema.js';
import { registerCrud, type EntityDef } from './crud.js';

const str = (v: unknown) => String(v ?? '');

export const ENTITY_DEFS: EntityDef[] = [
  {
    name: 'Tour',
    path: 'tours',
    table: s.tours,
    resource: 'bookings',
    ...entities.tours,
    label: (o) => str(o.name),
    orderBy: s.tours.startDate,
  },
  {
    name: 'Live',
    path: 'lives',
    table: s.lives,
    resource: 'bookings',
    ...entities.lives,
    label: (o) => `${str(o.venue)} ${str(o.date)}`,
    orderBy: s.lives.date,
    toApi: ({ posterFileId, ...row }) => ({
      ...row,
      posterUrl: posterFileId ? `/api/v1/files/${str(posterFileId)}` : null,
    }),
  },
  {
    name: 'CalendarEvent',
    path: 'calendar-events',
    table: s.calendarEvents,
    resource: 'calendar',
    ...entities.calendarEvents,
    label: (o) => str(o.title),
    orderBy: s.calendarEvents.startsAt,
    // Private events are visible only to their owner.
    readScope: (user) => or(eq(s.calendarEvents.visibility, 'team'), eq(s.calendarEvents.ownerId, user.id)),
    toDb: (input, user, existing) => (existing ? input : { ...input, ownerId: user.id }),
    canModify: (user, obj, action) => {
      const own = obj.ownerId === user.id;
      if (action === 'delete') return own || can(user.roles, 'calendar', 'delete');
      return obj.visibility === 'team' || own;
    },
  },
  {
    name: 'Product',
    path: 'products',
    table: s.products,
    resource: 'merch',
    ...entities.products,
    label: (o) => str(o.name),
    orderBy: s.products.name,
    toApi: ({ imageFileId, ...row }) => ({
      ...row,
      imageUrl: imageFileId ? `/api/v1/files/${str(imageFileId)}` : null,
    }),
  },
  {
    name: 'Customer',
    path: 'customers',
    table: s.customers,
    resource: 'customers',
    ...entities.customers,
    label: (o) => `${str(o.firstName)} ${str(o.lastName)}`.trim(),
    orderBy: s.customers.lastName,
  },
  {
    name: 'Order',
    path: 'orders',
    table: s.orders,
    resource: 'orders',
    ...entities.orders,
    label: (o) => `#${str(o.number)}`,
    orderBy: s.orders.number,
  },
  {
    name: 'Member',
    path: 'members',
    table: s.members,
    resource: 'members',
    ...entities.members,
    label: (o) => `${str(o.name)} ${str(o.surname)}`.trim(),
    orderBy: s.members.surname,
  },
  {
    name: 'StreamingIncome',
    path: 'streaming-incomes',
    table: s.streamingIncomes,
    resource: 'finance',
    ...entities.streamingIncomes,
    label: (o) => `${str(o.platform)} ${str(o.date)}`,
    orderBy: s.streamingIncomes.date,
  },
  {
    name: 'GeneralExpense',
    path: 'general-expenses',
    table: s.generalExpenses,
    resource: 'finance',
    ...entities.generalExpenses,
    label: (o) => `${str(o.category)} ${str(o.date)}`,
    orderBy: s.generalExpenses.date,
  },
  {
    name: 'RentPerson',
    path: 'rent-people',
    table: s.rentPeople,
    resource: 'finance',
    ...entities.rentPeople,
    label: (o) => str(o.name),
    orderBy: s.rentPeople.createdAt,
  },
  {
    name: 'RentPayment',
    path: 'rent-payments',
    table: s.rentPayments,
    resource: 'finance',
    ...entities.rentPayments,
    label: (o) => `${str(o.month).slice(0, 7)} ${str(o.amountCents)}c`,
    orderBy: s.rentPayments.paymentDate,
  },
];

export function registerEntityRoutes(app: App) {
  for (const def of ENTITY_DEFS) registerCrud(app, def);
}
