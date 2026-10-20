import 'dart:async';

import 'package:flutter/material.dart';

import 'places.dart';

/// Δύο dropdown πεδία: πρώτα Χώρα, μετά Πόλη (με αναζήτηση).
/// Μεταλλάσσει το [value] και καλεί [onChanged].
class PlaceFields extends StatefulWidget {
  const PlaceFields({super.key, required this.value, this.onChanged});

  final PlaceValue value;
  final VoidCallback? onChanged;

  @override
  State<PlaceFields> createState() => _PlaceFieldsState();
}

class _PlaceFieldsState extends State<PlaceFields> {
  bool _ready = Places.countries.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_ready) {
      Places.ensureLoaded().then((_) {
        if (mounted) setState(() => _ready = Places.countries.isNotEmpty);
      });
    }
  }

  PlaceValue get v => widget.value;

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<PlaceCountry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CountrySheet(),
    );
    if (picked == null) return;
    setState(() {
      if (v.countryCode != picked.code) {
        v.city = '';
        v.lat = null;
        v.lon = null;
      }
      v.countryCode = picked.code;
      v.countryName = picked.en;
    });
    widget.onChanged?.call();
    // Συνέχεια αυτόματα στην πόλη.
    await _pickCity();
  }

  Future<void> _pickCity() async {
    final cc = v.countryCode;
    if (cc == null) return;
    final picked = await showModalBottomSheet<PlaceCity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CitySheet(countryCode: cc),
    );
    if (picked == null) return;
    setState(() {
      v.city = picked.name;
      v.lat = picked.lat;
      v.lon = picked.lon;
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final country = Places.countryByCode(v.countryCode);
    final countryText = country != null
        ? '${country.el} · ${country.en}'
        : (v.countryName.isNotEmpty ? v.countryName : '');
    final cityText = v.city;
    return Column(
      children: [
        _PickerField(
          label: 'Χώρα',
          text: countryText,
          hint: _ready ? 'Επιλογή χώρας' : 'Φόρτωση…',
          icon: Icons.public_rounded,
          onTap: _ready ? _pickCountry : null,
        ),
        const SizedBox(height: 10),
        _PickerField(
          label: 'Πόλη',
          text: cityText,
          hint: v.countryCode == null
              ? 'Διάλεξε πρώτα χώρα'
              : 'Επιλογή πόλης',
          icon: Icons.location_city_rounded,
          onTap: (_ready && v.countryCode != null) ? _pickCity : null,
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.text,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String text;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          enabled: onTap != null,
        ),
        child: Text(
          text.isEmpty ? hint : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: text.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.hint,
    required this.onQuery,
    required this.child,
  });

  final String title;
  final String hint;
  final ValueChanged<String> onQuery;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: h * 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: false,
                onChanged: onQuery,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet();
  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final list = Places.searchCountries(q);
    return _SheetFrame(
      title: 'Επιλογή χώρας',
      hint: 'Αναζήτηση χώρας',
      onQuery: (s) => setState(() => q = s),
      child: list.isEmpty
          ? const Center(child: Text('Δεν βρέθηκε χώρα'))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final c = list[i];
                return ListTile(
                  title: Text(c.el),
                  subtitle: Text(c.en),
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
    );
  }
}

class _CitySheet extends StatefulWidget {
  const _CitySheet({required this.countryCode});
  final String countryCode;
  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  String q = '';
  List<PlaceCity> online = const [];
  bool searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String s) {
    setState(() {
      q = s;
      online = const [];
    });
    _debounce?.cancel();
    final text = s.trim();
    if (text.length < 3) {
      setState(() => searching = false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      // Online μόνο όταν το τοπικό dataset δίνει λίγα αποτελέσματα.
      if (Places.searchCities(widget.countryCode, text, limit: 6).length >=
          6) {
        return;
      }
      if (mounted) setState(() => searching = true);
      final res = await Places.searchOnline(widget.countryCode, text);
      if (!mounted || q.trim() != text) return;
      setState(() {
        online = res;
        searching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = Places.searchCities(widget.countryCode, q);
    final seen = <String>{
      for (final c in local) Places.norm(c.name),
    };
    final extra = online
        .where((c) => seen.add(Places.norm(c.name)))
        .toList();
    final all = [...local, ...extra];
    final country = Places.countryByCode(widget.countryCode);

    return _SheetFrame(
      title: 'Πόλη · ${country?.el ?? ''}',
      hint: 'Αναζήτηση πόλης (ελληνικά ή αγγλικά)',
      onQuery: _onQuery,
      child: ListView(
        children: [
          if (searching)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Αναζήτηση online…'),
                ],
              ),
            ),
          for (final c in all)
            ListTile(
              title: Text(c.display),
              subtitle: c.display != c.name ? Text(c.name) : null,
              onTap: () => Navigator.pop(context, c),
            ),
          if (all.isEmpty && !searching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Δεν βρέθηκε πόλη. Δοκίμασε άλλη γραφή.'),
            ),
        ],
      ),
    );
  }
}
