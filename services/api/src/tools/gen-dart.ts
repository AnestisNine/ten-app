/**
 * Generates the Dart model classes of the Flutter app from the shared zod schemas, so the app and
 * the API cannot drift apart. Output: apps/manager/lib/api/models.g.dart (checked in; CI fails if stale).
 *   pnpm gen:dart
 */
import * as shared from '@tbn/shared';
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { z } from 'zod';

const OUT = fileURLToPath(new URL('../../../../apps/manager/lib/api/models.g.dart', import.meta.url));

/** zod schema → Dart class name (kept equal to the app's historical names). */
const CLASSES: [z.ZodObject, string, string][] = [
  [shared.Tour, 'TourItem', 'tours'],
  [shared.Live, 'LiveItem', 'lives'],
  [shared.Product, 'ProductItem', 'products'],
  [shared.Customer, 'CustomerItem', 'customers'],
  [shared.Order, 'OrderItem', 'orders'],
  [shared.CalendarEvent, 'CalendarItem', 'calendar-events'],
  [shared.Member, 'MemberItem', 'members'],
  [shared.MemberSensitive, 'MemberSensitive', ''],
  [shared.StreamingIncome, 'StreamingIncome', 'streaming-incomes'],
  [shared.GeneralExpense, 'GeneralExpense', 'general-expenses'],
  [shared.RentPerson, 'RentPerson', 'rent-people'],
  [shared.RentPayment, 'RentPayment', 'rent-payments'],
  [shared.Settings, 'AppSettings', ''],
  [shared.AuditEntry, 'AuditItem', ''],
  [shared.Notification, 'AppNotification', ''],
];

const ENUMS: [z.ZodEnum, string][] = [
  [shared.LiveStatus, 'LiveStatus'],
  [shared.OrderStatus, 'OrderStatus'],
  [shared.ShippingMethod, 'ShippingMethod'],
  [shared.OrderSource, 'OrderSource'],
  [shared.OrderContext, 'OrderContext'],
  [shared.RentPaymentMethod, 'RentPaymentMethod'],
  [shared.GeneralExpenseCategory, 'GeneralExpenseCategory'],
  [shared.MemberRole, 'MemberRole'],
  [shared.CalendarVisibility, 'CalendarVisibility'],
  [shared.AuditAction, 'AuditAction'],
];

/** Fields the server assigns; they are never sent back. */
const SERVER_FIELDS = new Set(['number', 'createdAt', 'ownerId', 'imageUrl', 'posterUrl']);

type Json = Record<string, any>;
interface DartType {
  base: 'String' | 'int' | 'double' | 'bool' | 'DateTime' | 'enum';
  enumName?: string;
  dateOnly?: boolean;
  nullable: boolean;
}

const enumByValues = new Map(ENUMS.map(([e, name]) => [JSON.stringify(e.options), name]));

function resolve(schema: Json): DartType {
  if (schema.anyOf) {
    const nonNull = schema.anyOf.filter((s: Json) => s.type !== 'null');
    const nullable = nonNull.length < schema.anyOf.length;
    const types = nonNull.map(resolve);
    if (types.every((t: DartType) => t.base === 'String')) return { base: 'String', nullable };
    if (types.length === 1) return { ...types[0]!, nullable };
    throw new Error(`Unsupported union ${JSON.stringify(schema)}`);
  }
  let type = schema.type;
  let nullable = false;
  if (Array.isArray(type)) {
    nullable = type.includes('null');
    type = type.find((t: string) => t !== 'null');
  }
  if (schema.enum) {
    const name = enumByValues.get(JSON.stringify(schema.enum));
    if (!name) throw new Error(`Unregistered enum ${JSON.stringify(schema.enum)}`);
    return { base: 'enum', enumName: name, nullable };
  }
  if (type === 'string' && schema.format === 'date') return { base: 'DateTime', dateOnly: true, nullable };
  if (type === 'string' && schema.format === 'date-time') return { base: 'DateTime', nullable };
  if (type === 'string') return { base: 'String', nullable };
  if (type === 'integer') return { base: 'int', nullable };
  if (type === 'number') return { base: 'double', nullable };
  if (type === 'boolean') return { base: 'bool', nullable };
  throw new Error(`Unsupported schema ${JSON.stringify(schema)}`);
}

const dartName = (t: DartType) => (t.base === 'enum' ? t.enumName! : t.base) + (t.nullable ? '?' : '');

function defaultFor(t: DartType): string | null {
  if (t.nullable) return null; // optional parameter, defaults to null
  switch (t.base) {
    case 'String':
      return "''";
    case 'int':
      return '0';
    case 'double':
      return '0';
    case 'bool':
      return 'false';
    default:
      return 'required';
  }
}

