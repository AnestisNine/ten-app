import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../api/api_client.dart';

/// Returns an [ImageProvider] for a stored image reference, or null.
///
/// Server images (`/api/v1/files/...`) are loaded with the session cookie. Older `data:image/...`
/// references from the local-only versions are still shown.
ImageProvider? imageProviderFromRef(String? ref) {
  if (ref == null) return null;
  if (ref.startsWith('/api/')) {
    final api = ApiClient.instance;
    return NetworkImage(api.uri(ref).toString(), headers: api.authHeaders);
  }
  if (!ref.startsWith('data:image')) {
    return null;
  }
  final comma = ref.indexOf(',');
  if (comma < 0) {
    return null;
  }
  try {
    return MemoryImage(base64Decode(ref.substring(comma + 1)));
  } catch (_) {
    return null;
  }
}
