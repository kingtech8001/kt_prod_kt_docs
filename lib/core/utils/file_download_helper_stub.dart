import 'dart:typed_data';

/// Fallback stub for non-web platforms.
void triggerFileDownload({
  required Uint8List bytes,
  required String fileName,
  String? mimeType,
}) {
  // Mobile / desktop platforms can save via local storage or file picker.
}
