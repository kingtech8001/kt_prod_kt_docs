import 'package:kt_prod_kt_docs/app/data/models/activity_log_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';

class ActivityRepository {
  final SupabaseProvider _provider;

  ActivityRepository(this._provider);

  Future<List<ActivityLogModel>> getRecentActivities({
    int limit = 50,
    String? documentId,
  }) async {
    AppLogger.debug('ACTIVITY_REPO', 'getRecentActivities limit: $limit, docId: $documentId');
    try {
      var query = _provider.client
          .from('document_activity_logs')
          .select('*, profiles:user_id(full_name, email), documents:document_id(title)');

      if (documentId != null) {
        query = query.eq('document_id', documentId);
      }

      final response = await query.order('created_at', ascending: false).limit(limit);
      final list = (response as List)
          .map((json) => ActivityLogModel.fromJson(json as Map<String, dynamic>))
          .toList();
      AppLogger.info('ACTIVITY_REPO', 'Loaded ${list.length} activity log records.');
      return list;
    } catch (e, st) {
      AppLogger.error('ACTIVITY_REPO', 'Error in getRecentActivities: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> logActivity({
    String? documentId,
    required String action,
    Map<String, dynamic> details = const {},
  }) async {
    final user = _provider.currentUser;
    AppLogger.debug('ACTIVITY_REPO', 'logActivity action: $action, docId: $documentId');
    try {
      await _provider.client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': action,
        'details': details,
      });
    } catch (e, st) {
      AppLogger.warning('ACTIVITY_REPO', 'Non-fatal error logging activity: $e ($st)');
    }
  }
}
