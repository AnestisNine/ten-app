import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';

/// iOS / Android: opens the system share sheet.
Future<void> saveAndShareFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? subject,
  String? text,
  Rect? shareOrigin,
}) async {
  await Share.shareXFiles(
    <XFile>[XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
    subject: subject,
    text: text,
    sharePositionOrigin: shareOrigin,
  );
}
