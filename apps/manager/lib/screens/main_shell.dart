import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../data/app_store.dart';
import '../l10n/app_localizations.dart';
import 'auth_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'live_manager_screen.dart';
import 'menu_screen.dart';
import 'merch_screen.dart';
import 'tours_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  List<_NavItem> _items(AppLocalizations l) => <_NavItem>[
        _NavItem(Icons.home_outlined, Icons.home_rounded, l.navHome),
        _NavItem(Icons.mic_none_rounded, Icons.mic_rounded, l.navLive),
        _NavItem(Icons.airport_shuttle_outlined, Icons.airport_shuttle, l.navTours),
        _NavItem(Icons.inventory_2_outlined, Icons.inventory_2, l.navMerch),
        _NavItem(Icons.calendar_month_outlined, Icons.calendar_month, l.navCalendar),
        _NavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, l.navMenu),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items(AppLocalizations.of(context));
    final pages = <Widget>[
      DashboardScreen(
        onNavigate: (target) => setState(() => index = target),
      ),
      LiveManagerScreen(),
      ToursScreen(),
      MerchScreen(),
      CalendarScreen(),
      MenuScreen(),
    ];

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ValueListenableBuilder<int>(
          valueListenable: AppStore.dataVersion,
          builder: (context, _, __) => IndexedStack(index: index, children: pages),
        ),
      ),
    );

    final wide = MediaQuery.sizeOf(context).width >= 900;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: true,
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              leading: const Padding(
                padding: EdgeInsets.fromLTRB(8, 24, 8, 20),
                child: _Brand(),
              ),
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerTheme.color!),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TbnLogoMark(size: 78),
        const SizedBox(height: 6),
        Text(
          appVersionLabel,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
