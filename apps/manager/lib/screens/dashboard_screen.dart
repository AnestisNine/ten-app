import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';
import 'auth_screen.dart';
import 'live_detail_screen.dart';
import 'menu_detail_screens.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onNavigate,
  });

  final void Function(int index) onNavigate;

  static const _live = 1;
  static const _merch = 3;
  static const _calendar = 4;
  static const _menu = 5;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final nextLive = AppStore.nextConfirmedLive();
    final confirmedCount = AppStore.confirmedUpcomingCount();

    final pendingOrders = AppStore.orders
        .where((o) =>
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled)
        .length;

    final unread =
        AppStore.notifications.where((n) => !n.read).length;

    final rehearsal = AppStore.nextRehearsal();
    final rentPaidThisMonth = AppStore.rentPayments
        .where((p) =>
            p.month.year == now.year && p.month.month == now.month)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final rentRemaining =
        (AppStore.monthlyRentCost.value - rentPaidThisMonth)
            .clamp(0, double.infinity)
            .toDouble();

    var rentDebt = 0.0;
    final people = AppStore.rentPeople;
    if (people.isNotEmpty) {
      final share = AppStore.monthlyRentCost.value / people.length;
      for (final person in people) {
        for (var m = 1; m <= now.month; m++) {
          final paid = AppStore.rentPayments
              .where((p) =>
                  p.personId == person.id &&
                  p.month.year == now.year &&
                  p.month.month == m)
              .fold<double>(0, (sum, p) => sum + p.amount);
          if (share - paid > 0) {
            rentDebt += share - paid;
          }
        }
      }
    }

    final hour = now.hour;
    final greeting = hour < 12
        ? 'Καλημέρα'
        : hour < 18
            ? 'Καλό απόγευμα'
            : 'Καλησπέρα';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: t.headlineMedium),
                      const SizedBox(height: 2),
                      Text(greekDateLong(now), style: t.bodySmall),
                    ],
                  ),
                ),
                const TbnLogoMark(size: 46),
              ],
            ),
          ),
          _NewsCard(
            live: nextLive,
            rehearsal: rehearsal,
            today: today,
            onLive: () {
              if (nextLive == null) {
                onNavigate(_live);
                return;
              }
              Navigator.of(context).push(
                TbnPageRoute<void>(
                  builder: (_) => LiveDetailScreen(live: nextLive),
                ),
              );
            },
            onRehearsal: () => onNavigate(_calendar),
          ),
          const SectionLabel('Σύνοψη'),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 560 ? 3 : 2;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 124,
                ),
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: AppStore.cashboxBalance,
                    builder: (context, balance, _) {
                      return KpiCard(
                        title: 'Υπόλοιπο ταμείου',
                        value: formatEuro(balance),
                        icon: Icons.savings_outlined,
                        color: balance >= 0
                            ? TbnColors.success
                            : TbnColors.danger,
                        onTap: () {
                          Navigator.of(context).push(
                            TbnPageRoute<void>(
                              builder: (_) => const CashboxScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  KpiCard(
                    title: 'Επιβεβαιωμένα live',
                    value: '$confirmedCount',
                    icon: Icons.mic_none_rounded,
                    color: TbnColors.info,
                    onTap: () => onNavigate(_live),
                  ),
                  KpiCard(
                    title: 'Υπόλοιπο ενοικίου',
                    value: formatEuro(rentRemaining),
                    icon: Icons.home_work_outlined,
                    color: rentRemaining > 0
                        ? TbnColors.warning
                        : TbnColors.success,
                    onTap: () => onNavigate(_menu),
                  ),
                  KpiCard(
                    title: 'Οφειλές ενοικίου (έτος)',
                    value: formatEuro(rentDebt),
                    icon: Icons.payments_outlined,
                    color: rentDebt > 0
                        ? TbnColors.danger
                        : TbnColors.success,
                    onTap: () => onNavigate(_menu),
                  ),
                  KpiCard(
                    title: 'Παραγγελίες σε εκκρεμότητα',
                    value: '$pendingOrders',
                    icon: Icons.local_shipping_outlined,
                    color: pendingOrders > 0
                        ? TbnColors.warning
                        : TbnColors.success,
                    onTap: () => onNavigate(_merch),
                  ),
                  KpiCard(
                    title: 'Ειδοποιήσεις',
                    value: unread > 0
                        ? '$unread νέες'
                        : '${AppStore.notifications.length}',
                    icon: Icons.notifications_none_rounded,
                    color: unread > 0
                        ? TbnColors.accent
                        : TbnColors.info,
                    onTap: () => onNavigate(_menu),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.live,
    required this.rehearsal,
    required this.today,
    required this.onLive,
    required this.onRehearsal,
  });

  final LiveItem? live;
  final CalendarItem? rehearsal;
  final DateTime today;
  final VoidCallback onLive;
  final VoidCallback onRehearsal;

  static String _countdown(DateTime date, DateTime today) {
    final days = DateTime(date.year, date.month, date.day)
        .difference(today)
        .inDays;
    if (days <= 0) {
      return 'Σήμερα';
    }
    if (days == 1) {
      return 'Αύριο';
    }
    return 'σε $days ημέρες';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = rehearsal;
    final l = live;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text('ΝΕΑ', style: t.labelSmall),
          ),
          _NewsRow(
            icon: Icons.mic_none_rounded,
            color: TbnColors.accent,
            title: l == null
                ? 'Κανένα προγραμματισμένο live'
                : '${l.venue} · ${l.city}',
            subtitle: l == null
                ? 'Δεν υπάρχει επιβεβαιωμένο live'
                : '${greekDateLong(l.date)} · '
                    '${_countdown(l.date, today)}',
            onTap: onLive,
          ),
          const Divider(indent: 64),
          _NewsRow(
            icon: Icons.music_note_rounded,
            color: TbnColors.info,
            title: r == null
                ? 'Καμία προγραμματισμένη πρόβα'
                : r.title,
            subtitle: r == null
                ? 'Δεν υπάρχει πρόβα στο ημερολόγιο'
                : '${greekDateLong(r.dateTime)} · '
                    '${r.dateTime.hour.toString().padLeft(2, '0')}:'
                    '${r.dateTime.minute.toString().padLeft(2, '0')}'
                    '${r.location.isEmpty ? '' : ' · ${r.location}'}',
            onTap: onRehearsal,
          ),
        ],
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            IconChip(icon: icon, color: color, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: t.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
