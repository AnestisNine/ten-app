import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/app_store.dart';

/// Lets a user subscribe to the band calendar from Google / Apple / Outlook calendar.
/// The secret URL is shown only right after it is created; creating a new one disables the old.
Future<void> showCalendarFeedSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CalendarFeedSheet(),
  );
}

class _CalendarFeedSheet extends StatefulWidget {
  const _CalendarFeedSheet();

  @override
  State<_CalendarFeedSheet> createState() => _CalendarFeedSheetState();
}

class _CalendarFeedSheetState extends State<_CalendarFeedSheet> {
  bool loading = true;
  bool active = false;
  String? url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await AppStore.api.get('/api/v1/calendar/feed') as Map<String, dynamic>;
      active = json['active'] as bool;
    } catch (e) {
      AppStore.reportError(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _create() async {
    setState(() => loading = true);
    try {
      final json = await AppStore.api.post('/api/v1/calendar/feed') as Map<String, dynamic>;
      url = json['url'] as String;
      active = true;
    } catch (e) {
      AppStore.reportError(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _disable() async {
    setState(() => loading = true);
    try {
      await AppStore.api.delete('/api/v1/calendar/feed');
      active = false;
      url = null;
    } catch (e) {
      AppStore.reportError(e);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Συγχρονισμός ημερολογίου', style: t.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Πρόσθεσε τα lives και τις εκδηλώσεις της μπάντας στο Google Calendar, '
            'Apple Calendar ή Outlook. Ενημερώνεται αυτόματα (περίπου κάθε ώρα).',
            style: t.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (url != null) ...[
            SelectableText(url!, style: t.bodySmall),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Αντιγράφηκε')));
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Αντιγραφή συνδέσμου'),
            ),
            const SizedBox(height: 12),
            Text(
              'Google Calendar: Ρυθμίσεις → Προσθήκη ημερολογίου → Από URL.\n'
              'iPhone: Ρυθμίσεις → Ημερολόγιο → Λογαριασμοί → Προσθήκη → Άλλο → Συνδρομή.\n'
              'Ο σύνδεσμος είναι προσωπικός: μην τον μοιραστείς. Δεν θα εμφανιστεί ξανά.',
              style: t.bodySmall?.copyWith(color: muted, height: 1.5),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.link_rounded, size: 18),
              label: Text(active ? 'Νέος σύνδεσμος (ο παλιός σταματά)' : 'Δημιουργία συνδέσμου'),
            ),
          ],
          if (active && !loading)
            TextButton(
              onPressed: _disable,
              style: TextButton.styleFrom(foregroundColor: TbnColors.danger),
              child: const Text('Απενεργοποίηση συγχρονισμού'),
            ),
        ],
      ),
    );
  }
}
