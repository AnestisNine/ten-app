import 'dart:convert';

import 'package:flutter/widgets.dart';

/// Returns an [ImageProvider] for a stored image reference, or null.
///
/// Images are stored as `data:image/...;base64,...` strings so they work
/// identically on iOS and on web (no dart:io / file paths).
/// Legacy local file paths from v0.7.x are ignored (fallback icon shown).
ImageProvider? imageProviderFromRef(String? ref) {
  if (ref == null || !ref.startsWith('data:image')) {
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
