import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/file_download_helper.dart';

/// Centralized API helper for downloading, fetching, and previewing binary files.
class FileApiHelper {
  FileApiHelper._();

  /// Fetches binary bytes from an API URL with timeout and error handling.
  static Future<Uint8List> fetchBytes(String url) async {
    final uri = Uri.parse(url);
    AppLogger.debug('FILE_API', 'Initiating API byte download: host=${uri.host}, path=${uri.path}');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 35));

      AppLogger.info(
        'FILE_API',
        'API response: HTTP ${response.statusCode}, bytes=${response.bodyBytes.length}, type=${response.headers['content-type']}',
      );

      if (response.statusCode != 200) {
        throw Exception('API file request failed with HTTP ${response.statusCode}');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('The requested document file returned empty contents.');
      }

      return response.bodyBytes;
    } catch (e, st) {
      AppLogger.error('FILE_API', 'Failed to fetch bytes via API: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Saves binary bytes to the user's downloads folder.
  static void downloadFileFromBytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) {
    AppLogger.info('FILE_API', 'Triggering browser file download: "$fileName" (${bytes.length} bytes)');
    FileDownloadHelper.download(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  /// Downloads a file by fetching its bytes via API and saving to disk.
  static Future<void> downloadFileFromUrl({
    required String url,
    required String fileName,
    String? mimeType,
  }) async {
    final bytes = await fetchBytes(url);
    downloadFileFromBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}
