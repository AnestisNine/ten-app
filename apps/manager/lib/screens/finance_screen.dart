import 'package:flutter/material.dart';

import '../core/finance.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final f = FinanceSummary(
      lives: AppStore.lives,
      orders: AppStore.orders,
      products: AppStore.products,
      streaming: AppStore.streamingIncomes,
      expenses: AppStore.generalExpenses,
    );
    final liveIncome = f.liveIncome;
    final liveExpenses = f.liveExpenses;
    final completedOrderIncome = f.orderIncome;
    final streamingIncome = f.streamingIncome;
    final recordingExpenses = f.recordingExpenses;
    final rentExpenses = f.rentExpenses;
    final totalIncome = f.totalIncome;
    final totalExpenses = f.totalExpenses;
    final net = f.net;

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
    int amount,
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
    int amount,
    Color color,
    String? subtitle,
  ) {
    final t = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
