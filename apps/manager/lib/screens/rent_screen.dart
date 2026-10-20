import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/money.dart';
import '../core/rent.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';

class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  DateTime focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final monthPayments = _paymentsForMonth(focusedMonth);
    final paidIds = monthPayments.map((p) => p.personId).toSet();

    final calc = _calc;
    final paidAmount = calc.paidInMonth(focusedMonth.year, focusedMonth.month);
    final monthlyCost = calc.monthlyRentCents;
    final remainingAmount = calc.remainingForMonth(focusedMonth.year, focusedMonth.month);
    final peopleCount = AppStore.rentPeople.length;
    final progress = monthlyCost <= 0 ? 0.0 : (paidAmount / monthlyCost).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ενοίκιο'),
        actions: [
          IconButton(
            tooltip: 'Ανάλυση οφειλών',
            onPressed: _showYearAnalysis,
            icon: const Icon(Icons.analytics_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: FilledButton.icon(
              onPressed: _addPayment,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Πληρωμή'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            focusedMonth = DateTime(
                              focusedMonth.year,
                              focusedMonth.month - 1,
                              1,
                            );
                          });
                        },
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _monthLabel(focusedMonth),
                              textAlign: TextAlign.center,
                              style: t.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Μηνιαίο ενοίκιο ${formatEuro(monthlyCost)}',
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            focusedMonth = DateTime(
                              focusedMonth.year,
                              focusedMonth.month + 1,
                              1,
                            );
                          });
                        },
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            color: progress >= 1 ? TbnColors.success : TbnColors.accent,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${formatEuro(paidAmount)} πληρωμένα',
                              style: t.bodySmall,
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: t.labelMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Πλήρωσαν',
                  '${paidIds.length}/$peopleCount',
                  TbnColors.success,
                  Icons.people_alt_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  'Αναμένεται',
                  formatEuro(remainingAmount),
                  remainingAmount == 0 ? TbnColors.success : TbnColors.warning,
                  Icons.schedule_outlined,
                ),
              ),
            ],
          ),
          if (paidAmount > monthlyCost) ...[
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const IconChip(
                  icon: Icons.info_outline,
                  color: TbnColors.warning,
                ),
                title: const Text('Υπέρβαση ενοικίου'),
                subtitle: Text(
                  'Έχουν καταχωρηθεί '
                  '${formatEuro(paidAmount - monthlyCost)} '
                  'πάνω από το μηνιαίο κόστος.',
                ),
              ),
            ),
          ],
          const SectionLabel('Άτομα'),
          ...AppStore.rentPeople.map((person) {
            final payments = monthPayments.where((p) => p.personId == person.id).toList();

            final total = payments.fold<int>(
              0,
              (sum, payment) => sum + payment.amountCents,
            );
            final share = calc.shareFor(person);
            final remaining = share - total < 0 ? 0 : share - total;
            final paid = remaining == 0 && total > 0;
            final color = paid
                ? TbnColors.success
                : total > 0
                    ? TbnColors.warning
                    : TbnColors.danger;
            final initial = person.name.isEmpty ? '?' : person.name[0].toUpperCase();

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showPayments(person, payments),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: color.withValues(alpha: 0.15),
                        foregroundColor: color,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(person.name, style: t.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              paid
                                  ? 'Πλήρωσε ${formatEuro(total)}'
                                  : 'Πλήρωσε ${formatEuro(total)} · '
                                      'υπόλοιπο ${formatEuro(remaining)}',
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusPill(
                        label: paid
                            ? 'Πληρώθηκε'
                            : total > 0
                                ? 'Μερικώς'
                                : 'Οφείλει',
                        color: color,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  RentCalculator get _calc => RentCalculator(
        monthlyRentCents: AppStore.settings.value.monthlyRentCents,
        people: AppStore.rentPeople,
        payments: AppStore.rentPayments,
      );

  List<RentPayment> _paymentsForMonth(DateTime month) {
    return AppStore.rentPayments.where((payment) {
      return payment.month.year == month.year && payment.month.month == month.month;
    }).toList();
  }

  Widget _summaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconChip(icon: icon, color: color, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: t.titleMedium),
                  Text(
                    title,
                    style: t.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addPayment() {
    RentPerson person = AppStore.rentPeople.first;
    final amount = TextEditingController();
    DateTime paymentDate = DateTime.now();
    DateTime month = focusedMonth;
    RentPaymentMethod method = RentPaymentMethod.iris;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Νέα πληρωμή ενοικίου',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<RentPerson>(
                    initialValue: person,
                    decoration: const InputDecoration(
                      labelText: 'Όνομα',
                    ),
                    items: AppStore.rentPeople
                        .map(
                          (item) => DropdownMenuItem<RentPerson>(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        modalSetState(() {
                          person = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ποσό',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ημερομηνία πληρωμής'),
                    trailing: Text(_date(paymentDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: paymentDate,
                      );
                      if (picked != null) {
                        modalSetState(() {
                          paymentDate = picked;
                        });
                      }
                    },
                  ),
                  DropdownButtonFormField<RentPaymentMethod>(
                    initialValue: method,
                    decoration: const InputDecoration(
                      labelText: 'Τρόπος πληρωμής',
                    ),
                    items: RentPaymentMethod.values.map((value) {
                      return DropdownMenuItem<RentPaymentMethod>(
                        value: value,
                        child: Text(
                          rentPaymentMethodLabel(value),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        modalSetState(() {
                          method = value;
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Μήνας που αφορά'),
                    trailing: Text(_monthLabel(month)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: month,
                      );
                      if (picked != null) {
                        modalSetState(() {
                          month = DateTime(
                            picked.year,
                            picked.month,
                            1,
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      final parsed = parseCents(amount.text);
                      if (parsed == null || parsed <= 0) {
                        return;
                      }

                      AppStore.create(
                        RentPayment(
                          id: newId(),
                          personId: person.id,
                          amountCents: parsed,
                          paymentDate: paymentDate,
                          method: method,
                          month: month,
                        ),
                      );
                      setState(() {
                        focusedMonth = month;
                      });

                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Καταχώρηση πληρωμής',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPayments(
    RentPerson person,
    List<RentPayment> payments,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final currentPayments = AppStore.rentPayments
                .where((p) =>
                    p.personId == person.id && p.month.year == focusedMonth.year && p.month.month == focusedMonth.month)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _monthLabel(focusedMonth),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                if (currentPayments.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text(
                        'Δεν υπάρχει καταχωρημένη πληρωμή',
                      ),
                    ),
                  ),
                ...currentPayments.map(
                  (payment) => Card(
                    child: ListTile(
                      title: Text(
                        formatCents(payment.amountCents),
                      ),
                      subtitle: Text(
                        '${_date(payment.paymentDate)} · '
                        '${rentPaymentMethodLabel(payment.method)}',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () async {
                        await _editPayment(payment);
                        modalSetState(() {});
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  Future<void> _editPayment(RentPayment payment) async {
    final person = AppStore.rentPeople.firstWhere(
      (item) => item.id == payment.personId,
    );
    RentPerson selectedPerson = person;
    final amount = TextEditingController(
      text: centsToInput(payment.amountCents),
    );
    DateTime paymentDate = payment.paymentDate;
    DateTime month = payment.month;
    RentPaymentMethod method = payment.method;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Επεξεργασία πληρωμής',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<RentPerson>(
                    initialValue: selectedPerson,
                    decoration: const InputDecoration(
                      labelText: 'Όνομα',
                    ),
                    items: AppStore.rentPeople
                        .map(
                          (item) => DropdownMenuItem<RentPerson>(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        modalSetState(() {
                          selectedPerson = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ποσό',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ημερομηνία πληρωμής'),
                    trailing: Text(_date(paymentDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: paymentDate,
                      );
                      if (picked != null) {
                        modalSetState(() {
                          paymentDate = picked;
                        });
                      }
                    },
                  ),
                  DropdownButtonFormField<RentPaymentMethod>(
                    initialValue: method,
                    decoration: const InputDecoration(
                      labelText: 'Τρόπος πληρωμής',
                    ),
                    items: RentPaymentMethod.values.map((value) {
                      return DropdownMenuItem<RentPaymentMethod>(
                        value: value,
                        child: Text(
                          rentPaymentMethodLabel(value),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        modalSetState(() {
                          method = value;
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Μήνας που αφορά'),
                    trailing: Text(_monthLabel(month)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: month,
                      );
                      if (picked != null) {
                        modalSetState(() {
                          month = DateTime(
                            picked.year,
                            picked.month,
                            1,
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final parsed = parseCents(amount.text);
                      if (parsed == null || parsed <= 0) {
                        return;
                      }

                      setState(() {
                        payment.personId = selectedPerson.id;
                        payment.amountCents = parsed;
                        payment.paymentDate = paymentDate;
                        payment.method = method;
                        payment.month = month;
                        focusedMonth = month;
                      });
                      AppStore.update(payment);

                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Αποθήκευση αλλαγών',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showYearAnalysis() {
    final year = focusedMonth.year;
    final lastMonth = year == DateTime.now().year ? DateTime.now().month : 12;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .94,
          maxChildSize: .98,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ανάλυση οφειλών',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Text(
                      '$year',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Ιανουάριος έως ${_monthName(lastMonth)} · '
                  'Μερίδιο ανά άτομο / μήνα: ${formatCents(_calc.displayShare)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ...AppStore.rentPeople.map((person) {
                  final calc = _calc;
                  var totalDebt = 0;

                  final monthRows = <Widget>[];
                  for (var month = 1; month <= lastMonth; month++) {
                    final paid = calc.paidByPerson(person, year, month);
                    final debt = calc.debtForPersonMonth(person, year, month);
                    totalDebt += debt;

                    monthRows.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 3,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _monthName(month),
                              ),
                            ),
                            Text(
                              'Πλήρωσε ${formatCents(paid)}',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 92,
                              child: Text(
                                debt == 0 ? '0,00 €' : formatCents(debt),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: debt == 0 ? TbnColors.success : TbnColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    child: ExpansionTile(
                      title: Text(
                        person.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Συνολική οφειλή: ${formatCents(totalDebt)}',
                      ),
                      trailing: Text(
                        formatCents(totalDebt),
                        style: TextStyle(
                          color: totalDebt == 0 ? TbnColors.success : TbnColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        14,
                      ),
                      children: monthRows,
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  String _date(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }

  String _monthLabel(DateTime value) {
    return '${_monthName(value.month)} ${value.year}';
  }

  String _monthName(int month) {
    const months = <String>[
      'Ιανουάριος',
      'Φεβρουάριος',
      'Μάρτιος',
      'Απρίλιος',
      'Μάιος',
      'Ιούνιος',
      'Ιούλιος',
      'Αύγουστος',
      'Σεπτέμβριος',
      'Οκτώβριος',
      'Νοέμβριος',
      'Δεκέμβριος',
    ];
    return months[month - 1];
  }
}
