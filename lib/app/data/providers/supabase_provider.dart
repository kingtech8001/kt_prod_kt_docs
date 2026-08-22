import 'dart:typed_data';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider {
  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Storage Methods
  Future<String> uploadDocumentFile({
    required String storagePath,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    AppLogger.debug(
      'SUPABASE_STORAGE',
      'Uploading ${fileBytes.lengthInBytes} bytes to "$storagePath" with mime: $mimeType',
    );
    try {
      final response = await client.storage.from(AppConstants.storageBucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );
      AppLogger.info('SUPABASE_STORAGE', 'Upload successful: $response');
      return storagePath;
    } catch (e, st) {
      AppLogger.error(
        'SUPABASE_STORAGE',
        'Failed to upload file to path: $storagePath',
        error: e,
        stackTrace: st,
        contextData: {'mimeType': mimeType, 'size': fileBytes.lengthInBytes},
      );
      rethrow;
    }
  }

  Future<String> createSignedUrl({
    required String storagePath,
    int expiresInSeconds = 300,
    bool download = false,
  }) async {
    AppLogger.debug('SUPABASE_STORAGE', 'Creating signed URL for: $storagePath (expires in: ${expiresInSeconds}s)');
    try {
      final response = await client.storage
          .from(AppConstants.storageBucket)
          .createSignedUrl(
            storagePath,
            expiresInSeconds,
            transform: null,
          );
      AppLogger.info('SUPABASE_STORAGE', 'Signed URL created successfully.');
      return response;
    } catch (e, st) {
      AppLogger.error(
        'SUPABASE_STORAGE',
        'Failed to create signed URL for: $storagePath',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<Uint8List> downloadFileBytes(String storagePath) async {
    AppLogger.debug('SUPABASE_STORAGE', 'Downloading bytes for: $storagePath');
    try {
      final bytes = await client.storage
          .from(AppConstants.storageBucket)
          .download(storagePath);
      AppLogger.info('SUPABASE_STORAGE', 'Downloaded ${bytes.lengthInBytes} bytes for: $storagePath');
      return bytes;
    } catch (e, st) {
      AppLogger.error(
        'SUPABASE_STORAGE',
        'Failed to download file bytes for: $storagePath',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
