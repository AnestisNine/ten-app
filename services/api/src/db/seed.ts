/**
 * Development seed: the same sample data the app shipped with, plus one user per role.
 * Refuses to run in production. Re-running wipes and recreates the sample data.
 */
import { hashPassword } from 'better-auth/crypto';
import type { Role } from '@tbn/shared';
import { randomUUID } from 'node:crypto';
import { sql as rawSql } from 'drizzle-orm';
import { createDb, type Db } from './client.js';
import * as s from './schema.js';
import { encryptJson } from '../crypto.js';

export const DEV_PASSWORD = 'tbn-dev-password';
/** A public preview must not use the well-known development password. */
const seedPassword = () => process.env.SEED_PASSWORD || DEV_PASSWORD;

export const DEV_USERS: { email: string; name: string; roles: Role[] }[] = [
  { email: 'admin@tbn.local', name: 'Admin', roles: ['admin'] },
  { email: 'manager@tbn.local', name: 'Manager', roles: ['manager'] },
  { email: 'member@tbn.local', name: 'Μέλος', roles: ['member'] },
  { email: 'accountant@tbn.local', name: 'Λογιστής', roles: ['accountant'] },
  { email: 'merch@tbn.local', name: 'Merch Manager', roles: ['merchManager'] },
  { email: 'pos@tbn.local', name: 'Merch Staff', roles: ['merchStaff'] },
  { email: 'social@tbn.local', name: 'Social', roles: ['member', 'socialManager'] },
];

