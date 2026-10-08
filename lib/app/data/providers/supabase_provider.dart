import 'dart:typed_data';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider {
  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Supabase Storage Bucket Methods
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
    int expiresInSeconds = 3600,
    bool download = false,
  }) async {
    final cleanPath = storagePath.startsWith('/') ? storagePath.substring(1) : storagePath;
    AppLogger.debug('SUPABASE_STORAGE', 'Creating signed URL for: $cleanPath (expires in: ${expiresInSeconds}s)');
    try {
      final response = await client.storage
          .from(AppConstants.storageBucket)
          .createSignedUrl(
            cleanPath,
            expiresInSeconds,
            transform: null,
          );
      AppLogger.info('SUPABASE_STORAGE', 'Signed URL created successfully.');
      if (download) {
        final separator = response.contains('?') ? '&' : '?';
        return '$response${separator}download=true';
      }
      return response;
    } catch (e, st) {
      AppLogger.error(
        'SUPABASE_STORAGE',
        'Failed to create signed URL for: $cleanPath',
        error: e,
        stackTrace: st,
      );
      try {
        final publicUrl = client.storage.from(AppConstants.storageBucket).getPublicUrl(cleanPath);
        if (publicUrl.isNotEmpty) {
          final sep = publicUrl.contains('?') ? '&' : '?';
          return download ? '$publicUrl${sep}download=true' : publicUrl;
        }
      } catch (_) {}
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

  Future<void> deleteDocumentFile(String storagePath) async {
    AppLogger.debug('SUPABASE_STORAGE', 'Deleting file: $storagePath');
    try {
      await client.storage.from(AppConstants.storageBucket).remove([storagePath]);
      AppLogger.info('SUPABASE_STORAGE', 'File deleted: $storagePath');
    } catch (e, st) {
      AppLogger.warning('SUPABASE_STORAGE', 'Failed to delete file from storage: $e ($st)');
    }
  }
}
