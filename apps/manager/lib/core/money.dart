/// Money is always an integer number of euro cents (same rules as packages/shared/src/money.ts).
library;

/// 123456 → "1.234,56 €"
String formatCents(int cents, {bool symbol = true}) {
  final negative = cents < 0;
  final abs = cents.abs();
  final euros = (abs ~/ 100).toString();
  final rest = (abs % 100).toString().padLeft(2, '0');
  final grouped = StringBuffer();
  for (var i = 0; i < euros.length; i++) {
    if (i > 0 && (euros.length - i) % 3 == 0) grouped.write('.');
    grouped.write(euros[i]);
  }
  return '${negative ? '-' : ''}$grouped,$rest${symbol ? ' €' : ''}';
}

/// Value for an editable text field, e.g. 1250 → "12,50".
String centsToInput(int cents) => formatCents(cents, symbol: false).replaceAll('.', '');

/// Parses "12", "12.5", "12,50", "1.234,56", "1,234.56", "-3,2" into cents; null if invalid.
/// A separator followed by 1–2 digits is the decimal mark; followed by exactly 3 digits it is a
/// thousands separator ("1.234" = 1234 €). More than two decimals is rejected, not rounded.
int? parseCents(String input) {
  final raw = input.trim().replaceAll(RegExp(r'\s|€'), '');
  if (raw.isEmpty) return null;
  final negative = raw.startsWith('-');
  final body = negative ? raw.substring(1) : raw;
  if (!RegExp(r'^[0-9.,]+$').hasMatch(body)) return null;

  final sepIndex = body.lastIndexOf('.') > body.lastIndexOf(',') ? body.lastIndexOf('.') : body.lastIndexOf(',');
  var intPart = body;
  var fracPart = '';
  if (sepIndex != -1) {
    final decimals = body.length - sepIndex - 1;
    final sepCount = body.split(body[sepIndex]).length - 1;
    if (decimals > 0 && decimals <= 2 && sepCount == 1) {
      intPart = body.substring(0, sepIndex);
      fracPart = body.substring(sepIndex + 1);
    } else if (decimals != 3) {
      return null;
    }
  }
  final intDigits = intPart.replaceAll(RegExp(r'[.,]'), '');
  if (intDigits.isEmpty && fracPart.isEmpty) return null;
  if (!RegExp(r'^\d*$').hasMatch(intDigits) || !RegExp(r'^\d{0,2}$').hasMatch(fracPart)) return null;
  final cents = int.parse(intDigits.isEmpty ? '0' : intDigits) * 100 +
      int.parse(fracPart.padRight(2, '0').isEmpty ? '0' : fracPart.padRight(2, '0'));
  return negative ? -cents : cents;
}

/// Splits an amount into [parts] shares that add up exactly to [total].
List<int> splitEvenly(int total, int parts) {
  if (parts <= 0) throw ArgumentError.value(parts, 'parts');
  final sign = total < 0 ? -1 : 1;
  final abs = total.abs();
  final base = abs ~/ parts;
  final remainder = abs - base * parts;
  return List<int>.generate(parts, (i) => sign * (base + (i < remainder ? 1 : 0)));
}
