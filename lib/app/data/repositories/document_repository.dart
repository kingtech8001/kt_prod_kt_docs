import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/address_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/dashboard_metrics_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_metadata_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DocumentRepository {
  final SupabaseProvider _provider;

  DocumentRepository(this._provider);

  Future<List<DocumentModel>> getDocuments({
    String? categoryId,
    String? categoryCode,
    String? city,
    String? subCategory,
    String? brand,
    String? personName,
    String? personalDocType,
    String? status,
    String? folderId,
    String? searchQuery,
    bool isFavoriteOnly = false,
    bool isTrashOnly = false,
    int limit = 100,
    int offset = 0,
  }) async {
    final user = _provider.currentUser;
    AppLogger.debug('DOC_REPO', 'getDocuments query params:', {
      'categoryId': categoryId,
      'categoryCode': categoryCode,
      'city': city,
      'subCategory': subCategory,
      'brand': brand,
      'personName': personName,
      'personalDocType': personalDocType,
      'status': status,
      'isFavoriteOnly': isFavoriteOnly,
      'isTrashOnly': isTrashOnly,
    });

    try {
      var query = _provider.client.from('documents').select('''
        *,
        document_categories(id, name, code, color_hex, icon),
        folders(id, name),
        profiles:uploaded_by(id, full_name, email),
        document_addresses(*),
        utility_metadata(*),
        appliance_warranty_metadata(*),
        personal_document_metadata(*),
        document_favorites(document_id, user_id)
      ''');

      if (isTrashOnly) {
        query = query.not('deleted_at', 'is', null);
      } else {
        query = query.isFilter('deleted_at', null);
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (folderId != null && folderId.isNotEmpty) {
        query = query.eq('folder_id', folderId);
      }

      if (subCategory != null && subCategory.isNotEmpty) {
        query = query.eq('sub_category', subCategory);
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

      if (categoryCode != null && categoryCode.isNotEmpty) {
        list = list.where((d) => d.categoryCode == categoryCode).toList();
      }

      if (city != null && city.isNotEmpty && city != 'All Cities') {
        list = list
            .where((d) => d.address?.city.toLowerCase() == city.toLowerCase())
            .toList();
      }

      if (brand != null && brand.isNotEmpty && brand != 'All Brands') {
        list = list
            .where(
              (d) =>
                  d.applianceWarranty?.brand.toLowerCase() ==
                  brand.toLowerCase(),
            )
            .toList();
      }

      if (personName != null &&
          personName.isNotEmpty &&
          personName != 'All Persons') {
        list = list
            .where(
              (d) =>
                  d.personalMetadata?.personName.toLowerCase() ==
                  personName.toLowerCase(),
            )
            .toList();
      }

      if (personalDocType != null &&
          personalDocType.isNotEmpty &&
          personalDocType != 'All Document Types') {
        list = list
            .where(
              (d) =>
                  d.personalMetadata?.docTypeName.toLowerCase() ==
                  personalDocType.toLowerCase(),
            )
            .toList();
      }

      if (isFavoriteOnly && user != null) {
        list = list.where((d) => d.isFavorite).toList();
      }

      AppLogger.info(
        'DOC_REPO',
        'getDocuments returned ${list.length} documents.',
      );
      return list;
    } on PostgrestException catch (pe, st) {
      AppLogger.error(
        'DOC_REPO',
        'PostgrestException in getDocuments: ${pe.message}',
        error: pe,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Generic Exception in getDocuments: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<DocumentModel?> getDocumentById(String documentId) async {
    AppLogger.debug('DOC_REPO', 'Fetching document details for: $documentId');
    try {
      final response = await _provider.client
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
          .eq('id', documentId)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning('DOC_REPO', 'Document $documentId not found.');
        return null;
      }
      return DocumentModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Error in getDocumentById: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

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
  }) async {
    final user = _provider.currentUser;
    final docId = const Uuid().v4();
    final sanitizedFileName = fileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    AppLogger.info(
      'DOC_REPO',
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

      final insertedDoc = await _provider.client
          .from('documents')
          .insert(docData)
          .select()
          .single();
      AppLogger.info('DOC_REPO', 'Inserted main document record: $docId');

      if (address != null) {
        final addrMap = address.toJson();
        addrMap['document_id'] = docId;
        await _provider.client.from('document_addresses').insert(addrMap);
        AppLogger.info('DOC_REPO', 'Inserted address metadata for $docId');
      }

      if (utilityMetadata != null) {
        final utilMap = utilityMetadata.toJson();
        utilMap['document_id'] = docId;
        await _provider.client.from('utility_metadata').insert(utilMap);
        AppLogger.info('DOC_REPO', 'Inserted utility metadata for $docId');
      }

      if (applianceWarranty != null) {
        final warrantyMap = applianceWarranty.toJson();
        warrantyMap['document_id'] = docId;
        await _provider.client
            .from('appliance_warranty_metadata')
            .insert(warrantyMap);
        AppLogger.info('DOC_REPO', 'Inserted warranty metadata for $docId');
      }

      if (personalMetadata != null) {
        final personalMap = personalMetadata.toJson();
        personalMap['document_id'] = docId;
        await _provider.client
            .from('personal_document_metadata')
            .insert(personalMap);
        AppLogger.info(
          'DOC_REPO',
          'Inserted personal document metadata for $docId',
        );
      }

      await _provider.client.from('document_activity_logs').insert({
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
    } on PostgrestException catch (pe, st) {
      AppLogger.error(
        'DOC_REPO',
        'PostgrestException during createDocument: ${pe.message}',
        error: pe,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Error during createDocument: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> softDeleteDocument(String documentId) async {
    final user = _provider.currentUser;
    AppLogger.debug('DOC_REPO', 'softDeleteDocument for ID: $documentId');
    try {
      await _provider.client
          .from('documents')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': user?.id,
          })
          .eq('id', documentId);

      await _provider.client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'trashed',
        'details': {'reason': 'Moved to trash'},
      });
      AppLogger.info(
        'DOC_REPO',
        'Document $documentId soft-deleted successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Error during softDeleteDocument: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> updateDocumentDetails({
    required String documentId,
    required String title,
    String? description,
    String? documentNumber,
  }) async {
    final user = _provider.currentUser;
    AppLogger.debug(
      'DOC_REPO',
      'Updating document details for ID: $documentId',
    );
    try {
      await _provider.client
          .from('documents')
          .update({
            'title': title,
            'description': description,
            'document_number': documentNumber,
          })
          .eq('id', documentId);

      await _provider.client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'updated',
        'details': {'title': title},
      });
      AppLogger.info('DOC_REPO', 'Document $documentId updated successfully.');
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Error updating document details: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> restoreDocument(String documentId) async {
    final user = _provider.currentUser;
    AppLogger.debug('DOC_REPO', 'restoreDocument for ID: $documentId');
    try {
      await _provider.client
          .from('documents')
          .update({'deleted_at': null, 'deleted_by': null})
          .eq('id', documentId);

      await _provider.client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'restored',
        'details': {'reason': 'Restored from trash'},
      });
      AppLogger.info('DOC_REPO', 'Document $documentId restored successfully.');
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Error during restoreDocument: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> permanentDeleteDocument(
    String documentId,
    String filePath,
  ) async {
    final user = _provider.currentUser;
    AppLogger.debug(
      'DOC_REPO',
      'permanentDeleteDocument for ID: $documentId, path: $filePath',
    );
    try {
      if (filePath.startsWith('gdrive://')) {
        final fileId = filePath.replaceFirst('gdrive://', '');
        await _provider.deleteFromGoogleDrive(fileId);
      } else {
        try {
          await _provider.client.storage
              .from(AppConstants.storageBucket)
              .remove([filePath]);
        } catch (storageErr) {
          AppLogger.warning(
            'DOC_REPO',
            'Storage file remove non-fatal warning: $storageErr',
          );
        }
      }

      await _provider.client.from('documents').delete().eq('id', documentId);

      await _provider.client.from('document_activity_logs').insert({
        'document_id': null,
        'user_id': user?.id,
        'action': 'permanently_deleted',
        'details': {'doc_id': documentId},
      });
      AppLogger.info('DOC_REPO', 'Document $documentId permanently purged.');
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Error during permanentDeleteDocument: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<bool> toggleFavorite(String documentId, bool currentlyFavorite) async {
    final user = _provider.currentUser;
    if (user == null) return false;
    AppLogger.debug(
      'DOC_REPO',
      'toggleFavorite for doc: $documentId, currentlyFav: $currentlyFavorite',
    );

    try {
      if (currentlyFavorite) {
        await _provider.client.from('document_favorites').delete().match({
          'document_id': documentId,
          'user_id': user.id,
        });
        return false;
      } else {
        await _provider.client.from('document_favorites').insert({
          'document_id': documentId,
          'user_id': user.id,
        });
        return true;
      }
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Error in toggleFavorite: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<String> getSignedPreviewUrl(String storagePath) async {
    if (storagePath.startsWith('gdrive://')) {
      final fileId = storagePath.replaceFirst('gdrive://', '');
      return _provider.getGoogleDrivePreviewUrl(fileId);
    }
    return await _provider.createSignedUrl(
      storagePath: storagePath,
      expiresInSeconds: 600,
    );
  }

  Future<DashboardMetricsModel> getDashboardMetrics() async {
    AppLogger.debug(
      'DOC_REPO',
      'Fetching dashboard metrics via RPC get_dashboard_metrics...',
    );
    try {
      final response = await _provider.client.rpc('get_dashboard_metrics');
      if (response != null && response is Map<String, dynamic>) {
        AppLogger.info(
          'DOC_REPO',
          'get_dashboard_metrics RPC success:',
          response,
        );
        return DashboardMetricsModel.fromJson(response);
      }
    } catch (rpcErr) {
      AppLogger.warning(
        'DOC_REPO',
        'RPC get_dashboard_metrics fallback due to: $rpcErr',
      );
    }

    try {
      final countRes = await _provider.client
          .from('documents')
          .select('id, file_size')
          .isFilter('deleted_at', null);
      final count = (countRes as List).length;
      var totalSize = 0;
      for (var r in countRes) {
        totalSize += (r['file_size'] as num?)?.toInt() ?? 0;
      }

      return DashboardMetricsModel(
        totalDocuments: count,
        totalStorageBytes: totalSize,
      );
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Error in dashboard fallback count: $e',
        error: e,
        stackTrace: st,
      );
      return DashboardMetricsModel();
    }
  }

  Future<String> createShareLink(String documentId, {int daysValid = 7}) async {
    final user = _provider.currentUser;
    final token = const Uuid().v4().replaceAll('-', '').substring(0, 16);
    final expiresAt = DateTime.now().add(Duration(days: daysValid));
    AppLogger.debug(
      'DOC_REPO',
      'createShareLink for doc: $documentId (expires in $daysValid days)',
    );

    try {
      await _provider.client.from('document_shares').insert({
        'document_id': documentId,
        'shared_by': user?.id,
        'share_token': token,
        'expires_at': expiresAt.toIso8601String(),
      });

      await _provider.client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'shared',
        'details': {'token': token, 'days_valid': daysValid},
      });

      return token;
    } catch (e, st) {
      AppLogger.error(
        'DOC_REPO',
        'Error in createShareLink: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
