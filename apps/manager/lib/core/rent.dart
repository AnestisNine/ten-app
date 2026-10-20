import 'models.dart';
import 'money.dart';

/// Rent arithmetic shared by the Rent page and the dashboard. All amounts in cents.
class RentCalculator {
  RentCalculator({required this.monthlyRentCents, required this.people, required this.payments});

  final int monthlyRentCents;
  final List<RentPerson> people;
  final List<RentPayment> payments;

  /// Each person's monthly share. Shares add up exactly to the rent (remainder cents go to the
  /// first people in the list), e.g. 350 € / 11 = 31,82 € × 2 + 31,81 € × 9.
  int shareFor(RentPerson person) {
    if (people.isEmpty) return 0;
    final i = people.indexWhere((p) => p.id == person.id);
    if (i < 0) return 0;
    return splitEvenly(monthlyRentCents, people.length)[i];
  }

  /// Typical share, for display.
  int get displayShare => people.isEmpty ? 0 : splitEvenly(monthlyRentCents, people.length).last;

  bool _inMonth(RentPayment p, int year, int month) => p.month.year == year && p.month.month == month;

  int paidInMonth(int year, int month) =>
      payments.where((p) => _inMonth(p, year, month)).fold(0, (sum, p) => sum + p.amountCents);

  int paidByPerson(RentPerson person, int year, int month) => payments
      .where((p) => p.personId == person.id && _inMonth(p, year, month))
      .fold(0, (sum, p) => sum + p.amountCents);

  int remainingForMonth(int year, int month) {
    final r = monthlyRentCents - paidInMonth(year, month);
    return r < 0 ? 0 : r;
  }

  int debtForPersonMonth(RentPerson person, int year, int month) {
    final d = shareFor(person) - paidByPerson(person, year, month);
    return d < 0 ? 0 : d;
  }

  /// What the person owes from January up to and including [upToMonth].
  int yearDebtForPerson(RentPerson person, int year, int upToMonth) {
    var total = 0;
    for (var m = 1; m <= upToMonth; m++) {
      total += debtForPersonMonth(person, year, m);
    }
    return total;
  }

  int yearDebtTotal(int year, int upToMonth) => people.fold(0, (sum, p) => sum + yearDebtForPerson(p, year, upToMonth));
}
