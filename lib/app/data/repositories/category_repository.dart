import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';

class CategoryRepository {
  final SupabaseProvider _provider;

  CategoryRepository(this._provider);

  Future<List<CategoryModel>> getAllCategories() async {
    AppLogger.debug('CATEGORY_REPO', 'Fetching all document categories...');
    try {
      final response = await _provider.client
          .from('document_categories')
          .select()
          .order('name', ascending: true);

      final list = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      AppLogger.info('CATEGORY_REPO', 'Fetched ${list.length} categories.');
      return list;
    } catch (e, st) {
      AppLogger.error('CATEGORY_REPO', 'Error fetching categories: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}
