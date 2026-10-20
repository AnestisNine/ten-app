import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/money.dart';
import '../core/roles.dart';
import '../core/van_dialog.dart';
import '../core/vans.dart';
import '../core/widgets.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../l10n/app_localizations.dart';
import 'auth_screen.dart';
import 'two_factor_screen.dart';

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
          ValueListenableBuilder<AppSettings>(
            valueListenable: AppStore.settings,
            builder: (context, settings, _) {
              final balance = settings.cashboxBalanceCents;
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
                          color: balance >= 0 ? TbnColors.success : TbnColors.danger,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!AppStore.can('settings', 'write'))
                        Text(
                          'Η ενημέρωση του υπολοίπου γίνεται από admin ή manager.',
                          style: t.bodySmall,
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _edit(context, balance),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Ενημέρωση υπολοίπου'),
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

  void _edit(BuildContext context, int current) {
    final controller = TextEditingController(text: centsToInput(current));
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
                final value = parseCents(controller.text);
                if (value == null) {
                  return;
                }
                AppStore.updateSettings({'cashboxBalanceCents': value});

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

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    AppStore.loadAudit().whenComplete(() {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ιστορικό αλλαγών')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: AppStore.audit.isEmpty
                  ? const [
                      Card(child: ListTile(title: Text('Δεν υπάρχουν αλλαγές ακόμη'))),
                    ]
                  : AppStore.audit.map((a) {
                      return Card(
                        child: ListTile(
                          title: Text('${_actionLabel(a.action)} · ${a.entity}'),
                          subtitle: Text(
                            [
                              a.summary,
                              '${a.userName ?? 'σύστημα'} · ${greekDateLong(a.at)} '
                                  '${a.at.hour.toString().padLeft(2, '0')}:${a.at.minute.toString().padLeft(2, '0')}'
                            ].where((e) => e.isNotEmpty).join('\n'),
                            style: t.bodySmall,
                          ),
                        ),
                      );
                    }).toList(),
            ),
    );
  }

  String _actionLabel(AuditAction a) {
    switch (a) {
      case AuditAction.create:
        return 'Δημιουργία';
      case AuditAction.update:
        return 'Αλλαγή';
      case AuditAction.delete:
        return 'Διαγραφή';
      case AuditAction.read:
        return 'Προβολή';
      case AuditAction.login:
        return 'Σύνδεση';
      case AuditAction.export:
        return 'Εξαγωγή';
    }
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
    final l = AppLocalizations.of(context);
    final me = AppStore.me.value;
    final canEdit = AppStore.can('settings', 'write');
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: AppStore.settings,
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (me != null)
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(me.name),
                        subtitle: Text('${me.email}\n${me.roles.map(roleLabel).join(', ')}'),
                        isThreeLine: true,
                      ),
                      ListTile(
                        leading: Icon(
                          me.twoFactorEnabled ? Icons.verified_user_outlined : Icons.shield_outlined,
                          color: me.twoFactorEnabled ? TbnColors.success : null,
                        ),
                        title: Text(l.twoFactor),
                        subtitle: Text(me.twoFactorEnabled ? l.twoFactorOn : l.twoFactorOff),
                        trailing: me.twoFactorEnabled ? null : const Icon(Icons.chevron_right_rounded),
                        onTap: me.twoFactorEnabled
                            ? null
                            : () => Navigator.of(context).push(
                                  TbnPageRoute<void>(builder: (_) => const TwoFactorSetupScreen(required: false)),
                                ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.translate_rounded),
                        title: Text(l.language),
                        trailing: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 'el', label: Text('EL')),
                            ButtonSegment(value: 'en', label: Text('EN')),
                          ],
                          selected: {AppStore.locale.value.languageCode},
                          onSelectionChanged: (v) async {
                            await AppStore.setLocale(v.first);
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: TbnColors.danger),
                        title: Text(l.signOut, style: const TextStyle(color: TbnColors.danger)),
                        onTap: () => signOutAndReturnToLogin(context),
                      ),
                    ],
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.appearance, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<AppThemeOption>(
                        valueListenable: AppStore.themeOption,
                        builder: (context, themeOption, _) => SegmentedButton<AppThemeOption>(
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
                          onSelectionChanged: (selection) => AppStore.setTheme(selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (AppStore.can('finance', 'read'))
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.graphic_eq_outlined),
                    title: const Text('Streaming platforms'),
                    subtitle: Text('Συνολικά έσοδα: ${formatCents(AppStore.streamingIncomeTotalCents)}'),
                    trailing: AppStore.can('finance', 'write') ? const Icon(Icons.add_rounded) : null,
                    onTap: AppStore.can('finance', 'write') ? _addStreamingIncome : null,
                  ),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: const Text('Μηνιαίο ενοίκιο'),
                  subtitle: Text(formatCents(settings.monthlyRentCents)),
                  trailing: canEdit ? const Icon(Icons.edit_outlined) : null,
                  onTap: canEdit
                      ? () => _editAmount('Μηνιαίο ενοίκιο', settings.monthlyRentCents, 'monthlyRentCents')
                      : null,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_gas_station_outlined),
                  title: const Text('Προεπιλογή βαν & diesel'),
                  subtitle: Text(
                    '${Vans.byId(settings.vanId)?.name ?? 'Άλλο βαν'}\n'
                    'Diesel ${formatCents(settings.dieselPriceCents)}/L · '
                    '${settings.fuelConsumption.toStringAsFixed(1)} L/100km',
                  ),
                  trailing: canEdit ? const Icon(Icons.edit_outlined) : null,
                  onTap: canEdit ? _editFuel : null,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Όριο χαμηλού stock'),
                  subtitle: Text('${settings.lowStockThreshold} τεμ.'),
                  trailing: canEdit ? const Icon(Icons.edit_outlined) : null,
                  onTap: canEdit ? () => _editThreshold(settings.lowStockThreshold) : null,
                ),
              ),
              const Card(
                child: ListTile(
                  title: Text('Shipping methods'),
                  subtitle: Text('Box Now, ΕΛΤΑ, ACS, Γενική Ταχυδρομική'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('Server'),
                  subtitle: Text(AppStore.api.baseUrl),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editAmount(String title, int current, String field) {
    final controller = TextEditingController(text: centsToInput(current));
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Ποσό', suffixText: '€'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Ακύρωση')),
          FilledButton(
            onPressed: () {
              final value = parseCents(controller.text);
              if (value == null || value < 0) return;
              AppStore.updateSettings({field: value});
              Navigator.pop(dialogContext);
            },
            child: const Text('Αποθήκευση'),
          ),
        ],
      ),
    );
  }

  void _editThreshold(int current) {
    final controller = TextEditingController(text: '$current');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Όριο χαμηλού stock'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Τεμάχια'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Ακύρωση')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 0) return;
              AppStore.updateSettings({'lowStockThreshold': value});
              Navigator.pop(dialogContext);
            },
            child: const Text('Αποθήκευση'),
          ),
        ],
      ),
    );
  }

  void _addStreamingIncome() {
    final platform = TextEditingController(text: 'Spotify');
    final amount = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Νέο έσοδο streaming'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: platform, decoration: const InputDecoration(labelText: 'Πλατφόρμα')),
            const SizedBox(height: 10),
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Ποσό', suffixText: '€'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Ακύρωση')),
          FilledButton(
            onPressed: () {
              final value = parseCents(amount.text);
              if (value == null || platform.text.trim().isEmpty) return;
              AppStore.create(StreamingIncome(
                id: newId(),
                platform: platform.text.trim(),
                amountCents: value,
                date: DateTime.now(),
              ));
              Navigator.pop(dialogContext);
            },
            child: const Text('Αποθήκευση'),
          ),
        ],
      ),
    );
  }

  Future<void> _editFuel() async {
    final s = AppStore.settings.value;
    final r = await showVanDialog(
      context,
      title: 'Προεπιλογή βαν & diesel',
      vanId: s.vanId,
      consumption: s.fuelConsumption,
      price: s.dieselPriceCents / 100,
    );
    if (r == null || r.price == null) return;
    await AppStore.updateSettings({
      'dieselPriceCents': (r.price! * 100).round(),
      'fuelConsumption': r.consumption,
      'vanId': r.vanId,
    });
  }
}
