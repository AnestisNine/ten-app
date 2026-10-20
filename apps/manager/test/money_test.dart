import 'package:flutter_test/flutter_test.dart';
import 'package:tbn_manager/core/money.dart';

void main() {
  group('parseCents (same cases as packages/shared money.test.ts)', () {
    const ok = {
      '12': 1200,
      '12.5': 1250,
      '12,50': 1250,
      '0,05': 5,
      '1.234,56': 123456,
      '1,234.56': 123456,
      '1.234': 123400,
      '1.234.567': 123456700,
      '-3,2': -320,
      ' 20 € ': 2000,
    };
    ok.forEach((input, expected) {
      test('"$input" → $expected', () => expect(parseCents(input), expected));
    });
    for (final bad in ['', 'abc', '1,234,56', '1.2345', '12.345.6', '--1', '1e3']) {
      test('rejects "$bad"', () => expect(parseCents(bad), isNull));
    }
  });

  test('formatCents', () {
    expect(formatCents(123456), '1.234,56 €');
    expect(formatCents(-5), '-0,05 €');
    expect(formatCents(0), '0,00 €');
    expect(centsToInput(123456), '1234,56');
    expect(parseCents(centsToInput(123456)), 123456);
  });

  test('splitEvenly keeps the total exact', () {
    final parts = splitEvenly(35000, 11);
    expect(parts.reduce((a, b) => a + b), 35000);
    expect(parts.first, 3182);
    expect(parts.last, 3181);
  });
}
