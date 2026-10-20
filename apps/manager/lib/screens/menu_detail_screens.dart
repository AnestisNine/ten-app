import 'package:flutter/material.dart';

import '../core/van_dialog.dart';
import '../core/vans.dart';
import '../core/widgets.dart';
import '../core/theme.dart';
import '../data/app_store.dart';

class CashboxScreen extends StatelessWidget {
  const CashboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cashbox')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ValueListenableBuilder<double>(
            valueListenable: AppStore.cashboxBalance,
            builder: (context, balance, _) {
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ΔΙΑΘΕΣΙΜΟ ΤΑΜΕΙΟ', style: t.labelSmall),
                      const SizedBox(height: 8),
                      Text(
                        formatEuro(balance),
                        style: t.headlineLarge?.copyWith(
                          color: balance >= 0
                              ? TbnColors.success
                              : TbnColors.danger,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<bool>(
                        valueListenable: AppStore.isAdmin,
                        builder: (context, admin, _) {
                          if (!admin) {
                            return Text(
                              'Η ενημέρωση του υπολοίπου γίνεται μόνο '
                              'από admin.',
                              style: t.bodySmall,
                            );
                          }
                          return OutlinedButton.icon(
                            onPressed: () => _edit(context, balance),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Ενημέρωση υπολοίπου'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, double current) {
    final controller =
        TextEditingController(text: current.toStringAsFixed(2));
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Υπόλοιπο ταμείου'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(labelText: 'Ποσό (€)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Ακύρωση'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );
                if (value == null) {
                  return;
                }
                AppStore.cashboxBalance.value = value;
                AppStore.log(
                  'Cashbox',
                  'Υπόλοιπο ταμείου: ${value.toStringAsFixed(2)} €',
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Αποθήκευση'),
            ),
          ],
        );
      },
    );
  }
}

class DriveScreen extends StatelessWidget {
  const DriveScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drive')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Card(
          child: ListTile(
            leading: Icon(Icons.cloud_outlined),
            title: Text('Google Drive'),
            subtitle: Text('Το πραγματικό shared link θα συνδεθεί από τα Settings.'),
          ),
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final items = AppStore.notifications.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: items.isEmpty
            ? const [
                EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Δεν υπάρχουν ειδοποιήσεις',
                ),
              ]
            : items.map((n) {
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: const IconChip(
                      icon: Icons.notifications_none_rounded,
                    ),
                    title: Text(n.title),
                    subtitle: Text(n.body),
                  ),
                );
              }).toList(),
      ),
    );
  }
}

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ιστορικό αλλαγών')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: AppStore.audit.isEmpty
            ? const [
                Card(
                  child: ListTile(
                    title: Text('Δεν υπάρχουν αλλαγές ακόμη'),
                  ),
                ),
              ]
            : AppStore.audit.reversed.map((a) {
                return Card(
                  child: ListTile(
                    title: Text(a.action),
                    subtitle: Text(a.area),
                  ),
                );
              }).toList(),
      ),
    );
  }
}


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ValueListenableBuilder<AppThemeOption>(
        valueListenable: AppStore.themeOption,
        builder: (context, themeOption, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appearance',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<AppThemeOption>(
                        segments: const [
                          ButtonSegment(
                            value: AppThemeOption.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                          ButtonSegment(
                            value: AppThemeOption.cream,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Cream'),
                          ),
                        ],
                        selected: <AppThemeOption>{themeOption},
                        onSelectionChanged: (selection) {
                          AppStore.themeOption.value =
                              selection.first;
                          AppStore.log(
                            'Settings',
                            'Theme → ${selection.first.name}',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ValueListenableBuilder<bool>(
                  valueListenable: AppStore.isAdmin,
                  builder: (context, admin, _) {
                    return SwitchListTile(
                      secondary: const Icon(
                        Icons.admin_panel_settings_outlined,
                      ),
                      title: const Text('Admin'),
                      subtitle: const Text(
                        'Δικαίωμα διαγραφής live και ενημέρωσης ταμείου. '
                        'Προσωρινή ρύθμιση στη συσκευή· θα συνδεθεί με '
                        'το login όταν μπει το backend.',
                      ),
                      value: admin,
                      onChanged: (value) {
                        AppStore.isAdmin.value = value;
                        AppStore.log(
                          'Settings',
                          'Ρόλος → ${value ? 'Admin' : 'Μέλος'}',
                        );
                      },
                    );
                  },
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.save_outlined),
                  title: Text('Τοπική αποθήκευση'),
                  subtitle: Text(
                    'Ενεργή · τα δεδομένα διατηρούνται μετά το κλείσιμο της εφαρμογής',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.graphic_eq_outlined),
                  title: const Text('Streaming platforms'),
                  subtitle: Text(
                    'Συνολικά έσοδα: '
                    '${AppStore.streamingIncomeTotal.value.toStringAsFixed(2)} €',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _editStreamingIncome,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: const Text('Μηνιαίο ενοίκιο'),
                  subtitle: Text(
                    '${AppStore.monthlyRentCost.value.toStringAsFixed(2)} €',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _editMonthlyRent,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_gas_station_outlined),
                  title: const Text('Προεπιλογή βαν & diesel'),
                  subtitle: Text(
                    '${Vans.byId(AppStore.vanId.value)?.name ?? 'Άλλο βαν'}\n'
                    'Diesel ${AppStore.dieselPrice.value.toStringAsFixed(2)} €/L · '
                    '${AppStore.fuelConsumption.value.toStringAsFixed(1)} L/100km',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _editFuel,
                ),
              ),
              const Card(
                child: ListTile(
                  title: Text('Low stock threshold'),
                  subtitle: Text('10'),
                ),
              ),
              const Card(
                child: ListTile(
                  title: Text('Shipping methods'),
                  subtitle: Text(
                    'Box Now, ΕΛΤΑ, ACS, Γενική Ταχυδρομική',
                  ),
                ),
              ),
              const Card(
                child: ListTile(
                  title: Text('Drive link'),
                  subtitle: Text('Not configured'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  void _editStreamingIncome() {
    final controller = TextEditingController(
      text: AppStore.streamingIncomeTotal.value.toStringAsFixed(2),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Streaming platforms'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Συνολικό ποσό εσόδων',
              suffixText: '€',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Ακύρωση'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );

                if (value == null || value < 0) {
                  return;
                }

                setState(() {
                  AppStore.streamingIncomeTotal.value = value;
                });

                AppStore.log(
                  'Settings',
                  'Streaming income → '
                  '${value.toStringAsFixed(2)} €',
                );

                Navigator.pop(dialogContext);
              },
              child: const Text('Αποθήκευση'),
            ),
          ],
        );
      },
    );
  }

void _editMonthlyRent() {
  final controller = TextEditingController(
    text: AppStore.monthlyRentCost.value.toStringAsFixed(2),
  );

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Μηνιαίο ενοίκιο'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Ποσό',
            suffixText: '€',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Ακύρωση'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (value == null || value <= 0) {
                return;
              }

              setState(() {
                AppStore.monthlyRentCost.value = value;
              });
              AppStore.log(
                'Settings',
                'Μηνιαίο ενοίκιο → '
                '${value.toStringAsFixed(2)} €',
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Αποθήκευση'),
          ),
        ],
      );
    },
  );
}

  Future<void> _editFuel() async {
    final r = await showVanDialog(
      context,
      title: 'Προεπιλογή βαν & diesel',
      vanId: AppStore.vanId.value,
      consumption: AppStore.fuelConsumption.value,
      price: AppStore.dieselPrice.value,
    );
    if (r == null || r.price == null) return;
    setState(() {
      AppStore.dieselPrice.value = r.price!;
      AppStore.fuelConsumption.value = r.consumption;
      AppStore.vanId.value = r.vanId;
    });
    AppStore.log(
      'Settings',
      'Προεπιλογή βαν → ${Vans.byId(r.vanId)?.name ?? 'Άλλο'}, '
      '${r.price!.toStringAsFixed(2)} €/L, '
      '${r.consumption.toStringAsFixed(1)} L/100km',
    );
  }
}
