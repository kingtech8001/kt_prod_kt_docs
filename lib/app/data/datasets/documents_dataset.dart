import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/address_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_metadata_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Dataset responsible for all Document Explorer data operations.
/// Strictly conforms to the 3-tier architecture: View -> Controller -> Dataset -> Supabase.
class DocumentsDataset {
  final SupabaseProvider _provider;

  DocumentsDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches all document categories ordered by name.
  Future<List<CategoryModel>> getAllCategories() async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getCategories();
    }
    AppLogger.debug('DOCUMENTS_DATASET', 'Fetching all document categories...');
    try {
      final response = await _client
          .from('document_categories')
          .select()
          .order('name', ascending: true);

      final list = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      AppLogger.info('DOCUMENTS_DATASET', 'Fetched ${list.length} categories.');
      return list;
    } catch (e, st) {
      AppLogger.error(
        'DOCUMENTS_DATASET',
        'Error fetching categories: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches active cities from master data.
  Future<List<MasterCityModel>> getCities({bool activeOnly = true}) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getCities();
    }
    AppLogger.debug(
      'DOCUMENTS_DATASET',
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
        'DOCUMENTS_DATASET',
        'Error fetching cities: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Queries documents matching filters (city, category, status, search, folder).
  Future<List<DocumentModel>> getFilteredDocuments({
    String? categoryId,
    String? folderId,
    String? city,
    String? status,
    String? searchQuery,
    int limit = 100,
    int offset = 0,
  }) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('DOCUMENTS_DATASET', 'Demo Mode: Returning filtered demo documents.');
      var list = DemoDataService.getAllDocuments();
      if (categoryId != null && categoryId.isNotEmpty) {
        list = list.where((d) => d.categoryId == categoryId).toList();
      }
      if (folderId != null && folderId.isNotEmpty) {
        list = list.where((d) => d.folderId == folderId).toList();
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        list = list.where((d) => d.status.toLowerCase() == status.toLowerCase()).toList();
      }
      if (city != null && city.isNotEmpty && city != 'All Cities') {
        list = list.where((d) => d.address?.city.toLowerCase() == city.toLowerCase()).toList();
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        list = list.where((d) =>
          d.title.toLowerCase().contains(q) ||
          d.subCategory.toLowerCase().contains(q) ||
          (d.documentNumber?.toLowerCase().contains(q) ?? false) ||
          d.fileName.toLowerCase().contains(q)
        ).toList();
      }
      return list;
    }

    AppLogger.debug('DOCUMENTS_DATASET', 'Querying documents with filters:', {
      'categoryId': categoryId,
      'folderId': folderId,
      'city': city,
      'status': status,
      'searchQuery': searchQuery,
    });

    try {
      var query = _client.from('documents').select('''
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
      ''').isFilter('deleted_at', null);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (folderId != null && folderId.isNotEmpty) {
        query = query.eq('folder_id', folderId);
      }

      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.or(
          'title.ilike.%${searchQuery.trim()}%,document_number.ilike.%${searchQuery.trim()}%,file_name.ilike.%${searchQuery.trim()}%,sub_category.ilike.%${searchQuery.trim()}%',
        );
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      var list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (city != null && city.isNotEmpty && city != 'All Cities') {
        list = list
            .where((d) => d.address?.city.toLowerCase() == city.toLowerCase())
            .toList();
      }

      AppLogger.info(
        'DOCUMENTS_DATASET',
        'Filtered documents returned: ${list.length}',
      );
      return list;
    } catch (e, st) {
      AppLogger.error(
        'DOCUMENTS_DATASET',
        'Error in getFilteredDocuments: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Obtains signed preview URL from Supabase storage or passes through external URLs.
  Future<String> getSignedPreviewUrl(String storagePath, {bool download = false}) async {
    if (storagePath.startsWith('http://') || storagePath.startsWith('https://')) {
      return storagePath;
    }
    if (DemoDataService.isDemoMode) {
      return 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?auto=format&fit=crop&w=1200&q=80';
    }
    return await _provider.createSignedUrl(
      storagePath: storagePath,
      expiresInSeconds: 3600,
      download: download,
    );
  }

  /// Downloads file binary bytes via API.
  Future<Uint8List> downloadFileBytes(String storagePath) async {
    if (DemoDataService.isDemoMode) {
      return Uint8List(0);
    }
    return await _provider.downloadFileBytes(storagePath);
  }

  /// Creates a secure expiring share link for the document.
  Future<String> createShareLink(String documentId, {int daysValid = 7}) async {
    if (DemoDataService.isDemoMode) {
      return 'demo-share-preview-token';
    }
    final user = _provider.currentUser;
    final token = const Uuid().v4().replaceAll('-', '').substring(0, 16);
    final expiresAt = DateTime.now().add(Duration(days: daysValid));

    AppLogger.debug(
      'DOCUMENTS_DATASET',
      'createShareLink for doc: $documentId ($daysValid days)',
    );

    try {
      await _client.from('document_shares').insert({
        'document_id': documentId,
        'shared_by': user?.id,
        'share_token': token,
        'expires_at': expiresAt.toIso8601String(),
      });

      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'shared',
        'details': {'token': token, 'days_valid': daysValid},
      });

      return token;
    } catch (e, st) {
      AppLogger.error(
        'DOCUMENTS_DATASET',
        'Error creating share link: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Toggles favorite status for a document.
  Future<bool> toggleFavorite(String documentId, bool currentlyFavorite) async {
    if (DemoDataService.isDemoMode) {
      return !currentlyFavorite;
    }
    final user = _provider.currentUser;
    if (user == null) return false;

    AppLogger.debug(
      'DOCUMENTS_DATASET',
      'toggleFavorite doc: $documentId, currentlyFav: $currentlyFavorite',
    );

    try {
      if (currentlyFavorite) {
        await _client.from('document_favorites').delete().match({
          'document_id': documentId,
          'user_id': user.id,
        });
        return false;
      } else {
        await _client.from('document_favorites').insert({
          'document_id': documentId,
          'user_id': user.id,
        });
        return true;
      }
    } catch (e, st) {
      AppLogger.error(
        'DOCUMENTS_DATASET',
        'Error in toggleFavorite: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Soft deletes document using RPC `soft_delete_document` with fallback.
  Future<void> softDeleteDocument(String documentId) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('DOCUMENTS_DATASET', 'Demo Mode: soft-deleted document $documentId');
      return;
    }
    final user = _provider.currentUser;
    AppLogger.debug(
      'DOCUMENTS_DATASET',
      'softDeleteDocument for ID: $documentId',
    );

    try {
      try {
        await _client.rpc('soft_delete_document', params: {
          'p_doc_id': documentId,
        });
      } catch (rpcErr) {
        AppLogger.warning(
          'DOCUMENTS_DATASET',
          'RPC soft_delete_document fallback to direct update: $rpcErr',
        );
        await _client.from('documents').update({
          'deleted_at': DateTime.now().toIso8601String(),
          'deleted_by': user?.id,
        }).eq('id', documentId);

        await _client.from('document_activity_logs').insert({
          'document_id': documentId,
          'user_id': user?.id,
          'action': 'moved_to_trash',
          'details': {'reason': 'Soft deleted from explorer'},
        });
      }

      AppLogger.info(
        'DOCUMENTS_DATASET',
        'Document $documentId soft-deleted successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'DOCUMENTS_DATASET',
        'Error in softDeleteDocument: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates document metadata and optionally re-uploads / replaces document payload or attachment URL.
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
    if (DemoDataService.isDemoMode) {
      AppLogger.info('DOCUMENTS_DATASET', 'Demo Mode: updated document details for $documentId');
      DemoDataService.updateDocumentMock(
        documentId: documentId,
        title: title,
        description: description,
        documentNumber: documentNumber,
        applianceWarranty: applianceWarranty,
        vehicleMetadata: vehicleMetadata,
        newFileName: newFileName,
        newFileSize: newFileBytes?.lengthInBytes,
        newMimeType: newMimeType,
        attachmentUrl: attachmentUrl,
      );
      return;
    }
    final user = _provider.currentUser;
    AppLogger.debug(
      'DOCUMENTS_DATASET',
      'updateDocumentDetails for ID: $documentId',
    );

    try {
      String sanitizedTitle = title;
      if (newFileBytes != null && newFileName != null && sanitizedTitle.contains('(Google Drive)')) {
        sanitizedTitle = sanitizedTitle
            .replaceAll('(Google Drive)', '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      final docUpdates = <String, dynamic>{
        'title': sanitizedTitle,
        'description': description,
        'document_number': documentNumber,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newFileBytes != null && newFileName != null) {
        final sanitizedFileName = newFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final catFolder = categoryCode?.isNotEmpty == true ? categoryCode! : 'documents';
        final subCatFolder = (subCategory ?? '').trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toLowerCase();
        final storagePath = subCatFolder.isNotEmpty
            ? '$catFolder/$subCatFolder/$documentId-$sanitizedFileName'
            : '$catFolder/$documentId-$sanitizedFileName';

        await _provider.uploadDocumentFile(
          storagePath: storagePath,
          fileBytes: newFileBytes,
          mimeType: newMimeType ?? 'application/pdf',
        );

        final fileType = newFileName.contains('.')
            ? newFileName.split('.').last.toLowerCase()
            : 'pdf';

        docUpdates['file_name'] = newFileName;
        docUpdates['file_path'] = storagePath;
        docUpdates['file_size'] = newFileBytes.lengthInBytes;
        docUpdates['file_type'] = fileType;
        docUpdates['mime_type'] = newMimeType ?? 'application/pdf';

        // Clean any legacy google drive extra attributes so it points to VPS/Supabase storage
        try {
          final currentDoc = await _client
              .from('documents')
              .select('extra_attributes')
              .eq('id', documentId)
              .maybeSingle();
          final extras = currentDoc?['extra_attributes'] != null
              ? Map<String, dynamic>.from(currentDoc!['extra_attributes'] as Map)
              : <String, dynamic>{};
          extras.remove('google_drive_url');
          extras.remove('attachment_url');
          extras.remove('is_google_attachment');
          extras['storage_provider'] = 'supabase';
          docUpdates['extra_attributes'] = extras;
        } catch (_) {}
      } else if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
        docUpdates['file_path'] = attachmentUrl;
        final uri = Uri.tryParse(attachmentUrl);
        final lastSeg = uri != null && uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Google Drive Document';
        docUpdates['file_name'] = lastSeg.isNotEmpty ? lastSeg : 'Google Drive Document';
        docUpdates['file_type'] = 'gdrive';
        docUpdates['mime_type'] = 'application/vnd.google-apps.document';
      }

      await _client.from('documents').update(docUpdates).eq('id', documentId);

      if (applianceWarranty != null) {
        final warrantyMap = applianceWarranty.toJson();
        warrantyMap['document_id'] = documentId;
        try {
          await _client.from('appliance_warranty_metadata').upsert(warrantyMap);
        } catch (tableErr) {
          AppLogger.warning(
            'DOCUMENTS_DATASET',
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

      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'updated',
        'details': {
          'title': title,
          'document_number': documentNumber,
        },
      });
      AppLogger.info(
        'DOCUMENTS_DATASET',
        'Document $documentId updated successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'DOCUMENTS_DATASET',
        'Error in updateDocumentDetails: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches single document by ID with all relations.
  Future<DocumentModel?> getDocumentById(String documentId) async {
    if (DemoDataService.isDemoMode) {
      final docs = DemoDataService.getAllDocuments();
      try {
        return docs.firstWhere((d) => d.id == documentId);
      } catch (_) {
        return docs.isNotEmpty ? docs.first : null;
      }
    }
    AppLogger.debug('DOCUMENTS_DATASET', 'Fetching document by ID: $documentId');
    try {
      final response = await _client.from('documents').select('''
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
      ''').eq('id', documentId).maybeSingle();

      if (response == null) return null;
      return DocumentModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error(
        'DOCUMENTS_DATASET',
        'Error in getDocumentById: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Creates a new document record, uploads binary payload to storage, and persists domain metadata.
  Future<DocumentModel> createDocument({
    required String title,
    String? description,
    required String categoryId,
    required String subCategory,
    String? folderId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    String? documentNumber,
    AddressModel? address,
    UtilityMetadataModel? utilityMetadata,
    ApplianceWarrantyModel? applianceWarranty,
    PersonalDocumentMetadataModel? personalMetadata,
    VehicleDocumentMetadataModel? vehicleMetadata,
  }) async {
    final docId = const Uuid().v4();
    if (DemoDataService.isDemoMode) {
      AppLogger.info('DOCUMENTS_DATASET', 'Demo Mode: Mocking document creation for "$title"');
      final newDoc = DocumentModel(
        id: docId,
        title: title,
        description: description,
        categoryId: categoryId,
        subCategory: subCategory,
        folderId: folderId,
        fileName: fileName,
        filePath: 'demo/$docId-$fileName',
        fileType: fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'pdf',
        mimeType: mimeType,
        fileSize: fileBytes.lengthInBytes,
        documentNumber: documentNumber,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryName: DemoDataService.getCategories().firstWhere(
          (c) => c.id == categoryId,
          orElse: () => DemoDataService.getCategories().first,
        ).name,
        categoryCode: DemoDataService.getCategories().firstWhere(
          (c) => c.id == categoryId,
          orElse: () => DemoDataService.getCategories().first,
        ).code,
        address: address,
        utilityMetadata: utilityMetadata,
        applianceWarranty: applianceWarranty,
        personalMetadata: personalMetadata,
        vehicleMetadata: vehicleMetadata,
      );
      return newDoc;
    }

    final user = _provider.currentUser;
    final sanitizedFileName = fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    AppLogger.info(
      'DOCUMENTS_DATASET',
      'Creating document: "$title" ($fileName) in category: $categoryId, subCategory: $subCategory',
    );

    try {
      String categoryFolder = 'documents';
      try {
        final catRes = await _provider.client
            .from('document_categories')
            .select('code')
            .eq('id', categoryId)
            .maybeSingle();
        if (catRes != null && catRes['code'] != null) {
          categoryFolder = catRes['code'] as String;
        } else {
          categoryFolder = categoryId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        }
      } catch (_) {
        categoryFolder = categoryId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      }

      final sanitizedSubCat = subCategory
          .trim()
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
          .toLowerCase();

      final storagePath = sanitizedSubCat.isNotEmpty
          ? '$categoryFolder/$sanitizedSubCat/$docId-$sanitizedFileName'
          : '$categoryFolder/$docId-$sanitizedFileName';

      await _provider.uploadDocumentFile(
        storagePath: storagePath,
        fileBytes: fileBytes,
        mimeType: mimeType,
      );
      final extraAttributes = <String, dynamic>{'storage_provider': 'supabase'};

      final fileType = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'pdf';

      if (applianceWarranty != null) {
        extraAttributes['appliance_items'] =
            applianceWarranty.items.map((i) => i.toJson()).toList();
      }

      final docData = {
        'id': docId,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'sub_category': subCategory,
        'folder_id': folderId,
        'file_name': fileName,
        'file_path': storagePath,
        'file_type': fileType,
        'mime_type': mimeType,
        'file_size': fileBytes.lengthInBytes,
        'document_number': documentNumber,
        'status': 'active',
        'uploaded_by': user?.id,
        'extra_attributes': extraAttributes,
      };

      final insertedDoc = await _client
          .from('documents')
          .insert(docData)
          .select()
          .single();
      AppLogger.info('DOCUMENTS_DATASET', 'Inserted main document record: $docId');

      if (address != null) {
        final addrMap = address.toJson();
        addrMap['document_id'] = docId;
        await _client.from('document_addresses').insert(addrMap);
        AppLogger.info('DOCUMENTS_DATASET', 'Inserted address metadata for $docId');
      }

      if (utilityMetadata != null) {
        final utilMap = utilityMetadata.toJson();
        utilMap['document_id'] = docId;
        await _client.from('utility_metadata').insert(utilMap);
        AppLogger.info('DOCUMENTS_DATASET', 'Inserted utility metadata for $docId');
      }

      if (applianceWarranty != null) {
        final warrantyMap = applianceWarranty.toJson();
        warrantyMap['document_id'] = docId;
        try {
          await _client
              .from('appliance_warranty_metadata')
              .insert(warrantyMap);
        } catch (tableErr) {
          AppLogger.warning(
            'DOCUMENTS_DATASET',
            'Non-fatal fallback inserting warrantyMap: $tableErr. Retrying without raw items column if needed.',
          );
          final legacyMap = Map<String, dynamic>.from(warrantyMap)..remove('items');
          await _client
              .from('appliance_warranty_metadata')
              .insert(legacyMap);
        }
        AppLogger.info('DOCUMENTS_DATASET', 'Inserted warranty metadata for $docId');
      }

      if (personalMetadata != null) {
        final personalMap = personalMetadata.toJson();
        personalMap['document_id'] = docId;
        await _client
            .from('personal_document_metadata')
            .insert(personalMap);
        AppLogger.info(
          'DOCUMENTS_DATASET',
          'Inserted personal document metadata for $docId',
        );
      }

      if (vehicleMetadata != null) {
        final vehicleMap = vehicleMetadata.toJson();
        vehicleMap['document_id'] = docId;
        await _client
            .from('vehicle_document_metadata')
            .insert(vehicleMap);
        AppLogger.info(
          'DOCUMENTS_DATASET',
          'Inserted vehicle document metadata for $docId',
        );
      }

      await _client.from('document_activity_logs').insert({
        'document_id': docId,
        'user_id': user?.id,
        'action': 'uploaded',
        'details': {
          'title': title,
          'file_name': fileName,
          'category': subCategory,
        },
      });

      final fullDoc = await getDocumentById(docId);
      return fullDoc ?? DocumentModel.fromJson(insertedDoc);
    } catch (e, st) {
      AppLogger.error(
        'DOCUMENTS_DATASET',
        'Error in createDocument: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
