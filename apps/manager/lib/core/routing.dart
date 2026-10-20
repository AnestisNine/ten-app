import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'places.dart';

/// Αποτέλεσμα διαδρομής οδήγησης μεταξύ δύο πόλεων.
class RouteInfo {
  const RouteInfo({
    required this.km,
    required this.minutes,
    this.fastKm = const {},
    this.ferry = false,
    this.estimate = false,
    this.key = '',
  });

  /// Κλειδί cache της διαδρομής (για χειροκίνητη τιμή διοδίων).
  final String key;

  RouteInfo withKey(String k) => RouteInfo(
        km: km,
        minutes: minutes,
        fastKm: fastKm,
        ferry: ferry,
        estimate: estimate,
        key: k,
      );

  final double km;
  final double minutes;

  /// Χιλιόμετρα "γρήγορου οδικού δικτύου" (πιθανά διόδια) ανά χώρα.
  final Map<String, double> fastKm;
  final bool ferry;

  /// true = προσέγγιση (ευθεία γραμμή × συντελεστής), όχι πραγματική διαδρομή.
  final bool estimate;

  Map<String, dynamic> toJson() => {
        'km': km,
        'min': minutes,
        'fast': fastKm,
        'ferry': ferry,
      };

  static RouteInfo fromJson(Map<String, dynamic> m) => RouteInfo(
        km: (m['km'] as num).toDouble(),
        minutes: (m['min'] as num).toDouble(),
        fastKm: ((m['fast'] as Map<String, dynamic>?) ?? const {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        ferry: (m['ferry'] as bool?) ?? false,
      );
}

/// Ενδεικτικό κόστος καυσίμου + διοδίων.
class TripCost {
  const TripCost(this.fuel, this.tolls, {this.manualTolls = false});
  final double fuel;
  final double tolls;
  final bool manualTolls;
  double get total => fuel + tolls;
}

class Routing {
  static const _cacheKey = 'tbn_route_cache_v1';
  static final Map<String, RouteInfo> _cache = {};
  static final Map<String, Future<RouteInfo>> _inflight = {};
  static bool _cacheLoaded = false;

  static const _hosts = [
    'https://router.project-osrm.org/route/v1/driving',
    'https://routing.openstreetmap.de/routed-car/route/v1/driving',
  ];

  static String _key(double a, double b, double c, double d) =>
      '${a.toStringAsFixed(3)},${b.toStringAsFixed(3)}>'
      '${c.toStringAsFixed(3)},${d.toStringAsFixed(3)}';

  static Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((k, v) {
        _cache[k] = RouteInfo.fromJson(v as Map<String, dynamic>);
      });
    } catch (_) {}
  }

