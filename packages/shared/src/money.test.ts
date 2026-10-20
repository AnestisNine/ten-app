import { describe, expect, it } from 'vitest';
import { formatMoney, parseMoney, splitEvenly, sumCents } from './money.js';

describe('parseMoney', () => {
  it.each([
    ['12', 1200],
    ['12.5', 1250],
    ['12,50', 1250],
    ['0,05', 5],
    ['1.234,56', 123456],
    ['1,234.56', 123456],
    ['1.234', 123400],
    ['1.234.567', 123456700],
    ['-3,2', -320],
    [' 20 € ', 2000],
  ])('%s → %i', (input, expected) => {
    expect(parseMoney(input)).toBe(expected);
  });

  it.each(['', 'abc', '1,234,56', '1.2345', '12.345.6', '--1', '1e3'])('rejects %s', (input) => {
    expect(parseMoney(input)).toBeNull();
  });
});

describe('formatMoney', () => {
  it('formats Greek style', () => {
    expect(formatMoney(123456, 'el').replace(/\s/g, ' ')).toBe('1.234,56 €');
  });
});

describe('splitEvenly', () => {
  it('distributes remainder so the parts sum to the total', () => {
    const parts = splitEvenly(35000, 11);
    expect(sumCents(parts)).toBe(35000);
    expect(parts[0]).toBe(3182);
    expect(parts[10]).toBe(3181);
  });
  it('handles negative totals', () => {
    expect(splitEvenly(-10, 3)).toEqual([-4, -3, -3]);
  });
  it('rejects bad part counts', () => {
    expect(() => splitEvenly(100, 0)).toThrow();
  });
});
