import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Session cookies for native builds, persisted in the Keychain / Keystore.
/// Not used on the web, where the browser keeps httpOnly cookies out of reach of the app.
class CookieStore {
  CookieStore();

  static const _key = 'tbn_session_cookies_v1';
  static const _storage = FlutterSecureStorage();
  final Map<String, String> _cookies = {};

  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return;
    try {
      _cookies
        ..clear()
        ..addAll(Map<String, String>.from(jsonDecode(raw) as Map));
    } catch (_) {
      await clear();
    }
  }

  String? get header => _cookies.isEmpty ? null : _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  /// `dart:io` joins several Set-Cookie headers with commas; split only where a new cookie starts.
  Future<void> absorb(String? setCookieHeader) async {
    if (setCookieHeader == null || setCookieHeader.isEmpty) return;
    for (final cookie in setCookieHeader.split(RegExp(r',(?=\s*[A-Za-z0-9_.-]+=)'))) {
      final parts = cookie.split(';');
      final pair = parts.first.trim();
      final i = pair.indexOf('=');
      if (i <= 0) continue;
      final name = pair.substring(0, i);
      final value = pair.substring(i + 1);
      final expired = parts.any((p) => p.trim().toLowerCase() == 'max-age=0');
      if (value.isEmpty || expired) {
        _cookies.remove(name);
      } else {
        _cookies[name] = value;
      }
    }
    await _storage.write(key: _key, value: jsonEncode(_cookies));
  }

  Future<void> clear() async {
    _cookies.clear();
    await _storage.delete(key: _key);
  }
}