  static Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(_cache.map((k, v) => MapEntry(k, v.toJson()))),
      );
    } catch (_) {}
  }

  /// Διαδρομή οδήγησης από (lat1,lon1) προς (lat2,lon2).
  static Future<RouteInfo> route(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    await _loadCache();
    await Places.ensureLoaded();
    final key = _key(lat1, lon1, lat2, lon2);
    await _loadOverrides();
    final cached = _cache[key];
    if (cached != null) return cached.withKey(key);
    return _inflight[key] ??= _fetchAndClear(key, lat1, lon1, lat2, lon2);
  }

  static Future<RouteInfo> _fetchAndClear(
    String key,
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    try {
      return await _fetch(key, lat1, lon1, lat2, lon2);
    } finally {
      _inflight.remove(key);
    }
  }

  static Future<RouteInfo> _fetch(
    String key,
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    for (final host in _hosts) {
      try {
        final uri = Uri.parse(
          '$host/$lon1,$lat1;$lon2,$lat2'
          '?overview=false&steps=true&geometries=polyline',
        );
        final r = await http.get(uri).timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final info = _parse(jsonDecode(r.body) as Map<String, dynamic>);
        if (info == null) continue;
        _cache[key] = info;
        _saveCache();
        return info.withKey(key);
      } catch (_) {
        continue;
      }
    }
    return fallback(lat1, lon1, lat2, lon2).withKey(key);
  }

  static RouteInfo? _parse(Map<String, dynamic> body) {
    if (body['code'] != 'Ok') return null;
    final routes = body['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;
    final route = routes.first as Map<String, dynamic>;
    final meters = (route['distance'] as num).toDouble();
    final seconds = (route['duration'] as num).toDouble();

    final fast = <String, double>{};
    var ferry = false;
    for (final leg in (route['legs'] as List<dynamic>? ?? const [])) {
      for (final s in ((leg as Map<String, dynamic>)['steps']
              as List<dynamic>? ??
          const [])) {
        final step = s as Map<String, dynamic>;
        if (step['mode'] == 'ferry') ferry = true;
        final d = (step['distance'] as num?)?.toDouble() ?? 0;
        final t = (step['duration'] as num?)?.toDouble() ?? 0;
        if (d < 2000 || t <= 0) continue;
        final kmh = d / t * 3.6;
        if (kmh < 80) continue; // όχι αυτοκινητόδρομος
        final geom = step['geometry'];
        if (geom is! String) continue;
        final pts = _decodePolyline(geom);
        if (pts.isEmpty) continue;
        final mid = pts[pts.length ~/ 2];
        final cc = Places.nearestCountry(mid.$1, mid.$2);
        if (cc == null) continue;
        fast[cc] = (fast[cc] ?? 0) + d / 1000;
      }
    }
    return RouteInfo(
      km: meters / 1000,
      minutes: seconds / 60,
      fastKm: fast,
      ferry: ferry,
    );
  }

  /// Polyline5 decoder → λίστα (lat, lon).
  static List<(double, double)> _decodePolyline(String s) {
    final out = <(double, double)>[];
    var i = 0, lat = 0, lon = 0;
    while (i < s.length) {
      var shift = 0, result = 0, b = 0;
      do {
        b = s.codeUnitAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && i < s.length);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = s.codeUnitAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && i < s.length);
      lon += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      out.add((lat / 1e5, lon / 1e5));
    }
    return out;
  }

  /// Προσέγγιση όταν δεν υπάρχει δίκτυο/διαδρομή: ευθεία × 1.25.
  static RouteInfo fallback(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final km = haversineKm(lat1, lon1, lat2, lon2) * 1.25;
    return RouteInfo(km: km, minutes: km / 70 * 60, estimate: true);
  }

  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(a.toDouble()));
  }

  // ---------- κόστος

  /// Ενδεικτικό πραγματικό κόστος €/km σε αυτοκινητόδρομο (επιβατικό/βαν <3.5t).
  static const Map<String, double> tollPerKm = {
    'FR': 0.11,
    'IT': 0.09,
    'ES': 0.09,
    'PT': 0.09,
    'HR': 0.08,
    'GR': 0.055,
    'PL': 0.06,
    'RS': 0.05,
    'MK': 0.04,
    'ME': 0.05,
    'BA': 0.04,
    'AL': 0.03,
    'RO': 0.0,
    'IE': 0.06,
    'NO': 0.06,
    'GB': 0.0,
  };

  /// Εφάπαξ βινιέτες (€, ενδεικτικά για σύντομη χρήση) όταν περνάς >15 km.
  static const Map<String, double> vignette = {
    'AT': 12.0,
    'CH': 43.0,
    'CZ': 12.0,
    'SK': 12.0,
    'SI': 17.0,
    'HU': 14.0,
    'BG': 8.0,
    'RO': 4.0,
    'MD': 0.0,
  };

  static TripCost cost(RouteInfo r, double dieselPrice, double lPer100) {
    final fuel = r.km * lPer100 / 100 * dieselPrice;
    final manual = r.key.isEmpty ? null : _overrides[r.key];
    if (manual != null) return TripCost(fuel, manual, manualTolls: true);
    var tolls = 0.0;
    r.fastKm.forEach((cc, km) {
      tolls += km * (tollPerKm[cc] ?? 0);
      if (km >= 15) tolls += vignette[cc] ?? 0;
    });
    return TripCost(fuel, tolls);
  }

  // ---------- χειροκίνητα διόδια (ανά διαδρομή, ίδια τιμή και στις δύο κατευθύνσεις)

  static const _ovKey = 'tbn_toll_overrides_v1';
  static final Map<String, double> _overrides = {};
  static bool _ovLoaded = false;

  /// Αυξάνεται όταν αλλάζει χειροκίνητη τιμή, ώστε τα widgets να ξαναχτιστούν.
  static final ValueNotifier<int> overridesVersion = ValueNotifier<int>(0);

  static Future<void> _loadOverrides() async {
    if (_ovLoaded) return;
    _ovLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_ovKey);
      if (raw == null || raw.isEmpty) return;
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
        _overrides[k] = (v as num).toDouble();
      });
      overridesVersion.value++;
    } catch (_) {}
  }

  static String _reverseKey(String key) {
    final parts = key.split('>');
    return parts.length == 2 ? '${parts[1]}>${parts[0]}' : key;
  }

  /// null = αφαίρεση χειροκίνητης τιμής (επιστροφή στην εκτίμηση).
  static Future<void> setTollOverride(String key, double? value) async {
    if (key.isEmpty) return;
    for (final k in [key, _reverseKey(key)]) {
      if (value == null) {
        _overrides.remove(k);
      } else {
        _overrides[k] = value;
      }
    }
    overridesVersion.value++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ovKey, jsonEncode(_overrides));
    } catch (_) {}
  }

  static double? tollOverride(String key) => _overrides[key];

  static String formatDuration(double minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    if (h == 0) return '${m}′';
    return '${h}ω ${m.toString().padLeft(2, '0')}′';
  }

  /// Διαδρομή ανάμεσα σε δύο lives (null αν λείπουν συντεταγμένες).
  static Future<RouteInfo?> routeBetween(LiveItem a, LiveItem b) async {
    await Places.ensureLoaded();
    final pa = Places.coordsOf(a);
    final pb = Places.coordsOf(b);
    if (pa == null || pb == null) return null;
    if ((pa.lat - pb.lat).abs() < 0.001 && (pa.lon - pb.lon).abs() < 0.001) {
      return const RouteInfo(km: 0, minutes: 0);
    }
    return route(pa.lat, pa.lon, pb.lat, pb.lon);
  }

  @visibleForTesting
  static void clearMemory() => _cache.clear();
}
