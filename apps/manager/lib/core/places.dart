import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'models.dart';

/// Χώρα (Ευρώπη + UK) από το ενσωματωμένο dataset.
class PlaceCountry {
  const PlaceCountry(this.code, this.en, this.el, this.aliases);
  final String code;
  final String en;
  final String el;
  final List<String> aliases;
}

/// Πόλη με συντεταγμένες.
class PlaceCity {
  const PlaceCity({
    required this.name,
    required this.cc,
    required this.lat,
    required this.lon,
    this.pop = 0,
    this.el,
  });
  final String name;
  final String cc;
  final double lat;
  final double lon;
  final int pop;
  final String? el;

  /// Όνομα για εμφάνιση (ελληνικό όπου υπάρχει).
  String get display => (el != null && el!.isNotEmpty) ? el! : name;
}

/// Τιμή επιλογής τόπου (χώρα + πόλη) που κρατά η φόρμα.
class PlaceValue {
  PlaceValue({
    this.countryCode,
    this.countryName = '',
    this.city = '',
    this.lat,
    this.lon,
  });
  String? countryCode;
  String countryName;
  String city;
  double? lat;
  double? lon;

  bool get hasCity => city.trim().isNotEmpty;
}

class Places {
  static List<PlaceCountry> countries = const [];
  static List<PlaceCity> cities = const [];
  static Future<void>? _loading;

  static Future<void> ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/places.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      countries = (map['countries'] as List<dynamic>).map((e) {
        final l = e as List<dynamic>;
        return PlaceCountry(
          l[0] as String,
          l[1] as String,
          l[2] as String,
          (l[3] as List<dynamic>).map((a) => a as String).toList(),
        );
      }).toList();
      cities = (map['cities'] as List<dynamic>).map((e) {
        final l = e as List<dynamic>;
        return PlaceCity(
          name: l[0] as String,
          cc: l[1] as String,
          lat: (l[2] as num).toDouble(),
          lon: (l[3] as num).toDouble(),
          pop: (l[4] as num).toInt(),
          el: l.length > 5 ? l[5] as String? : null,
        );
      }).toList();
    } catch (_) {
      _loading = null; // allow retry
    }
  }

  // ---------- text normalisation (case / Greek accents / Latin diacritics)

  static const _from = 'άέήίόύώϊϋΐΰςàáâãäåçèéêëìíîïñòóôõöøùúûüýÿšžčćđłśźżğış';
  static const _to = 'αεηιουωιυιυσaaaaaaceeeeiiiinoooooouuuuyyszccdlszzgis';

  static String norm(String s) {
    final b = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      final ch = String.fromCharCode(r);
      final i = _from.indexOf(ch);
      b.write(i >= 0 ? _to[i] : ch);
    }
    return b.toString().trim();
  }

  // ---------- countries

  static PlaceCountry? countryByCode(String? code) {
    if (code == null) return null;
    for (final c in countries) {
      if (c.code == code) return c;
    }
    return null;
  }

  static PlaceCountry? countryByName(String name) {
    final n = norm(name);
    if (n.isEmpty) return null;
    for (final c in countries) {
      if (norm(c.en) == n || norm(c.el) == n) return c;
      for (final a in c.aliases) {
        if (norm(a) == n) return c;
      }
    }
    if (n == 'england' || n == 'uk' || n == 'united kingdom' ||
        n == 'scotland' || n == 'wales' || n == 'αγγλια') {
      return countryByCode('GB');
    }
    return null;
  }

  static List<PlaceCountry> searchCountries(String q) {
    final n = norm(q);
    final list = countries.where((c) {
      if (n.isEmpty) return true;
      return norm(c.en).contains(n) ||
          norm(c.el).contains(n) ||
          c.aliases.any((a) => norm(a).contains(n));
    }).toList();
    list.sort((a, b) => norm(a.el).compareTo(norm(b.el)));
    return list;
  }

  // ---------- cities

  static List<PlaceCity> searchCities(String cc, String q, {int limit = 60}) {
    final n = norm(q);
    final res = <PlaceCity>[];
    for (final c in cities) {
      if (c.cc != cc) continue;
      if (n.isEmpty ||
          norm(c.name).contains(n) ||
          (c.el != null && norm(c.el!).contains(n))) {
        res.add(c);
      }
    }
    res.sort((a, b) {
      if (n.isNotEmpty) {
        final as = norm(a.name).startsWith(n) ||
            (a.el != null && norm(a.el!).startsWith(n));
        final bs = norm(b.name).startsWith(n) ||
            (b.el != null && norm(b.el!).startsWith(n));
        if (as != bs) return as ? -1 : 1;
      }
      return b.pop.compareTo(a.pop);
    });
    return res.length > limit ? res.sublist(0, limit) : res;
  }

  /// Online fallback (Open-Meteo geocoding) για πόλεις που λείπουν.
  static Future<List<PlaceCity>> searchOnline(String cc, String q) async {
    try {
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': q,
        'count': '15',
        'language': 'en',
        'format': 'json',
        'countryCode': cc,
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return const [];
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final results = (map['results'] as List<dynamic>?) ?? const [];
      final out = <PlaceCity>[];
      for (final e in results) {
        final m = e as Map<String, dynamic>;
        if ((m['country_code'] as String?)?.toUpperCase() != cc) continue;
        final lat = (m['latitude'] as num?)?.toDouble();
        final lon = (m['longitude'] as num?)?.toDouble();
        final name = m['name'] as String?;
        if (lat == null || lon == null || name == null) continue;
        out.add(PlaceCity(
          name: name,
          cc: cc,
          lat: lat,
          lon: lon,
          pop: (m['population'] as num?)?.toInt() ?? 0,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Συντεταγμένες ενός live (αποθηκευμένες ή από το dataset για παλιά lives).
  static ({double lat, double lon, String? cc})? coordsOf(LiveItem live) {
    if (live.lat != null && live.lon != null) {
      return (lat: live.lat!, lon: live.lon!, cc: live.countryCode);
    }
    final cc = live.countryCode ?? countryByName(live.country)?.code;
    final n = norm(live.city);
    if (n.isEmpty) return null;
    PlaceCity? best;
    for (final c in cities) {
      if (cc != null && c.cc != cc) continue;
      if (norm(c.name) == n || (c.el != null && norm(c.el!) == n)) {
        if (best == null || c.pop > best.pop) best = c;
      }
    }
    if (best == null) return null;
    return (lat: best.lat, lon: best.lon, cc: best.cc);
  }

  /// Τρέχουσα τιμή επιλογής για ένα live (λύνει και παλιά lives χωρίς κωδικό).
  static PlaceValue valueOf(LiveItem live) {
    final code = live.countryCode ?? countryByName(live.country)?.code;
    final c = coordsOf(live);
    return PlaceValue(
      countryCode: code,
      countryName: live.country,
      city: live.city,
      lat: c?.lat,
      lon: c?.lon,
    );
  }

  /// Κωδικός χώρας του κοντινότερου city του dataset (για διόδια).
  static String? nearestCountry(double lat, double lon) {
    if (cities.isEmpty) return null;
    final k = math.cos(lat * math.pi / 180);
    var bestD = double.infinity;
    String? cc;
    for (final c in cities) {
      final dy = c.lat - lat;
      final dx = (c.lon - lon) * k;
      final d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        cc = c.cc;
      }
    }
    return cc;
  }
}
