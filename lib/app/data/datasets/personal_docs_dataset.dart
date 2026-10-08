import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PersonalDocsResponse {
  final List<DocumentModel> documents;
  final int totalCount;
  final int totalDocumentsCount;
  final int totalPersonsCoveredCount;
  final int expiringSoonCount;
  final int expiredCount;

  const PersonalDocsResponse({
    required this.documents,
    required this.totalCount,
    required this.totalDocumentsCount,
    required this.totalPersonsCoveredCount,
    required this.expiringSoonCount,
    required this.expiredCount,
  });
}

/// Dataset responsible for Personal & Identity Documents data queries and operations.
/// Strictly conforms to the 3-Tier Architecture: View -> Controller -> Dataset -> Supabase.
class PersonalDocsDataset {
  final SupabaseProvider _provider;

  PersonalDocsDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches active master persons.
  Future<List<MasterPersonModel>> getMasterPersons({bool activeOnly = true}) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getPersons();
    }
    AppLogger.debug(
      'PERSONAL_DOCS_DATASET',
      'Fetching master persons (activeOnly: $activeOnly)...',
    );
    try {
      var query = _client.from('master_persons').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('full_name', ascending: true);

      final list = (response as List)
          .map((json) => MasterPersonModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_DATASET',
        'Error fetching master persons: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Fetches active personal document types.
  Future<List<MasterPersonalDocTypeModel>> getMasterPersonalDocTypes({
    bool activeOnly = true,
  }) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getPersonalDocTypes();
    }
    AppLogger.debug(
      'PERSONAL_DOCS_DATASET',
      'Fetching master personal doc types (activeOnly: $activeOnly)...',
    );
    try {
      var query = _client.from('master_personal_doc_types').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      final list = (response as List)
          .map(
            (json) => MasterPersonalDocTypeModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_DATASET',
        'Error fetching master personal doc types: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  String? _cachedIdentityDocsCategoryId;

  Future<String> _getIdentityDocsCategoryId() async {
    if (_cachedIdentityDocsCategoryId != null) return _cachedIdentityDocsCategoryId!;
    try {
      final res = await _client
          .from('document_categories')
          .select('id')
          .eq('code', 'identity_docs')
          .maybeSingle();
      if (res != null && res['id'] != null) {
        _cachedIdentityDocsCategoryId = res['id'] as String;
      }
    } catch (_) {}
    _cachedIdentityDocsCategoryId ??= '9bed19e3-ee7d-41c3-9664-31ae69c2c423';
    return _cachedIdentityDocsCategoryId!;
  }

  /// Fetches paginated personal documents with server-side batching and aggregated summary metrics.
  Future<PersonalDocsResponse> getPersonalDocuments({
    int page = 1,
    int pageSize = 20,
    String? personName,
    String? docType,
    String? searchQuery,
  }) async {
    if (DemoDataService.isDemoMode) {
      var list = DemoDataService.getAllDocuments()
          .where((d) => d.categoryId == 'cat-4' || d.categoryId == 'cat-personal' || d.categoryCode == 'identity_docs' || d.personalMetadata != null)
          .toList();

      if (personName != null && personName.isNotEmpty && personName != 'All Persons') {
        list = list.where((d) =>
          d.personalMetadata?.personName.toLowerCase() == personName.toLowerCase()
        ).toList();
      }
      if (docType != null && docType.isNotEmpty && docType != 'All Document Types') {
        list = list.where((d) =>
          (d.personalMetadata?.docTypeName.toLowerCase() == docType.toLowerCase()) ||
          (d.subCategory.toLowerCase() == docType.toLowerCase())
        ).toList();
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        list = list.where((d) =>
          d.title.toLowerCase().contains(q) ||
          d.subCategory.toLowerCase().contains(q) ||
          (d.documentNumber?.toLowerCase().contains(q) ?? false) ||
          (d.personalMetadata?.personName.toLowerCase().contains(q) ?? false) ||
          (d.personalMetadata?.idNumber?.toLowerCase().contains(q) ?? false)
        ).toList();
      }

      final personSet = <String>{};
      int expiringCount = 0;
      int expiredCount = 0;
      final now = DateTime.now();

      for (final d in list) {
        final pName = d.personalMetadata?.personName;
        if (pName != null && pName.isNotEmpty) {
          personSet.add(pName.trim().toLowerCase());
        }
        final expDate = d.personalMetadata?.expiryDate;
        if (expDate != null) {
          if (expDate.isBefore(now)) {
            expiredCount++;
          } else {
            final diff = expDate.difference(now).inDays;
            if (diff >= 0 && diff <= 60) {
              expiringCount++;
            }
          }
        }
      }

      return PersonalDocsResponse(
        documents: list,
        totalCount: list.length,
        totalDocumentsCount: list.length,
        totalPersonsCoveredCount: personSet.length,
        expiringSoonCount: expiringCount,
        expiredCount: expiredCount,
      );
    }
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    AppLogger.debug(
      'PERSONAL_DOCS_DATASET',
      'Fetching personal documents (page: $page, range: $from-$to, person: $personName, docType: $docType, search: $searchQuery)...',
    );

    try {
      final categoryId = await _getIdentityDocsCategoryId();

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

      // 1. Person filter via metadata subquery
      if (personName != null &&
          personName.isNotEmpty &&
          personName != 'All Persons') {
        final metaRows = await _client
            .from('personal_document_metadata')
            .select('document_id')
            .ilike('person_name', '%$personName%');
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

      // 2. Document Type filter via metadata subquery or sub_category
      if (docType != null &&
          docType.isNotEmpty &&
          docType != 'All Document Types') {
        final metaRows = await _client
            .from('personal_document_metadata')
            .select('document_id')
            .ilike('doc_type_name', '%$docType%');
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

      // 3. Search query filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        final searchFilter =
            'title.ilike.%$q%,document_number.ilike.%$q%,file_name.ilike.%$q%,sub_category.ilike.%$q%';
        query = query.or(searchFilter);
        countQuery = countQuery.or(searchFilter);
      }

      // 4. Fetch paginated documents
      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      var list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Ensure personalMetadata is present
      list = list.where((d) => d.personalMetadata != null).toList();

      // 5. Fetch exact count of matching records
      final countRes = await countQuery.count(CountOption.exact);
      final totalRecords = countRes.count;

      // 6. Calculate summary metrics across all personal document records in the database
      final summaryRes = await _client
          .from('personal_document_metadata')
          .select('person_name, expiry_date');

      final personSet = <String>{};
      int expiringCount = 0;
      int expiredCount = 0;
      final now = DateTime.now();

      for (final raw in (summaryRes as List)) {
        final pName = raw['person_name'] as String?;
        if (pName != null && pName.isNotEmpty) {
          personSet.add(pName.trim().toLowerCase());
        }

        final expiryStr = raw['expiry_date'] as String?;
        if (expiryStr != null) {
          final expDate = DateTime.tryParse(expiryStr);
          if (expDate != null) {
            if (expDate.isBefore(now)) {
              expiredCount++;
            } else {
              final diff = expDate.difference(now).inDays;
              if (diff >= 0 && diff <= 60) {
                expiringCount++;
              }
            }
          }
        }
      }

      return PersonalDocsResponse(
        documents: list,
        totalCount: totalRecords,
        totalDocumentsCount: summaryRes.length,
        totalPersonsCoveredCount: personSet.length,
        expiringSoonCount: expiringCount,
        expiredCount: expiredCount,
      );
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_DATASET',
        'Error fetching personal documents: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Toggles favorite status for a document.
  Future<bool> toggleFavorite(String documentId, bool currentFavorite) async {
    if (DemoDataService.isDemoMode) {
      return !currentFavorite;
    }
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
        'PERSONAL_DOCS_DATASET',
        'Error toggling favorite: $e',
        error: e,
        stackTrace: st,
      );
      return currentFavorite;
    }
  }

  /// Soft deletes a personal document by setting deleted_at timestamp.
  Future<void> softDeleteDocument(String documentId) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('PERSONAL_DOCS_DATASET', 'Demo Mode: Soft deleted personal doc $documentId');
      return;
    }
    AppLogger.info(
      'PERSONAL_DOCS_DATASET',
      'Soft deleting personal document: $documentId...',
    );
    try {
      final userId = _client.auth.currentUser?.id;
      try {
        await _client.rpc(
          'soft_delete_document',
          params: {
            'p_doc_id': documentId,
          },
        );
      } catch (rpcErr) {
        AppLogger.warning('PERSONAL_DOCS_DATASET', 'RPC soft_delete_document fallback: $rpcErr');
        await _client.from('documents').update({
          'deleted_at': DateTime.now().toIso8601String(),
          'deleted_by': userId,
        }).eq('id', documentId);
        await _client.from('document_activity_logs').insert({
          'document_id': documentId,
          'user_id': userId,
          'action': 'moved_to_trash',
          'details': {'reason': 'Soft deleted from personal docs'},
        });
      }
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_DATASET',
        'Error soft deleting personal document: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Generates a signed preview URL for viewing or downloading.
  Future<String> getSignedPreviewUrl(String filePath, {bool download = false}) async {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    if (filePath.startsWith('gdrive://')) {
      final fileId = filePath.replaceFirst('gdrive://', '').trim();
      return 'https://drive.google.com/file/d/$fileId/view?usp=sharing';
    }
    if (DemoDataService.isDemoMode) {
      return 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?auto=format&fit=crop&w=1200&q=80';
    }
    try {
      return await _provider.createSignedUrl(
        storagePath: filePath,
        expiresInSeconds: 3600,
        download: download,
      );
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_DATASET',
        'Error generating signed URL: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Downloads file binary bytes via API.
  Future<Uint8List> downloadFileBytes(String filePath) async {
    if (DemoDataService.isDemoMode) {
      return Uint8List(0);
    }
    return await _provider.downloadFileBytes(filePath);
  }

  /// Generates a shareable token for a document.
  Future<String> createShareLink(String documentId) async {
    if (DemoDataService.isDemoMode) {
      return 'demo-personal-share-token';
    }
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
        'PERSONAL_DOCS_DATASET',
        'Error generating share token: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
