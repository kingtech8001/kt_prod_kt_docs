import 'package:kt_prod_kt_docs/app/data/datasets/folder_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/folder_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';

class FolderRepository {
  final FolderDataset _dataset;

  FolderRepository(SupabaseProvider provider) : _dataset = FolderDataset(provider);

  Future<List<FolderModel>> getFolders({String? parentId}) =>
      _dataset.getFolders(parentId: parentId);

  Future<FolderModel> createFolder({
    required String name,
    String? description,
    String? parentId,
    String? color,
  }) =>
      _dataset.createFolder(
        name: name,
        description: description,
        parentId: parentId,
        color: color,
      );

  Future<void> deleteFolder(String folderId) => _dataset.deleteFolder(folderId);
}
