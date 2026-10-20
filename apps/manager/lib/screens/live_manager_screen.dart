import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/place_widgets.dart';
import '../core/places.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';
import 'live_detail_screen.dart';

class LiveManagerScreen extends StatefulWidget {
  const LiveManagerScreen({super.key});
  @override
  State<LiveManagerScreen> createState() => _LiveManagerScreenState();
}

class _LiveManagerScreenState extends State<LiveManagerScreen> {
  LiveStatus? filter;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final items = AppStore.lives
        .where((l) => filter == null || l.status == filter)
        .where((l) =>
            q.isEmpty ||
            l.venue.toLowerCase().contains(q) ||
            l.city.toLowerCase().contains(q) ||
            l.country.toLowerCase().contains(q))
        .toList();
    // Πρώτα τα επερχόμενα (το πιο κοντινό πρώτο), μετά τα περασμένα
    // (το πιο πρόσφατο πρώτο).
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final upcoming = items.where((l) => !l.date.isBefore(startOfToday)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = items.where((l) => l.date.isBefore(startOfToday)).toList()..sort((a, b) => b.date.compareTo(a.date));
    items
      ..clear()
      ..addAll(upcoming)
      ..addAll(past);

    final title = filter == null ? 'Όλα τα live' : liveStatusSectionTitle(filter!);

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            '$title · ${items.length}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.mic_none_rounded,
            title: 'Δεν βρέθηκαν live',
            subtitle: 'Άλλαξε το φίλτρο ή πρόσθεσε νέο live',
          ),
        ...items.map(_liveCard),
      ],
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          PageHeader(
            title: 'Live & Booking',
            subtitle: '${AppStore.lives.length} συνολικά',
            actions: [
              FilledButton.icon(
                onPressed: _addLive,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Νέο'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                ),
              ),
            ],
          ),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Αναζήτηση venue ή πόλης',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 640) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 196, child: _statusSidebar()),
                    const SizedBox(width: 18),
                    Expanded(child: list),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusChips(),
                  const SizedBox(height: 14),
                  list,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  int _count(LiveStatus? status) =>
      status == null ? AppStore.lives.length : AppStore.lives.where((l) => l.status == status).length;

  Widget _statusSidebar() {
    final entries = <MapEntry<LiveStatus?, String>>[
      const MapEntry(null, 'Όλα'),
      for (final s in LiveStatus.values) MapEntry(s, liveStatusGroupLabel(s)),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            for (final e in entries)
              _SidebarItem(
                label: e.value,
                count: _count(e.key),
                color: e.key == null ? TbnColors.accent : liveStatusColor(e.key!),
                selected: filter == e.key,
                onTap: () => setState(() => filter = e.key),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text('Όλα · ${_count(null)}'),
            selected: filter == null,
            onSelected: (_) => setState(() => filter = null),
          ),
          ...LiveStatus.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text('${liveStatusGroupLabel(s)} · ${_count(s)}'),
                selected: filter == s,
                onSelected: (_) => setState(() => filter = s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveCard(LiveItem live) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .push(
            TbnPageRoute<void>(
              builder: (_) => LiveDetailScreen(live: live),
            ),
          )
              .then((_) {
            if (mounted) {
              setState(() {});
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DateBadge(
                date: live.date,
                color: liveStatusColor(live.status),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
                    Text(
                      '${live.city}, ${live.country} · ${live.date.year}',
                      style: t.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    StatusPill(
                      label: liveStatusLabel(live.status),
                      color: liveStatusColor(live.status),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addLive() {
    final venue = TextEditingController();
    final place = PlaceValue(
      countryCode: 'GR',
      countryName: 'Greece',
    );
    DateTime date = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: venue,
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              const SizedBox(height: 10),
              PlaceFields(
                value: place,
                onChanged: () => modalSetState(() {}),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ημερομηνία'),
                trailing: Text('${date.day}/${date.month}/${date.year}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    initialDate: date,
                  );
                  if (picked != null) {
                    modalSetState(() => date = picked);
                  }
                },
              ),
              FilledButton(
                onPressed: () {
                  if (venue.text.trim().isEmpty || !place.hasCity) {
                    return;
                  }
                  AppStore.create(
                    LiveItem(
                      id: newId(),
                      venue: venue.text.trim(),
                      city: place.city.trim(),
                      country: place.countryName,
                      countryCode: place.countryCode,
                      lat: place.lat,
                      lon: place.lon,
                      date: date,
                      status: LiveStatus.proposal,
                    ),
                  );

                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Αποθήκευση'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: selected ? TbnColors.accent.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: selected ? t.titleSmall : t.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('$count', style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
