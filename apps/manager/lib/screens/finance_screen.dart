import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final completedLives = AppStore.lives.where(
      (live) => live.status == LiveStatus.completed,
    );

    final liveIncome = completedLives.fold<double>(
      0,
      (sum, live) => sum + live.totalIncome,
    );

    final liveExpenses = completedLives.fold<double>(
      0,
      (sum, live) => sum + live.totalExpenses,
    );

    final completedOrderIncome = AppStore.orders
        .where((order) => order.status == OrderStatus.completed)
        .fold<double>(0, (sum, order) {
      final product = AppStore.productById(order.productId);
      return sum + (product.salePrice * order.quantity) + order.shippingCost;
    });

    final streamingIncome = AppStore.streamingIncomeTotal.value;

    final recordingExpenses = AppStore.generalExpenses
        .where((item) =>
            item.category == GeneralExpenseCategory.recordingFee)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final rentExpenses = AppStore.generalExpenses
        .where((item) =>
            item.category == GeneralExpenseCategory.rentFee)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final totalIncome =
        liveIncome + completedOrderIncome + streamingIncome;
    final totalExpenses =
        liveExpenses + recordingExpenses + rentExpenses;
    final net = totalIncome - totalExpenses;

    final t = Theme.of(context).textTheme;
    final netColor = net >= 0 ? TbnColors.success : TbnColors.danger;

    return Scaffold(
      appBar: AppBar(title: const Text('Οικονομικά')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ΚΑΘΑΡΟ ΑΠΟΤΕΛΕΣΜΑ', style: t.labelSmall),
                  const SizedBox(height: 8),
                  Text(
                    formatEuro(net),
                    style: t.headlineLarge?.copyWith(color: netColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _total(
                          context,
                          'Έσοδα',
                          totalIncome,
                          TbnColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _total(
                          context,
                          'Έξοδα',
                          totalExpenses,
                          TbnColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionLabel('Έσοδα'),
          _group(context, [
            _row(
              context,
              Icons.mic_none_rounded,
              'Ολοκληρωμένα Live',
              liveIncome,
              TbnColors.success,
              'Door Deal + Fix + Merch',
            ),
            _row(
              context,
              Icons.local_shipping_outlined,
              'Ολοκληρωμένες παραγγελίες',
              completedOrderIncome,
              TbnColors.success,
              'Organic + Bandcamp',
            ),
            _row(
              context,
              Icons.graphic_eq_rounded,
              'Streaming platforms',
              streamingIncome,
              TbnColors.success,
              'Spotify, Apple Music κ.ά.',
            ),
          ]),
          const SectionLabel('Έξοδα'),
          _group(context, [
            _row(
              context,
              Icons.mic_none_rounded,
              'Ολοκληρωμένα Live',
              liveExpenses,
              TbnColors.danger,
              'Ηχολήπτης + Τεχνικός + Support bands',
            ),
            _row(
              context,
              Icons.album_outlined,
              'Αμοιβές ηχογραφήσεων',
              recordingExpenses,
              TbnColors.danger,
              null,
            ),
            _row(
              context,
              Icons.home_work_outlined,
              'Ενοίκιο',
              rentExpenses,
              TbnColors.danger,
              null,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _total(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodySmall),
          const SizedBox(height: 2),
          Text(
            formatEuro(amount),
            style: t.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(const Divider(indent: 66));
      }
    }
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String title,
    double amount,
    Color color,
    String? subtitle,
  ) {
    final t = Theme.of(context).textTheme;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: IconChip(icon: icon, color: color, size: 38),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Text(
        formatEuro(amount),
        style: t.titleSmall?.copyWith(color: color),
      ),
    );
  }
}
