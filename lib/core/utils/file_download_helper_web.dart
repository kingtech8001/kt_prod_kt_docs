import 'dart:html' as html;
import 'dart:typed_data';

/// Browser-native file download implementation for Flutter Web using Blob URLs.
void triggerFileDownload({
  required Uint8List bytes,
  required String fileName,
  String? mimeType,
}) {
  final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
