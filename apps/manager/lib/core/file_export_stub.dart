import 'dart:typed_data';
import 'dart:ui' show Rect;

/// Not used by the app (web-only); lets tests run on the Dart VM.
Future<void> saveAndShareFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? subject,
  String? text,
  Rect? shareOrigin,
}) {
  throw UnsupportedError('File downloads are only available in the web app');
}
