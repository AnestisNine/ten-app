import 'package:flutter/material.dart';

import 'money.dart';

import '../data/app_store.dart';
import 'models.dart';
import 'roles.dart';
import 'theme.dart';

/// Page route that keeps pushed pages readable on wide screens
/// (centered column, max 820px) and behaves normally on phones.
class TbnPageRoute<T> extends MaterialPageRoute<T> {
  TbnPageRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
  });

  @override
  Widget buildContent(BuildContext context) {
    return _CenteredColumn(child: super.buildContent(context));
  }
}

class _CenteredColumn extends StatelessWidget {
  const _CenteredColumn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: child,
        ),
      ),
    );
  }
}

const _weekdays = <String>[
  'Δευτέρα',
  'Τρίτη',
  'Τετάρτη',
  'Πέμπτη',
  'Παρασκευή',
  'Σάββατο',
  'Κυριακή',
];

const _monthsGenitive = <String>[
  'Ιανουαρίου',
  'Φεβρουαρίου',
  'Μαρτίου',
  'Απριλίου',
  'Μαΐου',
  'Ιουνίου',
  'Ιουλίου',
  'Αυγούστου',
  'Σεπτεμβρίου',
  'Οκτωβρίου',
  'Νοεμβρίου',
  'Δεκεμβρίου',
];

const _monthsShort = <String>[
  'ΙΑΝ',
  'ΦΕΒ',
  'ΜΑΡ',
  'ΑΠΡ',
  'ΜΑΪ',
  'ΙΟΥΝ',
  'ΙΟΥΛ',
  'ΑΥΓ',
  'ΣΕΠ',
  'ΟΚΤ',
  'ΝΟΕ',
  'ΔΕΚ',
];

String greekDateLong(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_monthsGenitive[d.month - 1]}';

/// Compact amount from cents: "20 €", "20,50 €", "1.250 €".
String formatEuro(int cents) {
  final full = formatCents(cents);
  return cents % 100 == 0 ? full.replaceFirst(',00', '') : full;
}

/// Σύντομη ονομασία ομάδας (λίστα φίλτρων).
String liveStatusGroupLabel(LiveStatus s) {
  switch (s) {
    case LiveStatus.proposal:
      return 'Προτάσεις';
    case LiveStatus.negotiation:
      return 'Σε διαπραγμάτευση';
    case LiveStatus.confirmed:
      return 'Επιβεβαιωμένα';
    case LiveStatus.completed:
      return 'Ολοκληρωμένα';
    case LiveStatus.cancelled:
      return 'Ακυρωμένα';
  }
}

/// Τίτλος ενότητας που εμφανίζεται στην κορυφή της σελίδας live.
String liveStatusSectionTitle(LiveStatus s) {
  switch (s) {
    case LiveStatus.proposal:
      return 'Προτάσεις live';
    case LiveStatus.negotiation:
      return 'Live σε διαπραγμάτευση';
    case LiveStatus.confirmed:
      return 'Επιβεβαιωμένα live';
    case LiveStatus.completed:
      return 'Ολοκληρωμένα live';
    case LiveStatus.cancelled:
      return 'Ακυρωμένα live';
  }
}

Color liveStatusColor(LiveStatus s) {
  switch (s) {
    case LiveStatus.proposal:
      return TbnColors.info;
    case LiveStatus.negotiation:
      return TbnColors.warning;
    case LiveStatus.confirmed:
      return TbnColors.success;
    case LiveStatus.completed:
      return const Color(0xFF8A93A3);
    case LiveStatus.cancelled:
      return TbnColors.danger;
  }
}

Color orderStatusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.waitingContact:
      return TbnColors.warning;
    case OrderStatus.waitingRestock:
      return TbnColors.info;
    case OrderStatus.sent:
      return TbnColors.accent;
    case OrderStatus.completed:
      return TbnColors.success;
    case OrderStatus.cancelled:
      return TbnColors.danger;
  }
}

/// Page title with optional subtitle and trailing actions.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: t.bodySmall),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8, left: 2),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.9,
            ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    this.color = TbnColors.accent,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date, this.color});

  final DateTime date;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? TbnColors.accent;
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _monthsShort[date.month - 1],
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: c,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    this.color = TbnColors.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconChip(icon: icon, color: color, size: 34),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, style: t.titleSmall, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: t.bodySmall, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Shown on pages the user may view but not change (their role is read-only there).
class ReadOnlyBanner extends StatelessWidget {
  const ReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = (AppStore.me.value?.roles ?? const <String>[]).map(roleLabel).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TbnColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TbnColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: TbnColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Μόνο προβολή: ο ρόλος σου${roles.isEmpty ? '' : ' ($roles)'} δεν επιτρέπει αλλαγές εδώ.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
