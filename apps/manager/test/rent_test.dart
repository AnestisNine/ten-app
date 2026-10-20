import 'package:flutter_test/flutter_test.dart';
import 'package:tbn_manager/core/models.dart';
import 'package:tbn_manager/core/rent.dart';

void main() {
  final people = List.generate(11, (i) => RentPerson(id: 'p$i', name: 'Άτομο ${i + 1}'));
  RentPayment pay(String person, int cents, int month) => RentPayment(
        id: newId(),
        personId: person,
        amountCents: cents,
        paymentDate: DateTime(2026, month, 3),
        method: RentPaymentMethod.iris,
        month: DateTime(2026, month),
      );

  test('shares add up exactly to the monthly rent', () {
    final calc = RentCalculator(monthlyRentCents: 35000, people: people, payments: const []);
    expect(people.map(calc.shareFor).reduce((a, b) => a + b), 35000);
    expect(calc.shareFor(people.first), 3182);
    expect(calc.shareFor(people.last), 3181);
  });

  test('debts per month and per year, overpayment does not create credit', () {
    final calc = RentCalculator(
      monthlyRentCents: 35000,
      people: people,
      payments: [pay('p0', 3182, 1), pay('p0', 5000, 2), pay('p1', 1000, 1)],
    );
    expect(calc.debtForPersonMonth(people[0], 2026, 1), 0);
    expect(calc.debtForPersonMonth(people[0], 2026, 2), 0);
    expect(calc.debtForPersonMonth(people[0], 2026, 3), 3182);
    expect(calc.yearDebtForPerson(people[1], 2026, 2), (3182 - 1000) + 3182);
    expect(calc.paidInMonth(2026, 1), 4182);
    expect(calc.remainingForMonth(2026, 1), 35000 - 4182);
    expect(calc.remainingForMonth(2026, 2), 30000);
  });

  test('no people means no shares', () {
    final calc = RentCalculator(monthlyRentCents: 35000, people: const [], payments: const []);
    expect(calc.displayShare, 0);
    expect(calc.yearDebtTotal(2026, 12), 0);
  });
}
