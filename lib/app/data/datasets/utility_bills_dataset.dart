import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


class UtilityBillsResponse {
  final List<DocumentModel> documents;
  final int totalCount;
  final double totalAmount;
  final double pendingAmount;
  final int paidCount;
  final int pendingCount;

  const UtilityBillsResponse({
    required this.documents,
    required this.totalCount,
    required this.totalAmount,
    required this.pendingAmount,
    required this.paidCount,
    required this.pendingCount,
  });
}

/// Dataset responsible for Utility Bills data queries and actions.
/// Strictly conforms to the 3-Tier Architecture: View -> Controller -> Dataset -> Supabase.
class UtilityBillsDataset {
  final SupabaseProvider _provider;

  UtilityBillsDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches active cities from master data.
  Future<List<MasterCityModel>> getMasterCities({bool activeOnly = true}) async {
    AppLogger.debug(
      'UTILITY_DATASET',
      'Fetching master cities (activeOnly: $activeOnly)...',
    );
    try {
      var query = _client.from('master_cities').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      final list = (response as List)
          .map((json) => MasterCityModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_DATASET',
        'Error fetching master cities: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Fetches active utility providers.
  Future<List<MasterUtilityProviderModel>> getUtilityProviders({
    bool activeOnly = true,
  }) async {
    AppLogger.debug(
      'UTILITY_DATASET',
      'Fetching utility providers (activeOnly: $activeOnly)...',
    );
    try {
      var query = _client.from('master_utility_providers').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      final list = (response as List)
          .map(
            (json) =>
                MasterUtilityProviderModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_DATASET',
        'Error fetching utility providers: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  String? _cachedUtilityCategoryId;

  Future<String> _getUtilityCategoryId() async {
    if (_cachedUtilityCategoryId != null) return _cachedUtilityCategoryId!;
    try {
      final res = await _client
          .from('document_categories')
          .select('id')
          .eq('code', 'utility_bills')
          .maybeSingle();
      if (res != null && res['id'] != null) {
        _cachedUtilityCategoryId = res['id'] as String;
      }
    } catch (_) {}
    _cachedUtilityCategoryId ??= '2b6f8867-c5e2-4fc5-ba5e-8042845f6f6c';
    return _cachedUtilityCategoryId!;
  }

  /// Fetches paginated utility bills with server-side batching and aggregated summary metrics.
  Future<UtilityBillsResponse> getUtilityBills({
    int page = 1,
    int pageSize = 20,
    String? city,
    String? subCategory,
    String? paymentStatus,
    String? searchQuery,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    AppLogger.debug(
      'UTILITY_DATASET',
      'Fetching utility bills (page: $page, range: $from-$to, city: $city, subCategory: $subCategory, status: $paymentStatus, search: $searchQuery)...',
    );

    try {
      final categoryId = await _getUtilityCategoryId();

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
          .eq('category_id', categoryId)
          .isFilter('deleted_at', null);

      var countQuery = _client
          .from('documents')
          .select('id')
          .eq('category_id', categoryId)
          .isFilter('deleted_at', null);

      // 1. City filtering via address document IDs
      if (city != null && city.isNotEmpty && city != 'All Cities') {
        final addrRows = await _client
            .from('document_addresses')
            .select('document_id')
            .ilike('city', '%$city%');
        final ids = (addrRows as List)
            .map((r) => r['document_id'] as String?)
            .whereType<String>()
            .toList();
        if (ids.isEmpty) {
          query = query.eq('id', '00000000-0000-0000-0000-000000000000');
          countQuery =
              countQuery.eq('id', '00000000-0000-0000-0000-000000000000');
        } else {
          query = query.inFilter('id', ids);
          countQuery = countQuery.inFilter('id', ids);
        }
      }

      // 2. Subcategory filter
      if (subCategory != null &&
          subCategory.isNotEmpty &&
          subCategory != 'All Utilities') {
        query = query.eq('sub_category', subCategory);
        countQuery = countQuery.eq('sub_category', subCategory);
      }

      // 3. Payment status filter via utility_metadata document IDs
      if (paymentStatus != null &&
          paymentStatus.isNotEmpty &&
          paymentStatus != 'all') {
        var metaQuery = _client.from('utility_metadata').select('document_id');
        if (paymentStatus == 'paid') {
          metaQuery = metaQuery.eq('payment_status', 'paid');
        } else if (paymentStatus == 'pending') {
          metaQuery = metaQuery.neq('payment_status', 'paid');
        } else if (paymentStatus == 'overdue') {
          final today = DateTime.now().toIso8601String().split('T').first;
          metaQuery =
              metaQuery.neq('payment_status', 'paid').lt('due_date', today);
        }
        final metaRows = await metaQuery;
        final ids = (metaRows as List)
            .map((r) => r['document_id'] as String?)
            .whereType<String>()
            .toList();
        if (ids.isEmpty) {
          query = query.eq('id', '00000000-0000-0000-0000-000000000000');
          countQuery =
              countQuery.eq('id', '00000000-0000-0000-0000-000000000000');
        } else {
          query = query.inFilter('id', ids);
          countQuery = countQuery.inFilter('id', ids);
        }
      }

      // 4. Search query filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        final searchFilter =
            'title.ilike.%$q%,document_number.ilike.%$q%,file_name.ilike.%$q%,sub_category.ilike.%$q%';
        query = query.or(searchFilter);
        countQuery = countQuery.or(searchFilter);
      }

      // 5. Fetch paginated documents
      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      var list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Ensure utilityMetadata is present
      list = list.where((d) => d.utilityMetadata != null).toList();


      // 2. Fetch metrics summary across matching records
      final countRes = await countQuery.count(CountOption.exact);
      final totalRecords = countRes.count;

      // Calculate summary metrics across all available bills
      final summaryRes = await _client
          .from('utility_metadata')
          .select('bill_amount, payment_status, due_date');

      double totalAmt = 0.0;
      double pendingAmt = 0.0;
      int paidCnt = 0;
      int pendingCnt = 0;

      for (final raw in (summaryRes as List)) {
        final amt = (raw['bill_amount'] as num?)?.toDouble() ?? 0.0;
        final status = raw['payment_status'] as String? ?? 'pending';
        final isPaid = status == 'paid' || status == 'auto_debit';

        totalAmt += amt;
        if (isPaid) {
          paidCnt++;
        } else {
          pendingAmt += amt;
          pendingCnt++;
        }
      }

      AppLogger.info(
        'UTILITY_DATASET',
        'Returned ${list.length} utility bills on page $page (total count: $totalRecords)',
      );

      return UtilityBillsResponse(
        documents: list,
        totalCount: totalRecords,
        totalAmount: totalAmt,
        pendingAmount: pendingAmt,
        paidCount: paidCnt,
        pendingCount: pendingCnt,
      );
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_DATASET',
        'Error fetching utility bills: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates the payment status and payment date of a utility bill.
  Future<void> updatePaymentStatus({
    required String metadataId,
    required bool isPaid,
    String? paymentDate,
  }) async {
    AppLogger.debug(
      'UTILITY_DATASET',
      'Updating payment status for metadata $metadataId -> isPaid: $isPaid',
    );
    try {
      await _client.from('utility_metadata').update({
        'payment_status': isPaid ? 'paid' : 'pending',
        'payment_date': paymentDate,
      }).eq('id', metadataId);

      AppLogger.info('UTILITY_DATASET', 'Payment status updated successfully.');
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_DATASET',
        'Error updating payment status: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Soft deletes a document (moves to trash) and writes an audit log.
  Future<void> softDeleteDocument(String documentId) async {
    final user = _provider.currentUser;
    AppLogger.debug('UTILITY_DATASET', 'Moving document to trash: $documentId');
    try {
      await _client.from('documents').update({
        'deleted_at': DateTime.now().toIso8601String(),
        'deleted_by': user?.id,
      }).eq('id', documentId);

      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'moved_to_trash',
        'details': {'reason': 'User moved utility bill to trash'},
      });

      AppLogger.info('UTILITY_DATASET', 'Document moved to trash successfully.');
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_DATASET',
        'Error moving document to trash: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates editable document fields (title, description, documentNumber).
  Future<void> updateDocumentDetails({
    required String documentId,
    required String title,
    String? description,
    String? documentNumber,
  }) async {
    final user = _provider.currentUser;
    AppLogger.debug('UTILITY_DATASET', 'Updating document details: $documentId');
    try {
      await _client.from('documents').update({
        'title': title,
        'description': description,
        'document_number': documentNumber,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'edited',
        'details': {
          'updated_fields': ['title', 'description', 'document_number']
        },
      });

      AppLogger.info('UTILITY_DATASET', 'Document details updated.');
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_DATASET',
        'Error updating document details: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Obtains a signed preview URL for downloading or viewing.
  Future<String> getSignedPreviewUrl(String filePath, {bool download = false}) async {
    return await _provider.createSignedUrl(
      storagePath: filePath,
      expiresInSeconds: 3600,
      download: download,
    );
  }

  /// Downloads file binary bytes via API.
  Future<Uint8List> downloadFileBytes(String filePath) async {
    return await _provider.downloadFileBytes(filePath);
  }


  /// Creates a share link for a document.
  Future<String> createShareLink(String documentId) async {
    final user = _provider.currentUser;
    final token = const Uuid().v4();
    await _client.from('document_shares').insert({
      'document_id': documentId,
      'shared_by': user?.id,
      'share_token': token,
      'access_type': 'view',
      'expires_at':
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });
    return token;
  }
}
