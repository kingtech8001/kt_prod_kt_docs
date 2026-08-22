import 'package:kt_prod_kt_docs/app/data/models/folder_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';

class FolderRepository {
  final SupabaseProvider _provider;

  FolderRepository(this._provider);

  Future<List<FolderModel>> getFolders({String? parentId}) async {
    AppLogger.debug('FOLDER_REPO', 'getFolders parentId: $parentId');
    try {
      var query = _provider.client
          .from('folders')
          .select('*, documents(id)');

      if (parentId != null) {
        query = query.eq('parent_id', parentId);
      }

      final response = await query.order('name', ascending: true);
      final list = (response as List)
          .map((json) => FolderModel.fromJson(json as Map<String, dynamic>))
          .toList();
      AppLogger.info('FOLDER_REPO', 'Loaded ${list.length} folders.');
      return list;
    } catch (e, st) {
      AppLogger.error('FOLDER_REPO', 'Error in getFolders: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<FolderModel> createFolder({
    required String name,
    String? description,
    String? parentId,
    String? color,
  }) async {
    final user = _provider.currentUser;
    AppLogger.info('FOLDER_REPO', 'Creating folder "$name" for user: ${user?.id}');
    try {
      final response = await _provider.client
          .from('folders')
          .insert({
            'name': name,
            'description': description,
            'parent_id': parentId,
            'color': color ?? '#64748B',
            'created_by': user?.id,
          })
          .select()
          .single();

      return FolderModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('FOLDER_REPO', 'Error creating folder: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteFolder(String folderId) async {
    AppLogger.debug('FOLDER_REPO', 'Deleting folder ID: $folderId');
    try {
      await _provider.client.from('folders').delete().eq('id', folderId);
      AppLogger.info('FOLDER_REPO', 'Folder $folderId deleted.');
    } catch (e, st) {
      AppLogger.error('FOLDER_REPO', 'Error deleting folder: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}
