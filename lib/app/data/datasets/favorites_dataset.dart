import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FavoritesResponse {
  final List<DocumentModel> documents;
  final int totalCount;

  const FavoritesResponse({
    required this.documents,
    required this.totalCount,
  });
}

/// Dataset responsible for Starred & Favorite documents queries and actions.
/// Strictly conforms to the 3-Tier Architecture: View -> Controller -> Dataset -> Supabase.
class FavoritesDataset {
  final SupabaseProvider _provider;

  FavoritesDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches document categories for filtering favorites.
  Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await _client
          .from('document_categories')
          .select()
          .order('name', ascending: true);
      return (res as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_DATASET',
        'Error fetching categories: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Fetches paginated favorite documents for the current authenticated user.
  Future<FavoritesResponse> getFavorites({
    int page = 1,
    int pageSize = 20,
    String? categoryCode,
    String? searchQuery,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      AppLogger.warning(
        'FAVORITES_DATASET',
        'No authenticated user found for favorites query.',
      );
      return const FavoritesResponse(documents: [], totalCount: 0);
    }

    AppLogger.debug(
      'FAVORITES_DATASET',
      'Fetching favorites (page: $page, range: $from-$to, category: $categoryCode, search: $searchQuery)...',
    );

    try {
      // 1. Fetch favorite document IDs for the user
      final favRows = await _client
          .from('document_favorites')
          .select('document_id')
          .eq('user_id', userId);

      final favDocIds = (favRows as List)
          .map((r) => r['document_id'] as String?)
          .whereType<String>()
          .toList();

      if (favDocIds.isEmpty) {
        return const FavoritesResponse(documents: [], totalCount: 0);
      }

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
          .inFilter('id', favDocIds)
          .isFilter('deleted_at', null);

      var countQuery = _client
          .from('documents')
          .select('id')
          .inFilter('id', favDocIds)
          .isFilter('deleted_at', null);

      // 2. Category filter
      if (categoryCode != null &&
          categoryCode.isNotEmpty &&
          categoryCode != 'all') {
        final catRes = await _client
            .from('document_categories')
            .select('id')
            .eq('code', categoryCode)
            .maybeSingle();
        if (catRes != null && catRes['id'] != null) {
          final catId = catRes['id'] as String;
          query = query.eq('category_id', catId);
          countQuery = countQuery.eq('category_id', catId);
        }
      }

      // 3. Search query filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        final searchFilter =
            'title.ilike.%$q%,document_number.ilike.%$q%,file_name.ilike.%$q%,sub_category.ilike.%$q%';
        query = query.or(searchFilter);
        countQuery = countQuery.or(searchFilter);
      }

      // 4. Server-side pagination
      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // 5. Fetch exact count of matching records
      final countRes = await countQuery.count(CountOption.exact);
      final totalRecords = countRes.count;

      return FavoritesResponse(
        documents: list,
        totalCount: totalRecords,
      );
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_DATASET',
        'Error fetching favorites: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Toggles favorite status for a document.
  Future<bool> toggleFavorite(String documentId, bool currentFavorite) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return currentFavorite;

    try {
      if (currentFavorite) {
        await _client
            .from('document_favorites')
            .delete()
            .eq('document_id', documentId)
            .eq('user_id', userId);
        return false;
      } else {
        await _client.from('document_favorites').insert({
          'document_id': documentId,
          'user_id': userId,
        });
        return true;
      }
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_DATASET',
        'Error toggling favorite: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Soft deletes a document by setting deleted_at timestamp.
  Future<void> softDeleteDocument(String documentId) async {
    AppLogger.info(
      'FAVORITES_DATASET',
      'Soft deleting document: $documentId...',
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
        'FAVORITES_DATASET',
        'Error soft deleting document: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates document details.
  Future<void> updateDocumentDetails({
    required String documentId,
    required String title,
    String? description,
    String? documentNumber,
    dynamic applianceWarranty,
    VehicleDocumentMetadataModel? vehicleMetadata,
  }) async {
    AppLogger.info(
      'FAVORITES_DATASET',
      'Updating details for document: $documentId...',
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
            'FAVORITES_DATASET',
            'Non-fatal fallback upserting warrantyMap: $tableErr. Retrying without raw items column if needed.',
          );
          final cleanMap = Map<String, dynamic>.from(warrantyMap)..remove('items');
          await _client.from('appliance_warranty_metadata').upsert(cleanMap);
        }
      }

      if (vehicleMetadata != null) {
        final payload = vehicleMetadata.toJson()
          ..remove('id')
          ..remove('document_id');
        await _client
            .from('vehicle_document_metadata')
            .update(payload)
            .eq('document_id', documentId);
      }
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_DATASET',
        'Error updating document: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Generates a signed preview URL for downloading or displaying.
  Future<String> getSignedPreviewUrl(String filePath, {bool download = false}) async {
    try {
      if (filePath.startsWith('gdrive://')) {
        final fileId = filePath.replaceFirst('gdrive://', '');
        return _provider.getGoogleDrivePreviewUrl(fileId, download: download);
      }
      return await _provider.createSignedUrl(
        storagePath: filePath,
        expiresInSeconds: 3600,
        download: download,
      );
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_DATASET',
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

  /// Generates a shareable token for a document.
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
        'FAVORITES_DATASET',
        'Error generating share token: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
