import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'http_factory.dart';

/// Error returned by the API: `{ "error": code, "message": ... }`.
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message);

  final int status;
  final String code;
  final String message;

  bool get isUnauthenticated => status == 401;
  bool get needsTwoFactor => code == 'two_factor_required';
  bool get isOffline => status == 0;

  @override
  String toString() => 'ApiException($status, $code, $message)';
}

class ApiClient {
  ApiClient._(this._http);

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._(createHttpClient());

  final http.Client _http;

  static const _defined = String.fromEnvironment('API_BASE_URL');

  /// Server origin: the page's own origin, unless built with --dart-define=API_BASE_URL (development).
  String baseUrl = '';

  Future<void> init() async {
    baseUrl = _defined.isNotEmpty ? _defined : (kIsWeb ? Uri.base.origin : '');
  }

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body);
  Future<dynamic> put(String path, Object body) => _send('PUT', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> upload(String path, Uint8List bytes, String filename) async {
    final req = http.MultipartRequest('PUT', uri(path))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    return _handle(await http.Response.fromStream(await _http.send(req)));
  }

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final req = http.Request(method, uri(path));
    if (body != null) {
      req.headers['content-type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(const Duration(seconds: 20)));
    } catch (e) {
      throw ApiException(0, 'offline', 'Δεν υπάρχει σύνδεση με τον server');
    }
    return _handle(res);
  }

  Future<dynamic> _handle(http.Response res) async {
    final text = utf8.decode(res.bodyBytes);
    dynamic json;
    if (text.isNotEmpty) {
      try {
        json = jsonDecode(text);
      } catch (_) {
        json = null;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    final map = json is Map ? json : const {};
    throw ApiException(
      res.statusCode,
      (map['error'] ?? map['code'] ?? 'http_${res.statusCode}').toString(),
      (map['message'] ?? 'Σφάλμα ${res.statusCode}').toString(),
    );
  }
}
