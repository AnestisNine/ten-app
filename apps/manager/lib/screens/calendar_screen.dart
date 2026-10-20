import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/app_store.dart';
import 'calendar_feed_sheet.dart';
import 'live_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int mode = 2;
  DateTime focused = DateTime.now();
  DateTime selected = DateTime.now();

  static const _weekdayLabels = <String>[
    'Δε',
    'Τρ',
    'Τε',
    'Πε',
    'Πα',
    'Σα',
    'Κυ',
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final selectedEvents = AppStore.calendarWithLives().where((e) {
      return _sameDay(e.startsAt, selected);
    }).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          PageHeader(
            title: 'Ημερολόγιο',
            subtitle: '${AppStore.calendarWithLives().length} events',
            actions: [
              IconButton(
                tooltip: 'Συγχρονισμός με το ημερολόγιό μου',
                onPressed: () => showCalendarFeedSheet(context),
                icon: const Icon(Icons.sync_rounded),
              ),
              if (AppStore.can('calendar', 'write'))
                FilledButton.icon(
                  onPressed: _addRehearsal,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Νέο'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('Ημέρα')),
                ButtonSegment(value: 1, label: Text('Εβδομάδα')),
                ButtonSegment(value: 2, label: Text('Μήνας')),
              ],
              selected: <int>{mode},
              onSelectionChanged: (s) => setState(() => mode = s.first),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _previous,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _header(),
                          textAlign: TextAlign.center,
                          style: t.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _next,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  if (mode != 0) _weekdayRow(),
                  if (mode == 2) _monthView(),
                  if (mode == 1) _weekView(),
                  if (mode == 0) _dayView(),
                ],
              ),
            ),
          ),
          SectionLabel(greekDateLong(selected)),
          if (selectedEvents.isEmpty)
            const Card(
              margin: EdgeInsets.zero,
              child: EmptyState(
                icon: Icons.event_available_outlined,
                title: 'Καμία εκδήλωση αυτή τη μέρα',
              ),
            ),
          ...selectedEvents.map((event) {
            final time = '${event.startsAt.hour.toString().padLeft(2, '0')}:'
                '${event.startsAt.minute.toString().padLeft(2, '0')}';
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openEvent(event),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      IconChip(
                        icon: event.type == 'Live' ? Icons.mic_external_on_rounded : Icons.music_note_rounded,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: t.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              event.location.isEmpty ? 'Χωρίς τοποθεσία' : event.location,
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusPill(
                        label: event.type == 'Live' ? 'Live' : time,
                        color: TbnColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openEvent(CalendarItem event) {
    if (event.id.startsWith('live:')) {
      final id = event.id.substring(5);
      final matches = AppStore.lives.where((l) => l.id == id);
      if (matches.isEmpty) return;
      Navigator.of(context)
          .push(
        TbnPageRoute<void>(
          builder: (_) => LiveDetailScreen(live: matches.first),
        ),
      )
          .then((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    if (!AppStore.can('calendar', 'write')) return;
    _editEvent(event);
  }

  Widget _weekdayRow() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          for (final label in _weekdayLabels)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime date, {double margin = 3}) {
    final hasEvent = AppStore.calendarWithLives().any((e) {
      return _sameDay(e.startsAt, date);
    });
    final isSelected = _sameDay(selected, date);
    final isToday = _sameDay(DateTime.now(), date);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => setState(() {
        selected = date;
        focused = date;
      }),
      child: Container(
        margin: EdgeInsets.all(margin),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? TbnColors.accent : null,
          border: isToday && !isSelected ? Border.all(color: TbnColors.accent, width: 1.5) : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : onSurface,
              ),
            ),
            if (hasEvent)
              Positioned(
                bottom: 5,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : TbnColors.success,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _monthView() {
    final first = DateTime(focused.year, focused.month, 1);
    final days = DateTime(focused.year, focused.month + 1, 0).day;
    final leading = first.weekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leading + days,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemBuilder: (context, index) {
        if (index < leading) {
          return const SizedBox();
        }
        final day = index - leading + 1;
        return _dayCell(DateTime(focused.year, focused.month, day));
      },
    );
  }

  Widget _weekView() {
    final start = selected.subtract(Duration(days: selected.weekday - 1));

    return Row(
      children: List.generate(7, (i) {
        final date = start.add(Duration(days: i));
        return Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: _dayCell(date),
          ),
        );
      }),
    );
  }

  Widget _dayView() {
    final t = Theme.of(context).textTheme;
    final count = AppStore.calendarWithLives().where((e) {
      return _sameDay(e.startsAt, selected);
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text('${selected.day}', style: t.headlineLarge),
          const SizedBox(height: 4),
          Text(
            count == 0 ? 'Καμία εκδήλωση' : '$count εκδηλώσεις',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }

  void _addRehearsal() {
    final title = TextEditingController(text: 'Πρόβα');
    final location = TextEditingController(text: 'Studio');
    final notes = TextEditingController();
    var isPrivate = false;
    DateTime dateTime = DateTime.now().add(const Duration(days: 1));

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
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Νέα εκδήλωση',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Τίτλος'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ιδιωτικό'),
                    subtitle: const Text('Το βλέπεις μόνο εσύ (π.χ. για να δείξεις ότι δεν είσαι διαθέσιμος).'),
                    value: isPrivate,
                    onChanged: (v) => modalSetState(() => isPrivate = v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ημερομηνία'),
                    trailing: Text(
                      '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: dateTime,
                      );
                      if (picked != null) {
                        modalSetState(() {
                          dateTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            dateTime.hour,
                            dateTime.minute,
                          );
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ώρα'),
                    trailing: Text(
                      '${dateTime.hour.toString().padLeft(2, '0')}:'
                      '${dateTime.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(dateTime),
                      );
                      if (picked != null) {
                        modalSetState(() {
                          dateTime = DateTime(
                            dateTime.year,
                            dateTime.month,
                            dateTime.day,
                            picked.hour,
                            picked.minute,
                          );
                        });
                      }
                    },
                  ),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(
                      labelText: 'Τοποθεσία',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Σχόλια',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      final event = CalendarItem(
                        id: newId(),
                        startsAt: dateTime,
                        title: title.text.trim().isEmpty ? 'Πρόβα' : title.text.trim(),
                        type: isPrivate ? 'Personal' : 'Rehearsal',
                        location: location.text.trim(),
                        notes: notes.text.trim(),
                        visibility: isPrivate ? CalendarVisibility.private : CalendarVisibility.team,
                      );
                      AppStore.create(event);

                      setState(() {
                        selected = DateTime(
                          dateTime.year,
                          dateTime.month,
                          dateTime.day,
                        );
                        focused = selected;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Αποθήκευση'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editEvent(CalendarItem event) {
    final title = TextEditingController(text: event.title);
    final location = TextEditingController(text: event.location);
    final notes = TextEditingController(text: event.notes);
    DateTime dateTime = event.startsAt;

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
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Τίτλος',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ημερομηνία'),
                    trailing: Text(
                      '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: dateTime,
                      );
                      if (picked != null) {
                        modalSetState(() {
                          dateTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            dateTime.hour,
                            dateTime.minute,
                          );
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ώρα'),
                    trailing: Text(
                      '${dateTime.hour.toString().padLeft(2, '0')}:'
                      '${dateTime.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(dateTime),
                      );
                      if (picked != null) {
                        modalSetState(() {
                          dateTime = DateTime(
                            dateTime.year,
                            dateTime.month,
                            dateTime.day,
                            picked.hour,
                            picked.minute,
                          );
                        });
                      }
                    },
                  ),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(
                      labelText: 'Τοποθεσία',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notes,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Σχόλια',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        event.title = title.text.trim();
                        event.location = location.text.trim();
                        event.notes = notes.text.trim();
                        event.startsAt = dateTime;
                        selected = DateTime(
                          dateTime.year,
                          dateTime.month,
                          dateTime.day,
                        );
                        focused = selected;
                      });
                      AppStore.update(event);

                      Navigator.pop(context);
                    },
                    child: const Text('Αποθήκευση αλλαγών'),
                  ),
                  if (event.ownerId == AppStore.me.value?.id || AppStore.can('calendar', 'delete'))
                    TextButton(
                      onPressed: () {
                        AppStore.remove(event);
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: TbnColors.danger),
                      child: const Text('Διαγραφή'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _header() {
    if (mode == 0) {
      return '${selected.day}/${selected.month}/${selected.year}';
    }
    if (mode == 1) {
      return 'Week of ${selected.day}/${selected.month}/${selected.year}';
    }
    return '${focused.month}/${focused.year}';
  }

  void _previous() {
    setState(() {
      if (mode == 2) {
        focused = DateTime(focused.year, focused.month - 1, 1);
      } else if (mode == 1) {
        selected = selected.subtract(const Duration(days: 7));
        focused = selected;
      } else {
        selected = selected.subtract(const Duration(days: 1));
        focused = selected;
      }
    });
  }

  void _next() {
    setState(() {
      if (mode == 2) {
        focused = DateTime(focused.year, focused.month + 1, 1);
      } else if (mode == 1) {
        selected = selected.add(const Duration(days: 7));
        focused = selected;
      } else {
        selected = selected.add(const Duration(days: 1));
        focused = selected;
      }
    });
  }
}
