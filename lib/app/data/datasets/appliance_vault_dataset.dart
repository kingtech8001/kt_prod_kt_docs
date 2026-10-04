import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ApplianceVaultResponse {
  final List<DocumentModel> documents;
  final int totalCount;
  final int totalAppliancesCount;
  final int activeWarrantiesCount;
  final int expiringSoonCount;
  final int expiredCount;

  const ApplianceVaultResponse({
    required this.documents,
    required this.totalCount,
    required this.totalAppliancesCount,
    required this.activeWarrantiesCount,
    required this.expiringSoonCount,
    required this.expiredCount,
  });
}

/// Dataset responsible for Appliance Vault data queries and actions.
/// Strictly conforms to the 3-Tier Architecture: View -> Controller -> Dataset -> Supabase.
class ApplianceVaultDataset {
  final SupabaseProvider _provider;

  ApplianceVaultDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches active master brands.
  Future<List<MasterBrandModel>> getMasterBrands({bool activeOnly = true}) async {
    AppLogger.debug(
      'APPLIANCE_DATASET',
      'Fetching master brands (activeOnly: $activeOnly)...',
    );
    try {
      var query = _client.from('master_brands').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      final list = (response as List)
          .map((json) => MasterBrandModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DATASET',
        'Error fetching master brands: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Fetches active appliance subcategories.
  Future<List<MasterApplianceSubcategoryModel>> getApplianceSubcategories({
    bool activeOnly = true,
  }) async {
    AppLogger.debug(
      'APPLIANCE_DATASET',
      'Fetching appliance subcategories (activeOnly: $activeOnly)...',
    );
    try {
      var query = _client.from('master_appliance_subcategories').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      final list = (response as List)
          .map(
            (json) => MasterApplianceSubcategoryModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DATASET',
        'Error fetching appliance subcategories: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  String? _cachedApplianceCategoryId;

  Future<String> _getApplianceCategoryId() async {
    if (_cachedApplianceCategoryId != null) return _cachedApplianceCategoryId!;
    try {
      final res = await _client
          .from('document_categories')
          .select('id')
          .eq('code', 'appliance_warranty')
          .maybeSingle();
      if (res != null && res['id'] != null) {
        _cachedApplianceCategoryId = res['id'] as String;
      }
    } catch (_) {}
    _cachedApplianceCategoryId ??= '2b97daa0-6a1d-42e6-879f-c085e38219cc';
    return _cachedApplianceCategoryId!;
  }

  /// Fetches paginated appliance vault documents with server-side batching and aggregated summary metrics.
  Future<ApplianceVaultResponse> getApplianceVault({
    int page = 1,
    int pageSize = 20,
    String? brand,
    String? subCategory,
    String? warrantyStatus,
    String? searchQuery,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    AppLogger.debug(
      'APPLIANCE_DATASET',
      'Fetching appliance documents (page: $page, range: $from-$to, brand: $brand, subCategory: $subCategory, status: $warrantyStatus, search: $searchQuery)...',
    );

    try {
      final categoryId = await _getApplianceCategoryId();

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

      // 1. Brand filtering via metadata document IDs
      if (brand != null && brand.isNotEmpty && brand != 'All Brands') {
        final metaRows = await _client
            .from('appliance_warranty_metadata')
            .select('document_id')
            .ilike('brand', '%$brand%');
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

      // 2. Subcategory filter
      if (subCategory != null &&
          subCategory.isNotEmpty &&
          subCategory != 'All Appliances') {
        query = query.eq('sub_category', subCategory);
        countQuery = countQuery.eq('sub_category', subCategory);
      }

      // 3. Warranty status filter via metadata document IDs
      if (warrantyStatus != null &&
          warrantyStatus.isNotEmpty &&
          warrantyStatus != 'all') {
        var metaQuery =
            _client.from('appliance_warranty_metadata').select('document_id');
        final today = DateTime.now().toIso8601String().split('T').first;
        final in30Days = DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String()
            .split('T')
            .first;

        if (warrantyStatus == 'active') {
          metaQuery = metaQuery
              .gte('warranty_valid_upto', today)
              .neq('warranty_status', 'no_warranty');
        } else if (warrantyStatus == 'expiring_soon') {
          metaQuery = metaQuery
              .gte('warranty_valid_upto', today)
              .lte('warranty_valid_upto', in30Days)
              .neq('warranty_status', 'no_warranty');
        } else if (warrantyStatus == 'expired') {
          metaQuery = metaQuery
              .lt('warranty_valid_upto', today)
              .neq('warranty_status', 'no_warranty');
        } else if (warrantyStatus == 'no_warranty') {
          metaQuery = metaQuery.eq('warranty_status', 'no_warranty');
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

      // Ensure applianceWarranty is present
      list = list.where((d) => d.applianceWarranty != null).toList();

      // 6. Fetch exact count of matching records
      final countRes = await countQuery.count(CountOption.exact);
      final totalRecords = countRes.count;

      // 7. Calculate summary metrics across all available appliances in the database
      final summaryRes = await _client
          .from('appliance_warranty_metadata')
          .select('warranty_valid_upto, warranty_status, warranty_period_months');

      int totalAppliances = (summaryRes as List).length;
      int activeCount = 0;
      int expiringCount = 0;
      int expiredCount = 0;

      final now = DateTime.now();
      for (final raw in summaryRes) {
        final status = raw['warranty_status'] as String? ?? 'active';
        final period = (raw['warranty_period_months'] as num?)?.toInt() ?? 12;
        final hasWarranty = status != 'no_warranty' && period > 0;

        if (!hasWarranty) continue;

        final validUptoStr = raw['warranty_valid_upto'] as String?;
        if (validUptoStr != null) {
          final validDate = DateTime.tryParse(validUptoStr);
          if (validDate != null) {
            if (validDate.isBefore(now)) {
              expiredCount++;
            } else {
              activeCount++;
              final diff = validDate.difference(now).inDays;
              if (diff >= 0 && diff <= 30) {
                expiringCount++;
              }
            }
          }
        }
      }

      return ApplianceVaultResponse(
        documents: list,
        totalCount: totalRecords,
        totalAppliancesCount: totalAppliances,
        activeWarrantiesCount: activeCount,
        expiringSoonCount: expiringCount,
        expiredCount: expiredCount,
      );
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DATASET',
        'Error fetching appliance documents: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Soft deletes an appliance document by setting deleted_at timestamp.
  Future<void> softDeleteDocument(String documentId) async {
    AppLogger.info(
      'APPLIANCE_DATASET',
      'Soft deleting appliance invoice: $documentId...',
    );
    try {
      final userId = _client.auth.currentUser?.id;
      await _client.rpc(
        'soft_delete_document',
        params: {
          'p_document_id': documentId,
          'p_user_id': ?userId,
        },
      );
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DATASET',
        'Error soft deleting invoice: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates document details and warranty metadata.
  Future<void> updateDocumentDetails({
    required String documentId,
    required String title,
    String? description,
    String? documentNumber,
    ApplianceWarrantyModel? applianceWarranty,
  }) async {
    AppLogger.info(
      'APPLIANCE_DATASET',
      'Updating details for appliance invoice: $documentId...',
    );
    try {
      await _client
          .from('documents')
          .update({
            'title': title,
            'description': description,
            'document_number': documentNumber,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', documentId);

      if (applianceWarranty != null) {
        final warrantyMap = applianceWarranty.toJson();
        warrantyMap['document_id'] = documentId;
        try {
          await _client.from('appliance_warranty_metadata').upsert(warrantyMap);
        } catch (tableErr) {
          AppLogger.warning(
            'APPLIANCE_DATASET',
            'Non-fatal fallback upserting warrantyMap: $tableErr. Retrying without raw items column if needed.',
          );
          final cleanMap = Map<String, dynamic>.from(warrantyMap)..remove('items');
          await _client.from('appliance_warranty_metadata').upsert(cleanMap);
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DATASET',
        'Error updating appliance invoice: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Generates a signed preview URL for downloading or displaying.
  Future<String> getSignedPreviewUrl(String filePath, {bool download = false}) async {
    try {
      return await _provider.createSignedUrl(
        storagePath: filePath,
        expiresInSeconds: 3600,
        download: download,
      );
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DATASET',
        'Error generating signed URL: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Downloads file binary bytes via API.
  Future<Uint8List> downloadFileBytes(String filePath) async {
    return await _provider.downloadFileBytes(filePath);
  }

  /// Generates a shareable token for an appliance document.
  Future<String> createShareLink(String documentId) async {
    try {
      final token = const Uuid().v4().replaceAll('-', '');
      final expiresAt = DateTime.now().add(const Duration(days: 7));
      await _client.from('document_shares').insert({
        'document_id': documentId,
        'share_token': token,
        'expires_at': expiresAt.toIso8601String(),
        'created_by': _client.auth.currentUser?.id,
      });
      return token;
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DATASET',
        'Error generating share token: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
