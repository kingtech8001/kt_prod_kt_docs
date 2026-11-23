import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';

/// External file access shared by PDF and image preview controllers.
class DocumentPreviewDataset {
  DocumentPreviewDataset(this._provider);
  final SupabaseProvider _provider;

  Future<Uint8List> fetchBytes(String url) async {
    try {
      return await FileApiHelper.fetchBytes(url);
    } catch (error, stackTrace) {
      AppLogger.error(
        'PREVIEW_DATASET',
        'File fetch failed.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Uint8List> download(String path) => _provider.downloadFileBytes(path);
  Future<String> createSignedUrl(String path) =>
      _provider.createSignedUrl(storagePath: path);

  Future<void> downloadBytes(Uint8List bytes, String name, String mime) async {
    try {
      FileApiHelper.downloadFileFromBytes(
        bytes: bytes,
        fileName: name,
        mimeType: mime,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'PREVIEW_DATASET',
        'File download failed.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> downloadUrl(String url, String name, String mime) async {
    try {
      await FileApiHelper.downloadFileFromUrl(
        url: url,
        fileName: name,
        mimeType: mime,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'PREVIEW_DATASET',
        'URL download failed.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
