import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/dashboard_metrics_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dataset responsible for all Home / Dashboard data operations.
/// Follows the strict 3-tier architecture: View -> Controller -> Dataset -> Supabase.
class DashboardDataset {
  final SupabaseProvider _provider;

  DashboardDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches dashboard metrics via RPC `get_dashboard_metrics` with safe fallback.
  Future<DashboardMetricsModel> getDashboardMetrics() async {
    AppLogger.debug(
      'DASHBOARD_DATASET',
      'Fetching dashboard metrics via RPC get_dashboard_metrics...',
    );
    try {
      final response = await _client.rpc('get_dashboard_metrics');
      if (response != null && response is Map<String, dynamic>) {
        AppLogger.info(
          'DASHBOARD_DATASET',
          'get_dashboard_metrics RPC success:',
          response,
        );
        return DashboardMetricsModel.fromJson(response);
      }
    } catch (rpcErr) {
      AppLogger.warning(
        'DASHBOARD_DATASET',
        'RPC get_dashboard_metrics fallback due to: $rpcErr',
      );
    }

    // Fallback if RPC is unavailable or returns null
    try {
      final countRes = await _client
          .from('documents')
          .select('id, file_size')
          .isFilter('deleted_at', null);

      final count = (countRes as List).length;
      var totalSize = 0;
      for (var r in countRes) {
        totalSize += (r['file_size'] as num?)?.toInt() ?? 0;
      }

      final trashRes = await _client
          .from('documents')
          .select('id, file_size')
          .not('deleted_at', 'is', null);

      final trashCount = (trashRes as List).length;
      var trashSize = 0;
      for (var r in trashRes) {
        trashSize += (r['file_size'] as num?)?.toInt() ?? 0;
      }

      return DashboardMetricsModel(
        totalDocuments: count,
        totalStorageBytes: totalSize,
        trashCount: trashCount,
        trashSizeBytes: trashSize,
      );
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_DATASET',
        'Error calculating dashboard fallback metrics: $e',
        error: e,
        stackTrace: st,
      );
      return DashboardMetricsModel();
    }
  }

  /// Fetches recent non-deleted documents with full relations.
  Future<List<DocumentModel>> getRecentDocuments({int limit = 8}) async {
    AppLogger.debug('DASHBOARD_DATASET', 'Fetching recent documents limit: $limit');
    try {
      final response = await _client
          .from('documents')
          .select('''
            *,
            document_categories(id, name, code, color_hex, icon),
            folders(id, name),
            profiles:uploaded_by(id, full_name, email),
            document_addresses(*),
            utility_metadata(*),
            appliance_warranty_metadata(*),
            personal_document_metadata(*),
            document_favorites(document_id, user_id)
          ''')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info(
        'DASHBOARD_DATASET',
        'Fetched ${list.length} recent documents.',
      );
      return list;
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_DATASET',
        'Error in getRecentDocuments: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches warranties expiring within 30 days.
  Future<List<DocumentModel>> getExpiringWarranties({int limit = 50}) async {
    AppLogger.debug('DASHBOARD_DATASET', 'Fetching expiring warranties...');
    try {
      final response = await _client
          .from('documents')
          .select('''
            *,
            document_categories(id, name, code, color_hex, icon),
            folders(id, name),
            profiles:uploaded_by(id, full_name, email),
            document_addresses(*),
            utility_metadata(*),
            appliance_warranty_metadata(*),
            personal_document_metadata(*),
            document_favorites(document_id, user_id)
          ''')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .where((doc) => doc.categoryCode == 'appliance_warranty')
          .where((doc) {
            final w = doc.applianceWarranty;
            return w != null && w.isExpiringSoon;
          })
          .toList();

      AppLogger.info(
        'DASHBOARD_DATASET',
        'Found ${list.length} expiring warranties.',
      );
      return list;
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_DATASET',
        'Error in getExpiringWarranties: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches pending utility bills.
  Future<List<DocumentModel>> getPendingUtilityBills({int limit = 50}) async {
    AppLogger.debug('DASHBOARD_DATASET', 'Fetching pending utility bills...');
    try {
      final response = await _client
          .from('documents')
          .select('''
            *,
            document_categories(id, name, code, color_hex, icon),
            folders(id, name),
            profiles:uploaded_by(id, full_name, email),
            document_addresses(*),
            utility_metadata(*),
            appliance_warranty_metadata(*),
            personal_document_metadata(*),
            document_favorites(document_id, user_id)
          ''')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .where((doc) => doc.categoryCode == 'utility_bills')
          .where((doc) {
            final u = doc.utilityMetadata;
            return u != null && !u.isPaid;
          })
          .toList();

      AppLogger.info(
        'DASHBOARD_DATASET',
        'Found ${list.length} pending utility bills.',
      );
      return list;
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_DATASET',
        'Error in getPendingUtilityBills: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Obtains signed preview URL for storage or Google Drive.
  Future<String> getSignedPreviewUrl(String storagePath, {bool download = false}) async {
    if (storagePath.startsWith('gdrive://')) {
      final fileId = storagePath.replaceFirst('gdrive://', '');
      return _provider.getGoogleDrivePreviewUrl(fileId, download: download);
    }
    return await _provider.createSignedUrl(
      storagePath: storagePath,
      expiresInSeconds: 600,
      download: download,
    );
  }

  /// Downloads file binary bytes via API.
  Future<Uint8List> downloadFileBytes(String storagePath) async {
    return await _provider.downloadFileBytes(storagePath);
  }

  /// Toggles favorite status for a document.
  Future<bool> toggleFavorite(String documentId, bool currentlyFavorite) async {
    final user = _provider.currentUser;
    if (user == null) return false;
    AppLogger.debug(
      'DASHBOARD_DATASET',
      'toggleFavorite doc: $documentId, currentlyFav: $currentlyFavorite',
    );

    try {
      if (currentlyFavorite) {
        await _client.from('document_favorites').delete().match({
          'document_id': documentId,
          'user_id': user.id,
        });
        return false;
      } else {
        await _client.from('document_favorites').insert({
          'document_id': documentId,
          'user_id': user.id,
        });
        return true;
      }
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_DATASET',
        'Error in toggleFavorite: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Soft deletes document using RPC `soft_delete_document` with direct fallback.
  Future<void> softDeleteDocument(String documentId) async {
    final user = _provider.currentUser;
    AppLogger.debug('DASHBOARD_DATASET', 'softDeleteDocument for ID: $documentId');
    try {
      try {
        await _client.rpc('soft_delete_document', params: {
          'p_document_id': documentId,
          'p_user_id': user?.id,
        });
      } catch (rpcErr) {
        AppLogger.warning(
          'DASHBOARD_DATASET',
          'RPC soft_delete_document fallback to direct update: $rpcErr',
        );
        await _client.from('documents').update({
          'deleted_at': DateTime.now().toIso8601String(),
          'deleted_by': user?.id,
        }).eq('id', documentId);
      }

      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'moved_to_trash',
        'details': {'reason': 'Soft deleted from dashboard'},
      });
      AppLogger.info(
        'DASHBOARD_DATASET',
        'Document $documentId soft-deleted successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_DATASET',
        'Error in softDeleteDocument: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates editable document metadata.
  Future<void> updateDocumentDetails({
    required String documentId,
    required String title,
    String? description,
    String? documentNumber,
    ApplianceWarrantyModel? applianceWarranty,
  }) async {
    final user = _provider.currentUser;
    AppLogger.debug(
      'DASHBOARD_DATASET',
      'updateDocumentDetails for ID: $documentId',
    );
    try {
      await _client.from('documents').update({
        'title': title,
        'description': description,
        'document_number': documentNumber,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

      if (applianceWarranty != null) {
        final warrantyMap = applianceWarranty.toJson();
        warrantyMap['document_id'] = documentId;
        try {
          await _client.from('appliance_warranty_metadata').upsert(warrantyMap);
        } catch (tableErr) {
          AppLogger.warning(
            'DASHBOARD_DATASET',
            'Non-fatal fallback upserting warrantyMap: $tableErr. Retrying without raw items column if needed.',
          );
          final cleanMap = Map<String, dynamic>.from(warrantyMap)..remove('items');
          await _client.from('appliance_warranty_metadata').upsert(cleanMap);
        }
      }

      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'updated',
        'details': {
          'title': title,
          'document_number': documentNumber,
        },
      });
      AppLogger.info(
        'DASHBOARD_DATASET',
        'Document $documentId updated successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_DATASET',
        'Error in updateDocumentDetails: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
