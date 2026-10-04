import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/folder_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dataset responsible for Folder Explorer operations.
/// Follows strict 3-tier architecture: View -> Controller -> Dataset -> Supabase.
class FolderDataset {
  final SupabaseProvider _provider;

  FolderDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches all folders with accurate document counts.
  Future<List<FolderModel>> getFolders({String? parentId, String? searchQuery}) async {
    if (DemoDataService.isDemoMode) {
      var list = DemoDataService.getFolders();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        list = list.where((f) => f.name.toLowerCase().contains(q) || (f.description?.toLowerCase().contains(q) ?? false)).toList();
      }
      return list;
    }
    AppLogger.debug('FOLDER_DATASET', 'Fetching folders (parentId: $parentId, search: $searchQuery)...');
    try {
      var query = _client.from('folders').select('*, documents(id, deleted_at)');

      if (parentId != null) {
        query = query.eq('parent_id', parentId);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('name.ilike.%$q%,description.ilike.%$q%');
      }

      final response = await query.order('name', ascending: true);
      final list = (response as List)
          .map((json) => FolderModel.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('FOLDER_DATASET', 'Loaded ${list.length} folders successfully.');
      return list;
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error in getFolders: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetches single folder details by ID.
  Future<FolderModel?> getFolderById(String id) async {
    if (DemoDataService.isDemoMode) {
      final folders = DemoDataService.getFolders();
      try {
        return folders.firstWhere((f) => f.id == id);
      } catch (_) {
        return folders.isNotEmpty ? folders.first : null;
      }
    }
    AppLogger.debug('FOLDER_DATASET', 'Fetching folder ID: $id');
    try {
      final response = await _client
          .from('folders')
          .select('*, documents(id, deleted_at)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return FolderModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error in getFolderById: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetches all active documents inside a specific folder with full relations.
  Future<List<DocumentModel>> getFolderDocuments(String folderId, {String? searchQuery}) async {
    if (DemoDataService.isDemoMode) {
      var list = DemoDataService.getAllDocuments().where((d) => d.folderId == folderId).toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        list = list.where((d) =>
          d.title.toLowerCase().contains(q) ||
          d.subCategory.toLowerCase().contains(q) ||
          (d.documentNumber?.toLowerCase().contains(q) ?? false)
        ).toList();
      }
      return list;
    }
    AppLogger.debug('FOLDER_DATASET', 'Fetching documents for folder: $folderId (search: $searchQuery)');
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
            document_favorites(document_id, user_id)
          ''')
          .eq('folder_id', folderId)
          .isFilter('deleted_at', null);

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('title.ilike.%$q%,document_number.ilike.%$q%,file_name.ilike.%$q%');
      }

      final response = await query.order('created_at', ascending: false);
      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('FOLDER_DATASET', 'Loaded ${list.length} documents for folder $folderId.');
      return list;
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error in getFolderDocuments: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetches active documents not currently assigned to this folder.
  Future<List<DocumentModel>> getAvailableDocumentsForFolder(String folderId) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getAllDocuments().where((d) => d.folderId != folderId).toList();
    }
    AppLogger.debug('FOLDER_DATASET', 'Fetching available documents to add to folder $folderId');
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
          .neq('folder_id', folderId)
          .order('created_at', ascending: false)
          .limit(100);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error in getAvailableDocumentsForFolder: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Creates a new folder.
  Future<FolderModel> createFolder({
    required String name,
    String? description,
    String? parentId,
    String? color,
  }) async {
    if (DemoDataService.isDemoMode) {
      return FolderModel(
        id: 'folder-demo-${name.toLowerCase().replaceAll(' ', '-')}',
        name: name,
        description: description,
        parentId: parentId,
        color: color ?? '#3B82F6',
        createdAt: DateTime.now(),
        documentCount: 0,
      );
    }
    final user = _provider.currentUser;
    AppLogger.info('FOLDER_DATASET', 'Creating folder "$name" for user: ${user?.id}');
    try {
      final response = await _client
          .from('folders')
          .insert({
            'name': name,
            'description': description,
            'parent_id': parentId,
            'color': color ?? '#3B82F6',
            'created_by': user?.id,
          })
          .select()
          .single();

      return FolderModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error creating folder: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates existing folder details.
  Future<FolderModel> updateFolder({
    required String id,
    required String name,
    String? description,
    String? color,
  }) async {
    if (DemoDataService.isDemoMode) {
      return FolderModel(
        id: id,
        name: name,
        description: description,
        color: color ?? '#3B82F6',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        documentCount: 2,
      );
    }
    AppLogger.info('FOLDER_DATASET', 'Updating folder "$id" -> "$name"');
    try {
      final response = await _client
          .from('folders')
          .update({
            'name': name,
            'description': description,
            'color': color ?? '#3B82F6',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return FolderModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error updating folder: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a folder (DB FK SET NULL automatically unlinks documents without deleting them).
  Future<void> deleteFolder(String folderId) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('FOLDER_DATASET', 'Deleting folder ID: $folderId');
    try {
      await _client.from('folders').delete().eq('id', folderId);
      AppLogger.info('FOLDER_DATASET', 'Folder $folderId deleted successfully.');
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error deleting folder: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Assigns one or more documents to a folder.
  Future<void> addDocumentsToFolder({
    required String folderId,
    required List<String> documentIds,
  }) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('FOLDER_DATASET', 'Adding ${documentIds.length} documents to folder $folderId');
    try {
      await _client
          .from('documents')
          .update({
            'folder_id': folderId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', documentIds);

      AppLogger.info('FOLDER_DATASET', 'Successfully added ${documentIds.length} documents to folder $folderId.');
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error adding documents to folder: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Unlinks a document from its folder.
  Future<void> removeDocumentFromFolder(String documentId) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('FOLDER_DATASET', 'Removing document $documentId from folder');
    try {
      await _client.from('documents').update({
        'folder_id': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

      AppLogger.info('FOLDER_DATASET', 'Document $documentId removed from folder.');
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error removing document from folder: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Obtains signed preview URL for viewing or downloading.
  Future<String> getSignedPreviewUrl(String storagePath, {bool download = false}) async {
    if (DemoDataService.isDemoMode) {
      return 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?auto=format&fit=crop&w=1200&q=80';
    }
    return await _provider.createSignedUrl(
      storagePath: storagePath,
      expiresInSeconds: 3600,
      download: download,
    );
  }

  /// Downloads file binary bytes via API.
  Future<Uint8List> downloadFileBytes(String storagePath) async {
    if (DemoDataService.isDemoMode) {
      return Uint8List(0);
    }
    return await _provider.downloadFileBytes(storagePath);
  }

  /// Toggles favorite status for a document.
  Future<bool> toggleFavorite(String documentId, bool currentlyFavorite) async {
    if (DemoDataService.isDemoMode) {
      return !currentlyFavorite;
    }
    final user = _provider.currentUser;
    if (user == null) return false;
    AppLogger.debug('FOLDER_DATASET', 'toggleFavorite doc: $documentId, currentlyFav: $currentlyFavorite');
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
      AppLogger.error('FOLDER_DATASET', 'Error in toggleFavorite: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Soft deletes document using RPC `soft_delete_document` with fallback.
  Future<void> softDeleteDocument(String documentId) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('FOLDER_DATASET', 'Demo Mode: Soft deleted document $documentId');
      return;
    }
    final user = _provider.currentUser;
    AppLogger.debug('FOLDER_DATASET', 'softDeleteDocument for ID: $documentId');
    try {
      try {
        await _client.rpc('soft_delete_document', params: {
          'p_document_id': documentId,
          'p_user_id': user?.id,
        });
      } catch (rpcErr) {
        AppLogger.warning('FOLDER_DATASET', 'RPC soft_delete_document fallback: $rpcErr');
        await _client.from('documents').update({
          'deleted_at': DateTime.now().toIso8601String(),
          'deleted_by': user?.id,
        }).eq('id', documentId);
      }

      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'moved_to_trash',
        'details': {'reason': 'Soft deleted from folder view'},
      });
      AppLogger.info('FOLDER_DATASET', 'Document $documentId soft-deleted successfully.');
    } catch (e, st) {
      AppLogger.error('FOLDER_DATASET', 'Error in softDeleteDocument: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}