export async function seed(db: Db, encryptionKey: string) {
  await db.transaction(async (tx) => {
    // Order matters because of foreign keys. audit_log is append-only and is left alone.
    for (const t of [
      s.orders, s.customers, s.products, s.files, s.lives, s.tours, s.calendarEvents, s.calendarFeeds,
      s.memberSensitive, s.members, s.streamingIncomes, s.generalExpenses, s.rentPayments, s.rentPeople,
      s.notifications, s.twoFactor, s.session, s.account, s.verification, s.user,
    ]) {
      await tx.delete(t);
    }
    await tx.execute(rawSql`ALTER SEQUENCE orders_number_seq RESTART WITH 1001`);

    const hash = await hashPassword(seedPassword());
    const userIds: Record<string, string> = {};
    for (const u of DEV_USERS) {
      const id = randomUUID();
      userIds[u.email] = id;
      await tx.insert(s.user).values({ id, name: u.name, email: u.email, emailVerified: true, roles: u.roles.join(',') });
      await tx.insert(s.account).values({ id: randomUUID(), accountId: id, providerId: 'credential', userId: id, password: hash });
    }

    await tx
      .insert(s.settings)
      .values({ id: 1 })
      .onConflictDoUpdate({
        target: s.settings.id,
        set: { monthlyRentCents: 35000, cashboxBalanceCents: 126500, dieselPriceCents: 175, fuelConsumption: 9.1, vanId: 'vw_t61', lowStockThreshold: 3 },
      });

    const [tour] = await tx
      .insert(s.tours)
      .values({ name: 'Autumn Tour 2026', startDate: '2026-09-15', endDate: '2026-10-18' })
      .returning();
    const zero = {
      cashIncomeCents: 0, merchIncomeCents: 0, soundExpensesCents: 0, extraExpensesCents: 0, doorDealCents: 0,
      fixCents: 0, soundEngineerFeeCents: 0, technicianFeeCents: 0, supportBandFeeCents: 0,
    };
    await tx.insert(s.lives).values([
      {
        venue: 'Fuzz Club', city: 'Athens', country: 'Greece', countryCode: 'GR', lat: 37.9838, lon: 23.7275,
        date: '2026-09-15', status: 'completed', tourId: tour!.id,
        ...zero, cashIncomeCents: 130000, merchIncomeCents: 42000, soundExpensesCents: 15000, extraExpensesCents: 19000,
        doorDealCents: 90000, fixCents: 40000, soundEngineerFeeCents: 15000, technicianFeeCents: 12000, supportBandFeeCents: 8000,
        mainAct: 'TBN', contactPerson: 'Promoter A', soundEngineer: 'Engineer A', ticketsPresale: 120, ticketsDoor: 55,
        generalInfo: 'Demo live information',
      },
      {
        venue: 'Principal Club Theater', city: 'Thessaloniki', country: 'Greece', countryCode: 'GR', lat: 40.6401, lon: 22.9444,
        date: '2026-10-03', status: 'completed', tourId: tour!.id, ...zero, fixCents: 60000, mainAct: 'TBN',
      },
      {
        venue: 'Gagarin 205', city: 'Athens', country: 'Greece', countryCode: 'GR', lat: 37.9838, lon: 23.7275,
        date: '2026-11-21', status: 'confirmed', ...zero, doorDealCents: 120000, mainAct: 'TBN', support: 'Support band',
      },
      {
        venue: 'Kulturfabrik', city: 'Sofia', country: 'Bulgaria', countryCode: 'BG', lat: 42.6977, lon: 23.3219,
        date: '2027-02-06', status: 'negotiation', ...zero,
      },
    ]);

    const [tshirt, hoodie] = await tx
      .insert(s.products)
      .values([
        { name: 'TBN T-Shirt', stock: 8, unitCostCents: 800, salePriceCents: 2000 },
        { name: 'TBN Hoodie', stock: 0, unitCostCents: 1800, salePriceCents: 4000 },
        { name: 'TBN Vinyl LP', stock: 25, unitCostCents: 900, salePriceCents: 2500 },
      ])
      .returning();
    const [customer] = await tx
      .insert(s.customers)
      .values({
        firstName: 'Γιάννης', lastName: 'Παπαδόπουλος', email: 'customer@example.com', phone: '6900000000',
        address: 'Example 10', city: 'Athens', postalCode: '11111', country: 'Greece',
      })
      .returning();
    await tx.insert(s.orders).values([
      {
        customerId: customer!.id, productId: tshirt!.id, quantity: 2, shippingCostCents: 600, shippingMethod: 'boxNow',
        status: 'waitingContact', source: 'organic', context: 'outsideLive',
      },
      {
        customerId: customer!.id, productId: tshirt!.id, quantity: 1, shippingCostCents: 500, shippingMethod: 'elta',
        status: 'completed', source: 'bandcamp', context: 'outsideLive',
      },
      {
        customerId: customer!.id, productId: hoodie!.id, quantity: 1, shippingCostCents: 0, shippingMethod: 'acs',
        status: 'waitingRestock', source: 'organic', context: 'afterLive',
      },
    ]);

    await tx.insert(s.calendarEvents).values([
      { startsAt: new Date('2026-11-04T18:00:00Z'), title: 'Πρόβα', type: 'Rehearsal', location: 'Studio', notes: 'Full band', visibility: 'team', ownerId: userIds['manager@tbn.local'] },
      { startsAt: new Date('2026-11-11T18:00:00Z'), title: 'Πρόβα', type: 'Rehearsal', location: 'Studio', visibility: 'team', ownerId: userIds['manager@tbn.local'] },
      { startsAt: new Date('2026-11-14T15:30:00Z'), title: 'Studio Session', type: 'Studio', location: 'TBN Studio', notes: 'Recording session', visibility: 'team', ownerId: userIds['admin@tbn.local'] },
      { startsAt: new Date('2026-11-06T09:00:00Z'), title: 'Γιατρός (ιδιωτικό)', type: 'Personal', visibility: 'private', ownerId: userIds['member@tbn.local'] },
    ]);

    await tx.insert(s.streamingIncomes).values([
      { platform: 'Spotify', amountCents: 18540, date: '2026-08-01' },
      { platform: 'Apple Music', amountCents: 7420, date: '2026-08-01' },
    ]);
    await tx.insert(s.generalExpenses).values([
      { category: 'recordingFee', amountCents: 35000, date: '2026-07-20', notes: 'Studio recording' },
      { category: 'rentFee', amountCents: 55000, date: '2026-08-01', notes: 'Studio rent' },
    ]);

    const people = await tx
      .insert(s.rentPeople)
      .values(Array.from({ length: 11 }, (_, i) => ({ name: `Άτομο ${i + 1}` })))
      .returning();
    await tx.insert(s.rentPayments).values([
      { personId: people[0]!.id, amountCents: 3182, paymentDate: '2026-10-03', method: 'iris', month: '2026-10-01' },
      { personId: people[1]!.id, amountCents: 3182, paymentDate: '2026-10-05', method: 'cash', month: '2026-10-01' },
    ]);

    const [member] = await tx
      .insert(s.members)
      .values([
        { role: 'musician', name: 'Member', surname: 'Example', mobile: '6900000000', email: 'member@tbn.local', userId: userIds['member@tbn.local'] },
        { role: 'driver', name: 'Driver', surname: 'Example', mobile: '6900000001', email: '' },
      ])
      .returning();
    await tx.insert(s.memberSensitive).values({
      memberId: member!.id,
      ciphertext: encryptJson(
        {
          fatherSurname: '', fatherName: 'Πατέρας', motherName: 'Μητέρα', birthDate: '1990-01-01', birthPlace: 'Αθήνα',
          nationality: 'Ελληνική', address: 'Οδός 1', maritalStatus: '', children: '', idNumber: 'AB123456', passport: '',
          issueDateAndAuthority: '', ama: '', afm: '000000000', doy: '', amka: '01019000000', contactPhone: '',
          iban: 'GR0000000000000000000000000', bank: '',
        },
        encryptionKey,
        `member_sensitive:${member!.id}`,
      ),
    });
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  // Wipes all data. In production only for a throw-away preview, explicitly: ALLOW_DEMO_SEED=1.
  if (process.env.NODE_ENV === 'production' && process.env.ALLOW_DEMO_SEED !== '1') {
    throw new Error('Refusing to seed a production database (set ALLOW_DEMO_SEED=1 for a demo instance)');
  }
  const url = process.env.DATABASE_URL;
  const key = process.env.DATA_ENCRYPTION_KEY;
  if (!url || !key) throw new Error('DATABASE_URL and DATA_ENCRYPTION_KEY must be set');
  const { db, sql } = createDb(url);
  // --if-empty: seed only a fresh database (used by the preview so restarts keep your changes).
  if (process.argv.includes('--if-empty') && (await db.select({ id: s.user.id }).from(s.user).limit(1)).length > 0) {
    console.log('Database already has users; skipping demo data.');
    await sql.end();
    process.exit(0);
  }
  await seed(db, key);
  await sql.end();
  console.log(`Seeded. Users (password ${process.env.SEED_PASSWORD ? 'from SEED_PASSWORD' : `"${DEV_PASSWORD}"`}):`);
  for (const u of DEV_USERS) console.log(`  ${u.email.padEnd(24)} ${u.roles.join(', ')}`);
}
