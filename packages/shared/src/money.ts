/**
 * Money is always an integer amount of euro cents. Never use floats for money.
 */
export type Cents = number;

export function assertCents(value: number): Cents {
  if (!Number.isSafeInteger(value)) {
    throw new RangeError(`Money must be an integer number of cents, got ${value}`);
  }
  return value;
}

/**
 * Parses user input such as "12", "12.5", "12,50", "1.234,56", "1,234.56", "-3,2"
 * into cents. Returns null when the input is not a valid amount.
 * More than two decimal digits is rejected rather than silently rounded.
 */
export function parseMoney(input: string): Cents | null {
  const raw = input.trim().replace(/\s|€/g, '');
  if (raw === '') return null;
  const negative = raw.startsWith('-');
  const body = negative ? raw.slice(1) : raw;
  if (!/^[0-9.,]+$/.test(body)) return null;

  const lastDot = body.lastIndexOf('.');
  const lastComma = body.lastIndexOf(',');
  const sepIndex = Math.max(lastDot, lastComma);
  let intPart = body;
  let fracPart = '';
  if (sepIndex !== -1) {
    const decimals = body.length - sepIndex - 1;
    const sepCount = body.split(body[sepIndex]!).length - 1;
    // A separator followed by 1-2 digits is the decimal mark; followed by exactly
    // 3 digits it is a thousands separator ("1.234" = 1234 €, Greek convention).
    const isDecimal =
      decimals > 0 &&
      decimals <= 2 &&
      sepCount === 1;
    if (isDecimal) {
      intPart = body.slice(0, sepIndex);
      fracPart = body.slice(sepIndex + 1);
    } else if (decimals === 3) {
      intPart = body;
    } else {
      return null;
    }
  }
  const intDigits = intPart.replace(/[.,]/g, '');
  if (intDigits === '' && fracPart === '') return null;
  if (!/^\d*$/.test(intDigits) || !/^\d{0,2}$/.test(fracPart)) return null;
  const cents = Number(intDigits || '0') * 100 + Number(fracPart.padEnd(2, '0') || '0');
  if (!Number.isSafeInteger(cents)) return null;
  return negative ? -cents : cents;
}

/** Formats cents for display, e.g. 123456 → "1.234,56 €" (el) or "€1,234.56" (en). */
export function formatMoney(cents: Cents, locale: 'el' | 'en' = 'el'): string {
  return new Intl.NumberFormat(locale === 'el' ? 'el-GR' : 'en-IE', {
    style: 'currency',
    currency: 'EUR',
  }).format(cents / 100);
}

/** Splits an amount into n parts that sum exactly to the total (remainder cents go to the first parts). */
export function splitEvenly(total: Cents, parts: number): Cents[] {
  if (!Number.isInteger(parts) || parts <= 0) throw new RangeError('parts must be a positive integer');
  assertCents(total);
  const sign = total < 0 ? -1 : 1;
  const abs = Math.abs(total);
  const base = Math.floor(abs / parts);
  const remainder = abs - base * parts;
  return Array.from({ length: parts }, (_, i) => sign * (base + (i < remainder ? 1 : 0)));
}

export function sumCents(values: readonly Cents[]): Cents {
  return values.reduce((a, b) => a + b, 0);
}
