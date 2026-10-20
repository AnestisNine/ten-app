import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';
import '../l10n/app_localizations.dart';
import 'finance_screen.dart';
import 'members_screen.dart';
import 'menu_detail_screens.dart';
import 'rent_screen.dart';
import 'users_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = AppStore.notifications.where((n) => !n.read).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const PageHeader(
            title: 'Menu',
            subtitle: 'Οικονομικά, μέλη και ρυθμίσεις',
          ),
          if (AppStore.can('finance', 'read')) ...[
            const SectionLabel('Οικονομικά'),
            _group(context, [
              _Entry(Icons.account_balance_wallet_outlined, 'Οικονομικά', 'Έσοδα, έξοδα, χρέη, ταμείο',
                  const FinanceScreen(), TbnColors.success),
              _Entry(Icons.home_work_outlined, 'Ενοίκιο', 'Πληρωμές και οφειλές ανά μήνα', const RentScreen(),
                  TbnColors.warning),
              _Entry(Icons.savings_outlined, 'Cashbox', 'Υπόλοιπο και κινήσεις', const CashboxScreen(), TbnColors.info),
            ]),
          ],
          const SectionLabel('Μέλη & αρχεία'),
          _group(context, [
            if (AppStore.can('members', 'read'))
              _Entry(Icons.people_outline, 'Μέλη', 'Στοιχεία μελών', const MembersScreen(), TbnColors.accent),
            _Entry(Icons.cloud_outlined, 'Drive', 'Shared Google Drive', const DriveScreen(), TbnColors.info),
          ]),
          const SectionLabel('Σύστημα'),
          _group(context, [
            _Entry(
              Icons.notifications_none_rounded,
              'Notifications',
              'Ειδοποιήσεις εφαρμογής',
              const NotificationsScreen(),
              TbnColors.accent,
              badge: unread > 0 ? '$unread' : null,
            ),
            if (AppStore.can('users', 'read'))
              _Entry(Icons.manage_accounts_outlined, AppLocalizations.of(context).users,
                  AppLocalizations.of(context).usersSubtitle, const UsersScreen(), TbnColors.accent),
            if (AppStore.can('audit', 'read'))
              _Entry(Icons.history, 'Ιστορικό αλλαγών', 'Audit log', const AuditScreen(), TbnColors.info),
            _Entry(Icons.settings_outlined, 'Settings', 'Ρυθμίσεις εφαρμογής', const SettingsScreen(),
                const Color(0xFF8A93A3)),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Center(
              child: Text(
                'TBN Manager $appVersionLabel',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, List<_Entry> entries) {
    final tiles = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      tiles.add(
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: IconChip(icon: e.icon, color: e.color, size: 38),
          title: Text(e.title),
          subtitle: Text(e.subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (e.badge != null) ...[
                StatusPill(label: e.badge!, color: TbnColors.accent),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              TbnPageRoute<void>(builder: (_) => e.page),
            );
          },
        ),
      );
      if (i < entries.length - 1) {
        tiles.add(const Divider(indent: 66));
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(children: tiles),
    );
  }
}

class _Entry {
  const _Entry(
    this.icon,
    this.title,
    this.subtitle,
    this.page,
    this.color, {
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;
  final Color color;
  final String? badge;
}
