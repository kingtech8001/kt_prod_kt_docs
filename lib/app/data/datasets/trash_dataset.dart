import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrashDataResponse {
  final List<DocumentModel> documents;
  final int totalCount;

  const TrashDataResponse({
    required this.documents,
    required this.totalCount,
  });
}

/// Dataset responsible for Trash Bin operations with server-side pagination.
/// Strictly conforms to the 3-tier architecture: View -> Controller -> Dataset -> Supabase.
class TrashDataset {
  final SupabaseProvider _provider;

  TrashDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches paginated soft-deleted documents with exact count.
  Future<TrashDataResponse> getTrashDocuments({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    if (DemoDataService.isDemoMode) {
      final mockTrash = [
        DocumentModel(
          id: 'trash-demo-1',
          title: 'Old Equipment AMC Contract 2023',
          description: 'Expired contract for decommissioned server room AC.',
          categoryId: 'cat-3',
          categoryName: 'Appliance & Warranty',
          categoryCode: 'APPLIANCE_WARRANTY',
          subCategory: 'Air Conditioner',
          fileName: 'old_ac_contract_2023.pdf',
          filePath: 'appliance_warranty/old_ac_contract_2023.pdf',
          fileType: 'pdf',
          mimeType: 'application/pdf',
          fileSize: 1048576,
          documentNumber: 'AMC-2023-991',
          status: 'inactive',
          deletedAt: DateTime.now().subtract(const Duration(days: 4)),
          createdAt: DateTime.now().subtract(const Duration(days: 400)),
          updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ];
      return TrashDataResponse(documents: mockTrash, totalCount: mockTrash.length);
    }
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    AppLogger.debug('TRASH_DATASET', 'Fetching trash page $page (range: $from-$to, search: $searchQuery)...');

    try {
      var query = _client
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
            vehicle_document_metadata(*),
            document_favorites(document_id, user_id)
          ''')
          .not('deleted_at', 'is', null);

      var countQuery = _client
          .from('documents')
          .select('id')
          .not('deleted_at', 'is', null);

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        final filter =
            'title.ilike.%$q%,document_number.ilike.%$q%,file_name.ilike.%$q%,sub_category.ilike.%$q%';
        query = query.or(filter);
        countQuery = countQuery.or(filter);
      }

      final countRes = await countQuery.count(CountOption.exact);

      final response = await query
          .order('deleted_at', ascending: false)
          .range(from, to);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final total = countRes.count;

      AppLogger.info(
        'TRASH_DATASET',
        'Fetched ${list.length} documents on page $page (total in trash: $total)',
      );

      return TrashDataResponse(documents: list, totalCount: total);
    } catch (e, st) {
      AppLogger.error(
        'TRASH_DATASET',
        'Error fetching trash documents: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Restores a document from trash via RPC `restore_document` with fallback.
  Future<void> restoreDocument(String documentId) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('TRASH_DATASET', 'Demo Mode: Restored document $documentId');
      return;
    }
    final user = _provider.currentUser;
    AppLogger.debug('TRASH_DATASET', 'Restoring document ID: $documentId');

    try {
      try {
        await _client.rpc('restore_document', params: {
          'p_doc_id': documentId,
        });
      } catch (rpcErr) {
        AppLogger.warning(
          'TRASH_DATASET',
          'RPC restore_document fallback to direct update: $rpcErr',
        );
        await _client.from('documents').update({
          'deleted_at': null,
          'deleted_by': null,
        }).eq('id', documentId);

        await _client.from('document_activity_logs').insert({
          'document_id': documentId,
          'user_id': user?.id,
          'action': 'restored',
          'details': {'reason': 'Restored from trash bin'},
        });
      }

      AppLogger.info(
        'TRASH_DATASET',
        'Document $documentId restored successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'TRASH_DATASET',
        'Error restoring document: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Permanently deletes a document via RPC `permanent_delete_document` with fallback and storage cleanup.
  Future<void> permanentDeleteDocument(
    String documentId,
    String filePath,
  ) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('TRASH_DATASET', 'Demo Mode: Permanently deleted document $documentId');
      return;
    }
    final user = _provider.currentUser;
    AppLogger.debug(
      'TRASH_DATASET',
      'Permanently deleting doc ID: $documentId, path: $filePath',
    );

    try {
      // 1. Storage file deletion
      try {
        await _client.storage
            .from(AppConstants.storageBucket)
            .remove([filePath]);
      } catch (storageErr) {
        AppLogger.warning(
          'TRASH_DATASET',
          'Storage file remove warning (non-fatal): $storageErr',
        );
      }

      // 2. Database permanent delete
      try {
        await _client.rpc('permanent_delete_document', params: {
          'p_doc_id': documentId,
        });
      } catch (rpcErr) {
        AppLogger.warning(
          'TRASH_DATASET',
          'RPC permanent_delete_document fallback to direct delete: $rpcErr',
        );
        await _client.from('documents').delete().eq('id', documentId);

        // Activity audit trail on fallback
        await _client.from('document_activity_logs').insert({
          'document_id': null,
          'user_id': user?.id,
          'action': 'permanently_deleted',
          'details': {
            'deleted_doc_id': documentId,
            'file_path': filePath,
            'fallback': true,
          },
        });
      }

      AppLogger.info(
        'TRASH_DATASET',
        'Document $documentId permanently purged from vault.',
      );
    } catch (e, st) {
      AppLogger.error(
        'TRASH_DATASET',
        'Error permanently deleting document: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
