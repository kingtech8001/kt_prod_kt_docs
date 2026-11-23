import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/datasets/documents_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
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
  Future<List<MasterBrandModel>> getMasterBrands({
    bool activeOnly = true,
  }) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getBrands();
    }
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
          .map(
            (json) => MasterBrandModel.fromJson(json as Map<String, dynamic>),
          )
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
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getApplianceSubcategories();
    }
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
    } catch (error, stackTrace) {
      AppLogger.error(
        'APPLIANCE_VAULT_DATASET',
        'Operation failed; applying fallback.',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
    if (DemoDataService.isDemoMode) {
      var list = DemoDataService.getAllDocuments()
          .where(
            (d) =>
                d.categoryId == 'cat-3' ||
                d.categoryId == 'cat-appliance' ||
                d.categoryCode == 'appliance_warranty' ||
                d.applianceWarranty != null,
          )
          .toList();

      if (brand != null && brand.isNotEmpty && brand != 'All Brands') {
        list = list
            .where(
              (d) =>
                  d.applianceWarranty?.brand.toLowerCase() ==
                      brand.toLowerCase() ||
                  (d.applianceWarranty?.items.any(
                        (i) => i.brand.toLowerCase() == brand.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }
      if (subCategory != null &&
          subCategory.isNotEmpty &&
          subCategory != 'All Appliances') {
        list = list
            .where(
              (d) => d.subCategory.toLowerCase() == subCategory.toLowerCase(),
            )
            .toList();
      }
      if (warrantyStatus != null &&
          warrantyStatus.isNotEmpty &&
          warrantyStatus != 'all') {
        final now = DateTime.now();
        list = list.where((d) {
          final wDate = d.applianceWarranty?.warrantyValidUpto;
          if (wDate == null) return warrantyStatus == 'no_warranty';
          if (warrantyStatus == 'expired') return wDate.isBefore(now);
          if (warrantyStatus == 'expiring_soon') {
            final diff = wDate.difference(now).inDays;
            return diff >= 0 && diff <= 30;
          }
          if (warrantyStatus == 'active') return wDate.isAfter(now);
          return true;
        }).toList();
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        list = list
            .where(
              (d) =>
                  d.title.toLowerCase().contains(q) ||
                  d.subCategory.toLowerCase().contains(q) ||
                  (d.documentNumber?.toLowerCase().contains(q) ?? false) ||
                  (d.applianceWarranty?.modelNumber?.toLowerCase().contains(
                        q,
                      ) ??
                      false) ||
                  (d.applianceWarranty?.serialNumber?.toLowerCase().contains(
                        q,
                      ) ??
                      false),
            )
            .toList();
      }

      int activeCount = 0;
      int expiringCount = 0;
      int expiredCount = 0;
      final now = DateTime.now();

      for (final d in list) {
        final wDate = d.applianceWarranty?.warrantyValidUpto;
        if (wDate != null) {
          if (wDate.isBefore(now)) {
            expiredCount++;
          } else {
            activeCount++;
            final diff = wDate.difference(now).inDays;
            if (diff >= 0 && diff <= 30) {
              expiringCount++;
            }
          }
        }
      }

      return ApplianceVaultResponse(
        documents: list,
        totalCount: list.length,
        totalAppliancesCount: list.length,
        activeWarrantiesCount: activeCount,
        expiringSoonCount: expiringCount,
        expiredCount: expiredCount,
      );
    }
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
          countQuery = countQuery.eq(
            'id',
            '00000000-0000-0000-0000-000000000000',
          );
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
        var metaQuery = _client
            .from('appliance_warranty_metadata')
            .select('document_id');
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
          countQuery = countQuery.eq(
            'id',
            '00000000-0000-0000-0000-000000000000',
          );
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
          .select(
            'warranty_valid_upto, warranty_status, warranty_period_months',
          );

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
    if (DemoDataService.isDemoMode) {
      AppLogger.info(
        'APPLIANCE_DATASET',
        'Demo Mode: Soft deleted invoice $documentId',
      );
      return;
    }
    AppLogger.info(
      'APPLIANCE_DATASET',
      'Soft deleting appliance invoice: $documentId...',
    );
    try {
      final userId = _client.auth.currentUser?.id;
      try {
        await _client.rpc(
          'soft_delete_document',
          params: {'p_doc_id': documentId},
        );
      } catch (rpcErr) {
        AppLogger.warning(
          'APPLIANCE_DATASET',
          'RPC soft_delete_document fallback: $rpcErr',
        );
        await _client
            .from('documents')
            .update({
              'deleted_at': DateTime.now().toIso8601String(),
              'deleted_by': userId,
            })
            .eq('id', documentId);
        await _client.from('document_activity_logs').insert({
          'document_id': documentId,
          'user_id': userId,
          'action': 'moved_to_trash',
          'details': {'reason': 'Soft deleted from appliance vault'},
        });
      }
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
    VehicleDocumentMetadataModel? vehicleMetadata,
    String? newFileName,
    Uint8List? newFileBytes,
    String? newMimeType,
    String? categoryCode,
    String? subCategory,
    String? attachmentUrl,
  }) async {
    final docsDataset = DocumentsDataset(_provider);
    await docsDataset.updateDocumentDetails(
      documentId: documentId,
      title: title,
      description: description,
      documentNumber: documentNumber,
      applianceWarranty: applianceWarranty,
      vehicleMetadata: vehicleMetadata,
      newFileName: newFileName,
      newFileBytes: newFileBytes,
      newMimeType: newMimeType,
      categoryCode: categoryCode,
      subCategory: subCategory,
      attachmentUrl: attachmentUrl,
    );
  }

  /// Generates a signed preview URL for downloading or displaying.
  Future<String> getSignedPreviewUrl(
    String filePath, {
    bool download = false,
  }) async {
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
    if (DemoDataService.isDemoMode) {
      return Uint8List(0);
    }
    return await _provider.downloadFileBytes(filePath);
  }

  /// Generates a shareable token for an appliance document.
  Future<String> createShareLink(String documentId) async {
    if (DemoDataService.isDemoMode) {
      return 'demo-appliance-share-link';
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
        'APPLIANCE_DATASET',
        'Error generating share token: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Renews or logs an extended warranty / AMC / service contract for an appliance document.
  Future<DocumentModel> renewApplianceWarranty({
    required DocumentModel previousDocument,
    required ApplianceWarrantyModel newWarranty,
    required String newTitle,
    required Uint8List fileBytes,
    required String fileName,
    String? newDescription,
  }) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.renewApplianceWarrantyMock(
        previousDoc: previousDocument,
        newWarranty: newWarranty,
        newTitle: newTitle,
        newFileName: fileName,
        newFileSize: fileBytes.length,
        newMimeType: fileName.toLowerCase().endsWith('.pdf')
            ? 'application/pdf'
            : 'image/jpeg',
        newFilePath: 'mock/$fileName',
        newDescription: newDescription,
      );
    }

    AppLogger.info(
      'APPLIANCE_DATASET',
      'Renewing appliance warranty / AMC: ${previousDocument.id} ("${previousDocument.title}")...',
    );

    try {
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'pdf';
      final mimeType = ext == 'pdf'
          ? 'application/pdf'
          : 'application/octet-stream';
      final storagePath =
          'appliances/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // 1. Upload new warranty / AMC document binary
      await _client.storage
          .from(AppConstants.storageBucket)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Prepare next renewal count and extra attributes
      final nextRenewalCount =
          (previousDocument.applianceWarranty?.renewalCount ?? 0) + 1;

      final extraAttrs = <String, dynamic>{
        'storage_provider': 'supabase',
        'previous_document_id': previousDocument.id,
        'renewal_count': nextRenewalCount,
        'warranty_type': newWarranty.warrantyType,
      };
      if (newWarranty.policyNumber != null) {
        extraAttrs['policy_number'] = newWarranty.policyNumber;
      }
      if (newWarranty.amcProvider != null) {
        extraAttrs['amc_provider'] = newWarranty.amcProvider;
      }
      if (newWarranty.renewalAmount != null) {
        extraAttrs['renewal_amount'] = newWarranty.renewalAmount;
      }
      if (newWarranty.renewalNotes != null) {
        extraAttrs['renewal_notes'] = newWarranty.renewalNotes;
      }

      final categoryId = await _getApplianceCategoryId();
      final resolvedSubCategory = previousDocument.subCategory.isNotEmpty
          ? previousDocument.subCategory
          : newWarranty.productCategory;

      final docNum =
          newWarranty.policyNumber ??
          (newWarranty.invoiceNumber.isNotEmpty
              ? newWarranty.invoiceNumber
              : previousDocument.documentNumber);

      final newDocPayload = {
        'title': newTitle,
        'description': newDescription ?? previousDocument.description,
        'category_id': categoryId,
        'sub_category': resolvedSubCategory,
        'folder_id': previousDocument.folderId,
        'file_name': fileName,
        'file_path': storagePath,
        'file_type': ext,
        'mime_type': mimeType,
        'file_size': fileBytes.length,
        'document_number': docNum,
        'status': 'active',
        'uploaded_by': _client.auth.currentUser?.id,
        'extra_attributes': extraAttrs,
      };

      final docRes = await _client
          .from('documents')
          .insert(newDocPayload)
          .select()
          .single();
      final newDocId = docRes['id'] as String;

      // 3. Insert appliance warranty metadata
      final warrantyPayload =
          newWarranty
              .copyWith(
                documentId: newDocId,
                previousDocumentId: previousDocument.id,
                renewalCount: nextRenewalCount,
              )
              .toJson(forSupabaseTable: true)
            ..remove('id');

      try {
        await _client
            .from('appliance_warranty_metadata')
            .insert(warrantyPayload);
      } catch (err) {
        AppLogger.warning(
          'APPLIANCE_DATASET',
          'Warranty table insert fallback without items: $err',
        );
        final cleanMap = Map<String, dynamic>.from(warrantyPayload)
          ..remove('items');
        await _client.from('appliance_warranty_metadata').insert(cleanMap);
      }

      // 4. Archive previous document
      final prevExtra = Map<String, dynamic>.from(
        previousDocument.extraAttributes,
      );
      prevExtra['archived_reason'] = 'renewed';
      await _client
          .from('documents')
          .update({'status': 'archived', 'extra_attributes': prevExtra})
          .eq('id', previousDocument.id);

      // 5. Activity log
      await _client.from('document_activity_logs').insert({
        'document_id': newDocId,
        'user_id': _client.auth.currentUser?.id,
        'action': 'warranty_renewed',
        'details': {
          'previous_document_id': previousDocument.id,
          'renewal_count': nextRenewalCount,
          'warranty_type': newWarranty.warrantyType,
          'provider': newWarranty.amcProvider,
          'policy_number': newWarranty.policyNumber,
        },
      });

      // 6. Return full model
      final fullDoc = await _client
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
          .eq('id', newDocId)
          .single();

      return DocumentModel.fromJson(fullDoc);
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DATASET',
        'Error renewing appliance warranty: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches history and versions for an appliance document
  Future<List<DocumentModel>> getApplianceHistory({
    required String documentId,
    String? serialNumber,
    String? invoiceNumber,
    String? productName,
  }) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getApplianceHistoryMock(
        documentId: documentId,
        serialNumber: serialNumber,
        invoiceNumber: invoiceNumber,
        productName: productName,
      );
    }

    AppLogger.debug(
      'APPLIANCE_DATASET',
      'Fetching appliance history for docId: $documentId, serial: $serialNumber, invoice: $invoiceNumber...',
    );

    try {
      var metaQuery = _client
          .from('appliance_warranty_metadata')
          .select('document_id');

      if (serialNumber != null && serialNumber.isNotEmpty) {
        metaQuery = metaQuery.eq('serial_number', serialNumber);
      } else if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
        metaQuery = metaQuery.eq('invoice_number', invoiceNumber);
      }

      final metaRows = await metaQuery;
      final ids = (metaRows as List)
          .map((r) => r['document_id'] as String?)
          .whereType<String>()
          .toSet();
      ids.add(documentId);

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
          .inFilter('id', ids.toList())
          .order('created_at', ascending: false);

      return (response as List)
          .map((j) => DocumentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DATASET',
        'Error fetching appliance history: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }
}
