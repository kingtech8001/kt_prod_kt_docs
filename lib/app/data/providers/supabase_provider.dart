import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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
      if (download) {
        final separator = response.contains('?') ? '&' : '?';
        return '$response${separator}download=true';
      }
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
      if (storagePath.startsWith('gdrive://')) {
        final fileId = storagePath.replaceFirst('gdrive://', '');
        final url = getGoogleDrivePreviewUrl(fileId, download: true);
        final uri = Uri.parse(url);
        final response = await http.get(uri).timeout(const Duration(seconds: 40));
        if (response.statusCode != 200) {
          throw Exception('Failed to download from Google Drive API (HTTP ${response.statusCode})');
        }
        if (response.bodyBytes.isEmpty) {
          throw Exception('File returned from Google Drive API is empty.');
        }
        AppLogger.info('GDRIVE_STORAGE', 'Downloaded ${response.bodyBytes.length} bytes for: $storagePath');
        return response.bodyBytes;
      }

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

  // Google Drive Edge Function Storage Methods
  Future<Map<String, dynamic>> uploadToGoogleDrive({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    String? folderName,
  }) async {
    AppLogger.debug(
      'GDRIVE_STORAGE',
      'Uploading ${fileBytes.lengthInBytes} bytes ($fileName) via Edge Function: ${AppConstants.edgeFunctionGdriveUpload}',
    );
    try {
      final response = await client.functions.invoke(
        AppConstants.edgeFunctionGdriveUpload,
        body: {
          'fileName': fileName,
          'mimeType': mimeType,
          'fileBase64': base64Encode(fileBytes),
          'folderName': folderName,
          'userId': currentUser?.id,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false || data['error'] != null) {
          throw Exception(data['error'] ?? 'Google Drive upload failed');
        }
        AppLogger.info('GDRIVE_STORAGE', 'Upload to Google Drive success, fileId: ${data["fileId"]}');
        return data;
      } else if (data is String) {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        return decoded;
      }
      throw Exception('Unexpected response format from Google Drive upload');
    } catch (e, st) {
      AppLogger.error(
        'GDRIVE_STORAGE',
        'Failed to upload file to Google Drive: $fileName',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> deleteFromGoogleDrive(String fileId) async {
    AppLogger.debug('GDRIVE_STORAGE', 'Deleting Google Drive file ID: $fileId');
    try {
      await client.functions.invoke(
        AppConstants.edgeFunctionGdriveDelete,
        body: {'fileId': fileId},
      );
      AppLogger.info('GDRIVE_STORAGE', 'Google Drive file $fileId deleted successfully.');
    } catch (e, st) {
      AppLogger.warning('GDRIVE_STORAGE', 'Non-fatal error deleting Google Drive file: $e ($st)');
    }
  }

  String getGoogleDrivePreviewUrl(String fileId, {bool download = false}) {
    final baseUrl = '${AppConstants.supabaseUrl}/functions/v1/${AppConstants.edgeFunctionGdriveProxy}?fileId=$fileId';
    if (download) {
      return '$baseUrl&download=true';
    }
    return baseUrl;
  }
}
