import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/dashboard_metrics_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardBundleModel {
  final DashboardMetricsModel metrics;
  final List<DocumentModel> recentDocuments;
  final List<DocumentModel> expiringWarranties;
  final List<DocumentModel> pendingUtilityBills;

  DashboardBundleModel({
    required this.metrics,
    required this.recentDocuments,
    required this.expiringWarranties,
    required this.pendingUtilityBills,
  });
}

/// Dataset responsible for all Home / Dashboard data operations.
/// Follows the strict 3-tier architecture: View -> Controller -> Dataset -> Supabase.
class DashboardDataset {
  final SupabaseProvider _provider;

  DashboardDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches complete dashboard data bundle via single database RPC `get_dashboard_bundle` in ~20ms.
  Future<DashboardBundleModel> getDashboardBundle() async {
    AppLogger.debug(
      'DASHBOARD_DATASET',
      'Fetching complete dashboard bundle via RPC get_dashboard_bundle...',
    );
    try {
      final response = await _client.rpc('get_dashboard_bundle');
      if (response != null && response is Map<String, dynamic>) {
        final metrics = DashboardMetricsModel.fromJson(
          (response['metrics'] as Map<String, dynamic>?) ?? {},
        );
        final recent = ((response['recent_documents'] as List?) ?? [])
            .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final expiring = ((response['expiring_warranties'] as List?) ?? [])
            .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final pending = ((response['pending_utility_bills'] as List?) ?? [])
            .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
            .toList();

        AppLogger.info('DASHBOARD_DATASET', 'Loaded complete dashboard bundle in single RPC trip.');
        return DashboardBundleModel(
          metrics: metrics,
          recentDocuments: recent,
          expiringWarranties: expiring,
          pendingUtilityBills: pending,
        );
      }
    } catch (e) {
      AppLogger.warning(
        'DASHBOARD_DATASET',
        'Single RPC get_dashboard_bundle fallback due to: $e',
      );
    }

    // High-performance fallback: fetch in parallel
    final results = await Future.wait([
      getDashboardMetrics(),
      getRecentDocuments(limit: 8),
      getExpiringWarranties(limit: 4),
      getPendingUtilityBills(limit: 4),
    ]);

    return DashboardBundleModel(
      metrics: results[0] as DashboardMetricsModel,
      recentDocuments: results[1] as List<DocumentModel>,
      expiringWarranties: results[2] as List<DocumentModel>,
      pendingUtilityBills: results[3] as List<DocumentModel>,
    );
  }

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

  /// Fetches recent non-deleted documents with necessary relations.
  Future<List<DocumentModel>> getRecentDocuments({int limit = 8}) async {
    AppLogger.debug('DASHBOARD_DATASET', 'Fetching recent documents limit: $limit');
    try {
      final response = await _client
          .from('documents')
          .select('''
            *,
            document_categories(id, name, code, color_hex, icon),
            folders(id, name),
            document_addresses(*),
            utility_metadata(*),
            appliance_warranty_metadata(*),
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

  /// Fetches warranties expiring within 30 days using indexed query.
  Future<List<DocumentModel>> getExpiringWarranties({int limit = 4}) async {
    AppLogger.debug('DASHBOARD_DATASET', 'Fetching expiring warranties...');
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final in30Days = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String()
          .split('T')
          .first;

      final metaRows = await _client
          .from('appliance_warranty_metadata')
          .select('document_id')
          .gte('warranty_valid_upto', today)
          .lte('warranty_valid_upto', in30Days)
          .neq('warranty_status', 'no_warranty')
          .limit(limit);

      final ids = (metaRows as List)
          .map((r) => r['document_id'] as String?)
          .whereType<String>()
          .toList();

      if (ids.isEmpty) {
        return [];
      }

      final response = await _client
          .from('documents')
          .select('''
            *,
            document_categories(id, name, code, color_hex, icon),
            appliance_warranty_metadata(*)
          ''')
          .inFilter('id', ids)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
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
      return [];
    }
  }

  /// Fetches pending utility bills using indexed query.
  Future<List<DocumentModel>> getPendingUtilityBills({int limit = 4}) async {
    AppLogger.debug('DASHBOARD_DATASET', 'Fetching pending utility bills...');
    try {
      final metaRows = await _client
          .from('utility_metadata')
          .select('document_id')
          .neq('payment_status', 'paid')
          .neq('payment_status', 'auto_debit')
          .limit(limit);

      final ids = (metaRows as List)
          .map((r) => r['document_id'] as String?)
          .whereType<String>()
          .toList();

      if (ids.isEmpty) {
        return [];
      }

      final response = await _client
          .from('documents')
          .select('''
            *,
            document_categories(id, name, code, color_hex, icon),
            document_addresses(*),
            utility_metadata(*)
          ''')
          .inFilter('id', ids)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
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
      return [];
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
