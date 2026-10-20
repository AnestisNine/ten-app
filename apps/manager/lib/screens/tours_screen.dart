import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/route_widgets.dart';
import '../core/van_dialog.dart';
import '../core/vans.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';
import 'live_detail_screen.dart';

class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key});

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          PageHeader(
            title: 'Tours',
            subtitle: '${AppStore.tours.length} tours',
            actions: [
              FilledButton.icon(
                onPressed: _addTour,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Νέο'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                ),
              ),
            ],
          ),
          if (AppStore.tours.isEmpty)
            const EmptyState(
              icon: Icons.airport_shuttle_outlined,
              title: 'Κανένα tour ακόμα',
              subtitle: 'Φτιάξε το πρώτο με το κουμπί «Νέο»',
            ),
          ...AppStore.tours.map((tour) {
            final tourLives = AppStore.lives.where((live) => live.tourId == tour.id).toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            final income = tourLives.fold<int>(
              0,
              (sum, live) => sum + live.totalIncomeCents,
            );
            final expenses = tourLives.fold<int>(
              0,
              (sum, live) => sum + live.totalExpensesCents,
            );
            final net = income - expenses;
            final netColor = net >= 0 ? TbnColors.success : TbnColors.danger;

            return Card(
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  leading: const IconChip(
                    icon: Icons.airport_shuttle_outlined,
                    size: 40,
                  ),
                  title: Text(tour.name, style: t.titleSmall),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${_date(tour.startDate)} – ${_date(tour.endDate)}'
                      ' · ${tourLives.length} live',
                      style: t.bodySmall,
                    ),
                  ),
                  trailing: StatusPill(
                    label: '${net >= 0 ? '+' : ''}${formatEuro(net)}',
                    color: netColor,
                  ),
                  children: [
                    _vanTile(tour),
                    RouteTotals(
                      lives: tourLives,
                      consumption: tour.consumption,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            label: 'Έσοδα',
                            value: formatEuro(income),
                            color: TbnColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Stat(
                            label: 'Έξοδα',
                            value: formatEuro(expenses),
                            color: TbnColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (tourLives.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Δεν υπάρχουν live σε αυτό το tour.',
                          style: t.bodySmall,
                        ),
                      ),
                    ...tourLives.asMap().entries.map((entry) {
                      final index = entry.key;
                      final live = entry.value;
                      final next = index + 1 < tourLives.length ? tourLives[index + 1] : null;

                      return Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.of(context)
                                .push(
                              TbnPageRoute<void>(
                                builder: (_) => LiveDetailScreen(live: live),
                              ),
                            )
                                .then((_) {
                              if (mounted) setState(() {});
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  DateBadge(
                                    date: live.date,
                                    color: liveStatusColor(live.status),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          live.venue,
                                          style: t.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(live.city, style: t.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '+${formatEuro(live.totalIncomeCents)}',
                                        style: const TextStyle(
                                          color: TbnColors.success,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '−${formatEuro(live.totalExpensesCents)}',
                                        style: const TextStyle(
                                          color: TbnColors.danger,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (next != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                top: 4,
                                bottom: 4,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Icon(
                                      Icons.south_rounded,
                                      size: 16,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RouteLegRow(
                                      from: live,
                                      to: next,
                                      consumption: tour.consumption,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox(height: 4),
                        ],
                      );
                    }),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => _addLiveToTour(tour),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Προσθήκη Live στο Tour'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _date(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }

  Widget _vanTile(TourItem tour) {
    final cs = Theme.of(context).colorScheme;
    final id = tour.vanId ?? AppStore.settings.value.vanId;
    final name = Vans.byId(id)?.name ?? 'Άλλο βαν';
    final cons = tour.consumption ?? AppStore.fuelConsumption.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Tooltip(
        message: 'Το βαν αυτού του tour. Ορίζει την κατανάλωση και το '
            'κόστος καυσίμου των διαδρομών του.',
        triggerMode: TooltipTriggerMode.longPress,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickTourVan(tour),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.airport_shuttle_outlined,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$name · ${cons.toStringAsFixed(1)} L/100km',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.edit_outlined, size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTourVan(TourItem tour) async {
    final r = await showVanDialog(
      context,
      title: 'Βαν · ${tour.name}',
      vanId: tour.vanId ?? AppStore.settings.value.vanId,
      consumption: tour.consumption ?? AppStore.fuelConsumption.value,
    );
    if (r == null) return;
    setState(() {
      tour.vanId = r.vanId;
      tour.consumption = r.consumption;
    });
    AppStore.update(tour);
  }

  void _addTour() {
    final name = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Νέο Tour',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Όνομα Tour',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ημερομηνία έναρξης'),
                    trailing: Text(_date(startDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: startDate,
                      );

                      if (picked != null) {
                        modalSetState(() {
                          startDate = picked;
                          if (endDate.isBefore(startDate)) {
                            endDate = startDate;
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ημερομηνία λήξης'),
                    trailing: Text(_date(endDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: startDate,
                        lastDate: DateTime(2035),
                        initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                      );

                      if (picked != null) {
                        modalSetState(() {
                          endDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () {
                      if (name.text.trim().isEmpty) {
                        return;
                      }

                      final tour = TourItem(
                        id: newId(),
                        name: name.text.trim(),
                        startDate: startDate,
                        endDate: endDate,
                        vanId: AppStore.settings.value.vanId,
                        consumption: AppStore.fuelConsumption.value,
                      );

                      AppStore.create(tour);
                      setState(() {});

                      Navigator.pop(context);
                    },
                    child: const Text('Δημιουργία Tour'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Opens the full live page for a new live in this tour; saved only when the user presses Save.
  Future<void> _addLiveToTour(TourItem tour) async {
    await Navigator.of(context).push(
      TbnPageRoute<void>(
        builder: (_) => LiveDetailScreen(
          live: LiveItem(
            id: newId(),
            venue: '',
            country: 'Greece',
            countryCode: 'GR',
            date: tour.startDate,
            status: LiveStatus.proposal,
            tourId: tour.id,
          ),
          isNew: true,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
            value,
            style: t.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
