import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class VehicleDocsResponse {
  final List<DocumentModel> documents;
  final int totalCount;
  final int totalDocumentsCount;
  final int totalVehiclesCount;
  final int expiringSoonCount;
  final int expiredCount;

  const VehicleDocsResponse({
    required this.documents,
    required this.totalCount,
    required this.totalDocumentsCount,
    required this.totalVehiclesCount,
    required this.expiringSoonCount,
    required this.expiredCount,
  });
}

/// Dataset responsible for Vehicle Documents data queries and operations.
/// Strictly conforms to the 3-Tier Architecture: View -> Controller -> Dataset -> Supabase.
class VehicleDocsDataset {
  final SupabaseProvider _provider;

  VehicleDocsDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  /// Fetches registered master vehicles.
  Future<List<MasterVehicleModel>> getMasterVehicles({
    bool activeOnly = true,
  }) async {
    AppLogger.debug(
      'VEHICLE_DOCS_DATASET',
      'Fetching master vehicles (activeOnly: $activeOnly)...',
    );
    try {
      var query = _client.from('master_vehicles').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('vehicle_number', ascending: true);

      final list = (response as List)
          .map((json) => MasterVehicleModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error fetching master vehicles: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Adds a new master vehicle.
  Future<MasterVehicleModel> createMasterVehicle(
    MasterVehicleModel vehicle,
  ) async {
    AppLogger.info(
      'VEHICLE_DOCS_DATASET',
      'Creating master vehicle: ${vehicle.vehicleNumber}...',
    );
    try {
      final payload = vehicle.toJson()..remove('id');
      final res = await _client
          .from('master_vehicles')
          .insert(payload)
          .select()
          .single();
      return MasterVehicleModel.fromJson(res);
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error creating master vehicle: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates an existing master vehicle.
  Future<void> updateMasterVehicle(MasterVehicleModel vehicle) async {
    AppLogger.info(
      'VEHICLE_DOCS_DATASET',
      'Updating master vehicle: ${vehicle.id} (${vehicle.vehicleNumber})...',
    );
    try {
      final payload = vehicle.toJson()..remove('id');
      await _client
          .from('master_vehicles')
          .update(payload)
          .eq('id', vehicle.id);
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error updating master vehicle: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches active vehicle document types.
  Future<List<MasterVehicleDocTypeModel>> getMasterVehicleDocTypes({
    bool activeOnly = true,
  }) async {
    AppLogger.debug(
      'VEHICLE_DOCS_DATASET',
      'Fetching master vehicle doc types (activeOnly: $activeOnly)...',
    );
    try {
      var query = _client.from('master_vehicle_doc_types').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);

      final list = (response as List)
          .map(
            (json) => MasterVehicleDocTypeModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error fetching master vehicle doc types: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  String? _cachedVehicleDocsCategoryId;

  Future<String> getVehicleDocsCategoryId() async {
    if (_cachedVehicleDocsCategoryId != null) {
      return _cachedVehicleDocsCategoryId!;
    }
    try {
      final res = await _client
          .from('document_categories')
          .select('id')
          .eq('code', 'vehicle_docs')
          .maybeSingle();
      if (res != null && res['id'] != null) {
        _cachedVehicleDocsCategoryId = res['id'] as String;
      }
    } catch (_) {}
    return _cachedVehicleDocsCategoryId ?? '';
  }

  /// Fetches paginated vehicle documents with server-side batching and aggregated summary metrics.
  Future<VehicleDocsResponse> getVehicleDocuments({
    int page = 1,
    int pageSize = 20,
    String? vehicleNumber,
    String? docType,
    String? expiryFilter, // 'All', 'Active', 'Expiring in 30 Days', 'Expired'
    String? searchQuery,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    AppLogger.debug(
      'VEHICLE_DOCS_DATASET',
      'Fetching vehicle docs (page: $page, range: $from-$to, vehicle: $vehicleNumber, docType: $docType, search: $searchQuery)...',
    );

    try {
      final categoryId = await getVehicleDocsCategoryId();

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
          .isFilter('deleted_at', null);

      if (categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      var countQuery = _client
          .from('documents')
          .select('id')
          .isFilter('deleted_at', null);

      if (categoryId.isNotEmpty) {
        countQuery = countQuery.eq('category_id', categoryId);
      }

      // 1. Vehicle filter via metadata subquery
      List<String>? filteredIds;

      if (vehicleNumber != null &&
          vehicleNumber.isNotEmpty &&
          vehicleNumber != 'All Vehicles') {
        final cleanNum = vehicleNumber.trim().toUpperCase();
        final metaRows = await _client
            .from('vehicle_document_metadata')
            .select('document_id')
            .eq('vehicle_number', cleanNum);
        final ids = (metaRows as List)
            .map((r) => r['document_id'] as String?)
            .whereType<String>()
            .toList();

        filteredIds = ids;
      }

      // 2. Document Type filter via metadata subquery
      if (docType != null &&
          docType.isNotEmpty &&
          docType != 'All Document Types' &&
          docType != 'All Docs') {
        final metaRows = await _client
            .from('vehicle_document_metadata')
            .select('document_id')
            .ilike('doc_type_name', '%$docType%');
        final ids = (metaRows as List)
            .map((r) => r['document_id'] as String?)
            .whereType<String>()
            .toSet();

        if (filteredIds != null) {
          filteredIds = filteredIds.where((id) => ids.contains(id)).toList();
        } else {
          filteredIds = ids.toList();
        }
      }

      // 3. Expiry status filter via metadata subquery
      if (expiryFilter != null &&
          expiryFilter.isNotEmpty &&
          expiryFilter != 'All' &&
          expiryFilter != 'All Statuses') {
        final now = DateTime.now();
        final todayStr = DateTime(now.year, now.month, now.day)
            .toIso8601String()
            .split('T')
            .first;
        final in30DaysStr = DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 30))
            .toIso8601String()
            .split('T')
            .first;

        var expQuery = _client.from('vehicle_document_metadata').select('document_id');

        if (expiryFilter == 'Expired') {
          expQuery = expQuery.lt('expiry_date', todayStr);
        } else if (expiryFilter == 'Expiring in 30 Days' || expiryFilter == 'Expiring Soon') {
          expQuery = expQuery
              .gte('expiry_date', todayStr)
              .lte('expiry_date', in30DaysStr);
        } else if (expiryFilter == 'Active' || expiryFilter == 'Valid') {
          expQuery = expQuery.gt('expiry_date', in30DaysStr);
        }

        final expRows = await expQuery;
        final expIds = (expRows as List)
            .map((r) => r['document_id'] as String?)
            .whereType<String>()
            .toSet();

        if (filteredIds != null) {
          filteredIds = filteredIds.where((id) => expIds.contains(id)).toList();
        } else {
          filteredIds = expIds.toList();
        }
      }

      // Apply ID filters if any were resolved
      if (filteredIds != null) {
        if (filteredIds.isEmpty) {
          query = query.eq('id', '00000000-0000-0000-0000-000000000000');
          countQuery =
              countQuery.eq('id', '00000000-0000-0000-0000-000000000000');
        } else {
          query = query.inFilter('id', filteredIds);
          countQuery = countQuery.inFilter('id', filteredIds);
        }
      }

      // 4. Search query filter (matches document fields or vehicle pass/policy metadata)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        List<String> metaMatchedIds = [];
        try {
          final metaMatchRows = await _client
              .from('vehicle_document_metadata')
              .select('document_id')
              .or(
                'toll_plaza_name.ilike.%$q%,fastag_id.ilike.%$q%,policy_or_cert_number.ilike.%$q%,pass_type.ilike.%$q%,insurance_company.ilike.%$q%',
              );
          metaMatchedIds = (metaMatchRows as List)
              .map((r) => r['document_id'] as String?)
              .whereType<String>()
              .toList();
        } catch (_) {}

        final searchFilter =
            'title.ilike.%$q%,document_number.ilike.%$q%,file_name.ilike.%$q%,sub_category.ilike.%$q%';

        if (metaMatchedIds.isNotEmpty) {
          final idFilter = metaMatchedIds.map((id) => 'id.eq.$id').join(',');
          query = query.or('$searchFilter,$idFilter');
          countQuery = countQuery.or('$searchFilter,$idFilter');
        } else {
          query = query.or(searchFilter);
          countQuery = countQuery.or(searchFilter);
        }
      }

      // 5. Fetch paginated documents
      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      var list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Ensure vehicleMetadata is present
      list = list.where((d) => d.vehicleMetadata != null).toList();

      // 6. Fetch exact count of matching records
      final countRes = await countQuery.count(CountOption.exact);
      final totalRecords = countRes.count;

      // 7. Calculate summary metrics across all vehicle document records in the database
      final summaryRes = await _client
          .from('vehicle_document_metadata')
          .select('vehicle_number, expiry_date');

      final vehicleSet = <String>{};
      int expiringCount = 0;
      int expiredCount = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final raw in (summaryRes as List)) {
        final vNum = raw['vehicle_number'] as String?;
        if (vNum != null && vNum.isNotEmpty) {
          vehicleSet.add(vNum.trim().toUpperCase());
        }

        final expiryStr = raw['expiry_date'] as String?;
        if (expiryStr != null) {
          final expDate = DateTime.tryParse(expiryStr);
          if (expDate != null) {
            if (expDate.isBefore(today)) {
              expiredCount++;
            } else {
              final diff = expDate.difference(today).inDays;
              if (diff >= 0 && diff <= 30) {
                expiringCount++;
              }
            }
          }
        }
      }

      return VehicleDocsResponse(
        documents: list,
        totalCount: totalRecords,
        totalDocumentsCount: summaryRes.length,
        totalVehiclesCount: vehicleSet.length,
        expiringSoonCount: expiringCount,
        expiredCount: expiredCount,
      );
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error fetching vehicle documents: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches all documents for a single vehicle and document type to show history/renewals.
  Future<List<DocumentModel>> getVehicleDocTypeHistory({
    required String vehicleNumber,
    required String docTypeName,
  }) async {
    AppLogger.debug(
      'VEHICLE_DOCS_DATASET',
      'Fetching history for vehicle: $vehicleNumber, docType: $docTypeName...',
    );
    try {
      final metaRows = await _client
          .from('vehicle_document_metadata')
          .select('document_id')
          .eq('vehicle_number', vehicleNumber.trim().toUpperCase())
          .ilike('doc_type_name', '%$docTypeName%');

      final ids = (metaRows as List)
          .map((r) => r['document_id'] as String?)
          .whereType<String>()
          .toList();

      if (ids.isEmpty) return [];

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
            vehicle_document_metadata(*),
            document_favorites(document_id, user_id)
          ''')
          .inFilter('id', ids)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .where((d) => d.vehicleMetadata != null)
          .toList();

      // Sort by expiry_date descending (latest active first) or created_at descending
      list.sort((a, b) {
        final aExp = a.vehicleMetadata?.expiryDate;
        final bExp = b.vehicleMetadata?.expiryDate;
        if (aExp != null && bExp != null) {
          return bExp.compareTo(aExp);
        }
        if (aExp != null) return -1;
        if (bExp != null) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return list;
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error fetching vehicle doc type history: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Saves metadata for a vehicle document.
  Future<void> saveVehicleDocumentMetadata(
    VehicleDocumentMetadataModel meta,
  ) async {
    AppLogger.info(
      'VEHICLE_DOCS_DATASET',
      'Saving vehicle metadata for doc: ${meta.documentId}...',
    );
    try {
      final payload = meta.toJson()..remove('id');
      await _client.from('vehicle_document_metadata').insert(payload);
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error saving vehicle document metadata: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates vehicle document metadata.
  Future<void> updateVehicleDocumentMetadata(
    VehicleDocumentMetadataModel meta,
  ) async {
    AppLogger.info(
      'VEHICLE_DOCS_DATASET',
      'Updating vehicle metadata for doc: ${meta.documentId}...',
    );
    try {
      final payload = meta.toJson()
        ..remove('id')
        ..remove('document_id');

      if (meta.documentId != null) {
        await _client
            .from('vehicle_document_metadata')
            .update(payload)
            .eq('document_id', meta.documentId!);
      }
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error updating vehicle document metadata: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates document title, description, document_number, and vehicle metadata.
  Future<void> updateDocumentDetails({
    required String documentId,
    required String title,
    String? description,
    String? documentNumber,
    VehicleDocumentMetadataModel? vehicleMetadata,
  }) async {
    AppLogger.info(
      'VEHICLE_DOCS_DATASET',
      'Updating details for vehicle document: $documentId...',
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

      if (vehicleMetadata != null) {
        await updateVehicleDocumentMetadata(vehicleMetadata);
      }

      final user = _provider.currentUser;
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
        'VEHICLE_DOCS_DATASET',
        'Vehicle document $documentId updated successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error in updateDocumentDetails: $e',
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
        'VEHICLE_DOCS_DATASET',
        'Error toggling favorite: $e',
        error: e,
        stackTrace: st,
      );
      return currentFavorite;
    }
  }

  /// Soft deletes a vehicle document by setting deleted_at timestamp.
  Future<void> softDeleteDocument(String documentId) async {
    AppLogger.info(
      'VEHICLE_DOCS_DATASET',
      'Soft deleting vehicle document: $documentId...',
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
        'VEHICLE_DOCS_DATASET',
        'Error soft deleting vehicle document: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Generates a signed preview URL for viewing or downloading.
  Future<String> getSignedPreviewUrl(
    String filePath, {
    bool download = false,
  }) async {
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
        'VEHICLE_DOCS_DATASET',
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
        'VEHICLE_DOCS_DATASET',
        'Error generating share token: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // --- Vehicle Service & Maintenance Methods ---

  /// Fetches service records, optionally filtered by vehicle ID.
  Future<List<VehicleServiceModel>> getVehicleServices({
    String? vehicleId,
  }) async {
    AppLogger.debug(
      'VEHICLE_DOCS_DATASET',
      'Fetching vehicle services (vehicleId: $vehicleId)...',
    );
    try {
      var query = _client.from('vehicle_services').select();
      if (vehicleId != null && vehicleId.isNotEmpty) {
        query = query.eq('vehicle_id', vehicleId);
      }
      final response = await query
          .order('service_date', ascending: false)
          .order('odometer_km', ascending: false);

      final list = (response as List)
          .map((json) =>
              VehicleServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error fetching vehicle services: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Inserts a new vehicle service record.
  Future<VehicleServiceModel> createVehicleService(
    VehicleServiceModel service,
  ) async {
    AppLogger.debug(
      'VEHICLE_DOCS_DATASET',
      'Creating vehicle service log for vehicle: ${service.vehicleId}...',
    );
    try {
      final insertData = service.toJson();
      insertData.remove('id'); // let Supabase generate UUID
      insertData['created_by'] = _client.auth.currentUser?.id;

      final response = await _client
          .from('vehicle_services')
          .insert(insertData)
          .select()
          .single();

      return VehicleServiceModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error creating vehicle service: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates an existing vehicle service record.
  Future<VehicleServiceModel> updateVehicleService(
    VehicleServiceModel service,
  ) async {
    AppLogger.debug(
      'VEHICLE_DOCS_DATASET',
      'Updating vehicle service log: ${service.id}...',
    );
    try {
      final updateData = service.toJson();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('vehicle_services')
          .update(updateData)
          .eq('id', service.id)
          .select()
          .single();

      return VehicleServiceModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error updating vehicle service: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Deletes a vehicle service record.
  Future<void> deleteVehicleService(String serviceId) async {
    AppLogger.debug(
      'VEHICLE_DOCS_DATASET',
      'Deleting vehicle service log: $serviceId...',
    );
    try {
      await _client.from('vehicle_services').delete().eq('id', serviceId);
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_DATASET',
        'Error deleting vehicle service: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