function fromJsonExpr(key: string, t: DartType): string {
  const v = `json['${key}']`;
  const wrap = (expr: string) => (t.nullable ? `${v} == null ? null : ${expr}` : expr);
  switch (t.base) {
    case 'String':
      return t.nullable ? `${v} as String?` : `(${v} as String?) ?? ''`;
    case 'int':
      return t.nullable ? `(${v} as num?)?.toInt()` : `(${v} as num).toInt()`;
    case 'double':
      return t.nullable ? `(${v} as num?)?.toDouble()` : `(${v} as num).toDouble()`;
    case 'bool':
      return t.nullable ? `${v} as bool?` : `(${v} as bool?) ?? false`;
    case 'DateTime':
      return wrap(t.dateOnly ? `parseApiDate(${v} as String)` : `DateTime.parse(${v} as String).toLocal()`);
    case 'enum':
      return wrap(`${t.enumName}.values.byName(${v} as String)`);
  }
}

function toJsonExpr(field: string, t: DartType): string {
  const q = t.nullable ? '?' : '';
  switch (t.base) {
    case 'DateTime':
      return t.dateOnly ? (t.nullable ? `${field} == null ? null : formatApiDate(${field}!)` : `formatApiDate(${field})`) : `${field}${q}.toUtc().toIso8601String()`;
    case 'enum':
      return `${field}${q}.name`;
    default:
      return field;
  }
}

const lines: string[] = [
  '// GENERATED by services/api/src/tools/gen-dart.ts from packages/shared/src/schemas.ts.',
  '// Do not edit by hand: change the zod schema and run `pnpm gen:dart`.',
  '// ignore_for_file: prefer_const_constructors, unnecessary_this',
  '',
  "part of 'models.dart';",
  '',
];

for (const [e, name] of ENUMS) {
  lines.push(`enum ${name} { ${e.options.join(', ')} }`, '');
}

lines.push('/// API path segment of each entity, e.g. LiveItem → "lives".');
lines.push('const Map<Type, String> apiPaths = {');
for (const [, name, path] of CLASSES) if (path) lines.push(`  ${name}: '${path}',`);
lines.push('};', '');

for (const [schema, name] of CLASSES) {
  const js = z.toJSONSchema(schema) as Json;
  const required = new Set<string>(js.required ?? []);
  const fields = Object.entries(js.properties as Json).map(([key, s]) => {
    const t = resolve(s);
    if (!required.has(key)) t.nullable = true;
    return { key, t, desc: (s as Json).description as string | undefined };
  });
  const hasId = fields.some((f) => f.key === 'id');

  lines.push(`class ${name} {`);
  lines.push(`  ${name}({`);
  for (const f of fields) {
    const d = f.key === 'id' ? 'required' : defaultFor(f.t);
    lines.push(d === 'required' ? `    required this.${f.key},` : d === null ? `    this.${f.key},` : `    this.${f.key} = ${d},`);
  }
  lines.push('  });', '');
  lines.push(`  factory ${name}.fromJson(Map<String, dynamic> json) => ${name}(`);
  for (const f of fields) lines.push(`        ${f.key}: ${fromJsonExpr(f.key, f.t)},`);
  lines.push('      );', '');
  for (const f of fields) {
    if (f.desc) lines.push(`  /// ${f.desc.replace(/\n/g, ' ')}`);
    lines.push(`  ${f.key === 'id' ? 'final ' : ''}${dartName(f.t)} ${f.key};`);
  }
  lines.push('');
  lines.push('  /// JSON for the API. Server-assigned fields are left out.');
  lines.push('  Map<String, dynamic> toJson() => {');
  for (const f of fields) {
    if (SERVER_FIELDS.has(f.key)) continue;
    lines.push(`        '${f.key}': ${toJsonExpr(f.key, f.t)},`);
  }
  lines.push('      };', '');
  lines.push(`  ${name} copy() => ${name}.fromJson({...toJson(), ${fields
    .filter((f) => SERVER_FIELDS.has(f.key))
    .map((f) => `'${f.key}': ${toJsonExpr(f.key, f.t)}`)
    .join(', ')}});`);
  if (hasId) {
    lines.push('');
    lines.push(`  @override\n  bool operator ==(Object other) => other is ${name} && other.id == id;\n`);
    lines.push('  @override\n  int get hashCode => id.hashCode;');
  }
  lines.push('}', '');
}

writeFileSync(OUT, lines.join('\n'));
console.log(`Wrote ${OUT}`);
