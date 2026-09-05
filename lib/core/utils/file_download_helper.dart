import 'dart:typed_data';

import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart' as platform_download;

/// Unified cross-platform file download utility.
class FileDownloadHelper {
  FileDownloadHelper._();

  /// Triggers a browser/system download of [bytes] saved as [fileName].
  static void download({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) {
    platform_download.triggerFileDownload(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}
