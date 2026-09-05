import 'package:kt_prod_kt_docs/app/data/models/activity_log_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityLogsResponse {
  final List<ActivityLogModel> logs;
  final int totalCount;

  const ActivityLogsResponse({
    required this.logs,
    required this.totalCount,
  });
}

/// Dataset responsible for Activity & Audit Logs data operations.
/// Strictly conforms to 3-tier architecture: View -> Controller -> Dataset -> Supabase.
class ActivityLogsDataset {
  final SupabaseProvider _provider;

  ActivityLogsDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches paginated activity log events with optional action filter and text search.
  Future<ActivityLogsResponse> getActivityLogs({
    int page = 1,
    int pageSize = 25,
    String? actionFilter,
    String? searchQuery,
    String? documentId,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    AppLogger.debug(
      'ACTIVITY_DATASET',
      'Fetching activity logs: page $page, pageSize $pageSize (range $from to $to), action: $actionFilter',
    );

    try {
      var query = _client.from('document_activity_logs').select('''
        id,
        document_id,
        user_id,
        action,
        details,
        created_at,
        profiles:user_id (
          full_name,
          email
        ),
        documents:document_id (
          title
        )
      ''');

      var countQuery = _client.from('document_activity_logs').select('id');

      if (documentId != null && documentId.isNotEmpty) {
        query = query.eq('document_id', documentId);
        countQuery = countQuery.eq('document_id', documentId);
      }

      if (actionFilter != null && actionFilter.isNotEmpty && actionFilter != 'all') {
        query = query.eq('action', actionFilter);
        countQuery = countQuery.eq('action', actionFilter);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        final filter = 'action.ilike.%$q%';
        query = query.or(filter);
        countQuery = countQuery.or(filter);
      }

      final countRes = await countQuery.count(CountOption.exact);

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final list = (response as List)
          .map((json) => ActivityLogModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final total = countRes.count;

      AppLogger.info(
        'ACTIVITY_DATASET',
        'Fetched ${list.length} activity logs on page $page (total: $total)',
      );

      return ActivityLogsResponse(logs: list, totalCount: total);
    } catch (e, st) {
      AppLogger.error(
        'ACTIVITY_DATASET',
        'Error fetching activity logs: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Logs a new audit activity event.
  Future<void> logActivity({
    String? documentId,
    required String action,
    Map<String, dynamic> details = const {},
  }) async {
    final user = _provider.currentUser;
    AppLogger.debug('ACTIVITY_DATASET', 'logActivity action: $action, docId: $documentId');
    try {
      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': action,
        'details': details,
      });
    } catch (e, st) {
      AppLogger.warning('ACTIVITY_DATASET', 'Non-fatal error logging activity: $e ($st)');
    }
  }
}
