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
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
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

  /// Obtains signed preview URL for storage or Google Drive proxy.
  Future<String> getSignedPreviewUrl(String storagePath, {bool download = false}) async {
    if (storagePath.startsWith('gdrive://')) {
      final fileId = storagePath.replaceFirst('gdrive://', '');
      return _provider.getGoogleDrivePreviewUrl(fileId, download: download);
    }
    return await _provider.createSignedUrl(
      storagePath: storagePath,
      expiresInSeconds: 600,
      download: download,
    );
  }

  /// Downloads file binary bytes via API.
  Future<Uint8List> downloadFileBytes(String storagePath) async {
    return await _provider.downloadFileBytes(storagePath);
  }

  /// Creates a secure expiring share link for the document.
  Future<String> createShareLink(String documentId, {int daysValid = 7}) async {
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
    final user = _provider.currentUser;
    AppLogger.debug(
      'DOCUMENTS_DATASET',
      'softDeleteDocument for ID: $documentId',
    );

    try {
      try {
        await _client.rpc('soft_delete_document', params: {
          'p_document_id': documentId,
          'p_user_id': user?.id,
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
      }

      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'moved_to_trash',
        'details': {'reason': 'Soft deleted from explorer'},
      });
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

  /// Updates document metadata.
  Future<void> updateDocumentDetails({
    required String documentId,
    required String title,
    String? description,
    String? documentNumber,
    ApplianceWarrantyModel? applianceWarranty,
  }) async {
    final user = _provider.currentUser;
    AppLogger.debug(
      'DOCUMENTS_DATASET',
      'updateDocumentDetails for ID: $documentId',
    );

    try {
      await _client.from('documents').update({
        'title': title,
        'description': description,
        'document_number': documentNumber,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

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
    final user = _provider.currentUser;
    final docId = const Uuid().v4();
    final sanitizedFileName = fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    AppLogger.info(
      'DOCUMENTS_DATASET',
      'Creating document: "$title" ($fileName) via provider: ${AppConstants.storageProvider}',
    );

    try {
      String storagePath;
      Map<String, dynamic> extraAttributes = {};

      if (AppConstants.storageProvider == 'gdrive') {
        final gdriveRes = await _provider.uploadToGoogleDrive(
          fileBytes: fileBytes,
          fileName: fileName,
          mimeType: mimeType,
          folderName: subCategory,
        );
        final fileId = gdriveRes['fileId'] as String;
        storagePath = 'gdrive://$fileId';
        extraAttributes = {
          'storage_provider': 'gdrive',
          'gdrive_file_id': fileId,
          if (gdriveRes['webViewLink'] != null)
            'web_view_link': gdriveRes['webViewLink'],
          if (gdriveRes['webContentLink'] != null)
            'web_content_link': gdriveRes['webContentLink'],
        };
      } else {
        storagePath = 'vault/${user?.id ?? "shared"}/$docId/$sanitizedFileName';
        await _provider.uploadDocumentFile(
          storagePath: storagePath,
          fileBytes: fileBytes,
          mimeType: mimeType,
        );
        extraAttributes = {'storage_provider': 'supabase'};
      }

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
