import 'dart:typed_data';
import 'package:kt_prod_kt_docs/app/data/datasets/documents_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/address_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_metadata_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
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
  Future<List<MasterCityModel>> getMasterCities({
    bool activeOnly = true,
  }) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getCities();
    }
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
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getUtilityProviders();
    }
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
            (json) => MasterUtilityProviderModel.fromJson(
              json as Map<String, dynamic>,
            ),
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
    } catch (error, stackTrace) {
      AppLogger.error(
        'UTILITY_BILLS_DATASET',
        'Operation failed; applying fallback.',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
    if (DemoDataService.isDemoMode) {
      var list = DemoDataService.getAllDocuments()
          .where(
            (d) =>
                d.categoryId == 'cat-2' ||
                d.categoryId == 'cat-utility' ||
                d.categoryCode == 'utility_bills' ||
                d.utilityMetadata != null,
          )
          .toList();

      if (city != null && city.isNotEmpty && city != 'All Cities') {
        list = list
            .where((d) => d.address?.city.toLowerCase() == city.toLowerCase())
            .toList();
      }
      if (subCategory != null &&
          subCategory.isNotEmpty &&
          subCategory != 'All Utilities') {
        list = list
            .where(
              (d) => d.subCategory.toLowerCase() == subCategory.toLowerCase(),
            )
            .toList();
      }
      if (paymentStatus != null &&
          paymentStatus.isNotEmpty &&
          paymentStatus != 'all') {
        list = list.where((d) {
          final s = d.utilityMetadata?.paymentStatus.toLowerCase() ?? 'pending';
          if (paymentStatus == 'paid') return s == 'paid' || s == 'auto_debit';
          if (paymentStatus == 'pending') return s != 'paid';
          if (paymentStatus == 'overdue') {
            final due = d.utilityMetadata?.dueDate;
            return s != 'paid' && due != null && due.isBefore(DateTime.now());
          }
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
                  (d.utilityMetadata?.consumerNumber.toLowerCase().contains(
                        q,
                      ) ??
                      false),
            )
            .toList();
      }

      double totalAmt = 0.0;
      double pendingAmt = 0.0;
      int paidCnt = 0;
      int pendingCnt = 0;

      for (final d in list) {
        final amt = d.utilityMetadata?.billAmount ?? 0.0;
        final s = d.utilityMetadata?.paymentStatus.toLowerCase() ?? 'pending';
        final isPaid = s == 'paid' || s == 'auto_debit';
        totalAmt += amt;
        if (isPaid) {
          paidCnt++;
        } else {
          pendingAmt += amt;
          pendingCnt++;
        }
      }

      return UtilityBillsResponse(
        documents: list,
        totalCount: list.length,
        totalAmount: totalAmt,
        pendingAmount: pendingAmt,
        paidCount: paidCnt,
        pendingCount: pendingCnt,
      );
    }
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

      // 2. Subcategory filter
      if (subCategory != null &&
          subCategory.isNotEmpty &&
          subCategory != 'All Utilities') {
        query = query.eq('sub_category', subCategory);
      }

      // 3. Search query filter
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        final searchFilter =
            'title.ilike.%$q%,document_number.ilike.%$q%,file_name.ilike.%$q%,sub_category.ilike.%$q%';
        query = query.or(searchFilter);
      }

      // 4. Fetch documents
      final response = await query.order('created_at', ascending: false);

      var list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Ensure utilityMetadata is present
      list = list.where((d) => d.utilityMetadata != null).toList();

      // 5. Apply City filter safely in-memory (prevents HTTP 414 / URI overflow)
      if (city != null && city.isNotEmpty && city != 'All Cities') {
        final targetCity = city.toLowerCase().trim();
        list = list.where((d) {
          final docCity = d.address?.city.toLowerCase().trim();
          return docCity != null && docCity.contains(targetCity);
        }).toList();
      }

      // 6. Apply Payment Status filter safely in-memory
      if (paymentStatus != null &&
          paymentStatus.isNotEmpty &&
          paymentStatus != 'all') {
        final today = DateTime.now();
        list = list.where((d) {
          final s = d.utilityMetadata?.paymentStatus.toLowerCase() ?? 'pending';
          if (paymentStatus == 'paid') {
            return s == 'paid' || s == 'auto_debit';
          }
          if (paymentStatus == 'pending') {
            return s != 'paid';
          }
          if (paymentStatus == 'overdue') {
            final due = d.utilityMetadata?.dueDate;
            return s != 'paid' && due != null && due.isBefore(today);
          }
          return true;
        }).toList();
      }

      final totalRecords = list.length;
      final paginatedList = list.skip(from).take(pageSize).toList();

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
        'Returned ${paginatedList.length} utility bills on page $page (total count: $totalRecords)',
      );

      return UtilityBillsResponse(
        documents: paginatedList,
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
    if (DemoDataService.isDemoMode) {
      AppLogger.info(
        'UTILITY_DATASET',
        'Demo Mode: Updated payment status for $metadataId',
      );
      return;
    }
    AppLogger.debug(
      'UTILITY_DATASET',
      'Updating payment status for metadata $metadataId -> isPaid: $isPaid',
    );
    try {
      await _client
          .from('utility_metadata')
          .update({
            'payment_status': isPaid ? 'paid' : 'pending',
            'payment_date': paymentDate,
          })
          .eq('id', metadataId);

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

  /// Updates account / connection details across all bills belonging to this consumer number,
  /// including premise name, provider, meter number, and full physical address.
  Future<void> updateConnectionAccountDetails({
    required String oldConsumerNumber,
    required String newConsumerNumber,
    String? meterNumber,
    required String providerName,
    required String utilityType,
    String? premiseName,
    String? flatHouseNo,
    String? buildingName,
    String? streetAddress,
    required String areaLocality,
    required String city,
    String state = 'Gujarat',
    String? postalCode,
    String country = 'India',
  }) async {
    if (DemoDataService.isDemoMode) {
      final all = DemoDataService.getAllDocuments();
      for (int i = 0; i < all.length; i++) {
        final doc = all[i];
        if (doc.utilityMetadata?.consumerNumber == oldConsumerNumber) {
          final oldMeta = doc.utilityMetadata!;
          final newMeta = UtilityMetadataModel(
            id: oldMeta.id,
            documentId: oldMeta.documentId,
            utilityType: utilityType,
            providerName: providerName,
            consumerNumber: newConsumerNumber,
            meterNumber: meterNumber,
            billDate: oldMeta.billDate,
            dueDate: oldMeta.dueDate,
            billingPeriodStart: oldMeta.billingPeriodStart,
            billingPeriodEnd: oldMeta.billingPeriodEnd,
            billAmount: oldMeta.billAmount,
            paymentStatus: oldMeta.paymentStatus,
            paymentDate: oldMeta.paymentDate,
            paymentReferenceId: oldMeta.paymentReferenceId,
            unitsConsumed: oldMeta.unitsConsumed,
          );
          final newAddress = AddressModel(
            id: doc.address?.id,
            documentId: doc.id,
            premiseName: premiseName,
            flatHouseNo: flatHouseNo,
            buildingName: buildingName,
            streetAddress: streetAddress,
            areaLocality: areaLocality,
            city: city,
            state: state,
            postalCode: postalCode,
            country: country,
          );
          all[i] = doc.copyWith(
            subCategory: utilityType,
            utilityMetadata: newMeta,
            address: newAddress,
          );
        }
      }
      return;
    }

    AppLogger.debug(
      'UTILITY_DATASET',
      'Updating connection account: $oldConsumerNumber -> $newConsumerNumber',
    );
    try {
      // 1. Update utility_metadata for all bills of this consumer
      await _client
          .from('utility_metadata')
          .update({
            'consumer_number': newConsumerNumber,
            'meter_number': meterNumber,
            'provider_name': providerName,
            'utility_type': utilityType,
          })
          .eq('consumer_number', oldConsumerNumber);

      // 2. Fetch the document IDs for this consumer
      final docIdRows = await _client
          .from('utility_metadata')
          .select('document_id')
          .eq('consumer_number', newConsumerNumber);

      final docIds = (docIdRows as List)
          .map((r) => r['document_id'] as String)
          .toList();

      if (docIds.isNotEmpty) {
        // 3. Upsert / update addresses
        final addrRows = await _client
            .from('document_addresses')
            .select('document_id')
            .inFilter('document_id', docIds);
        final existingAddrDocIds = (addrRows as List)
            .map((r) => r['document_id'] as String)
            .toSet();

        final addrUpdatePayload = {
          'premise_name': premiseName,
          'flat_house_no': flatHouseNo,
          'building_name': buildingName,
          'street_address': streetAddress,
          'area_locality': areaLocality,
          'city': city,
          'state': state,
          'postal_code': postalCode,
          'country': country,
        };

        if (existingAddrDocIds.isNotEmpty) {
          await _client
              .from('document_addresses')
              .update(addrUpdatePayload)
              .inFilter('document_id', existingAddrDocIds.toList());
        }

        final missingAddrDocIds = docIds
            .where((id) => !existingAddrDocIds.contains(id))
            .toList();
        if (missingAddrDocIds.isNotEmpty) {
          final insertPayloads = missingAddrDocIds
              .map((id) => {'document_id': id, ...addrUpdatePayload})
              .toList();
          try {
            await _client.from('document_addresses').insert(insertPayloads);
          } catch (e) {
            AppLogger.warning(
              'UTILITY_DATASET',
              'Non-fatal inserting missing addresses: $e',
            );
          }
        }

        // 4. Update documents subcategory
        await _client
            .from('documents')
            .update({
              'sub_category': utilityType,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .inFilter('id', docIds);
      }
      AppLogger.info(
        'UTILITY_DATASET',
        'Connection account details updated successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_DATASET',
        'Error updating connection account: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Soft deletes a document (moves to trash) and writes an audit log.
  Future<void> softDeleteDocument(String documentId) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info(
        'UTILITY_DATASET',
        'Demo Mode: Moved doc to trash $documentId',
      );
      return;
    }
    final user = _provider.currentUser;
    AppLogger.debug('UTILITY_DATASET', 'Moving document to trash: $documentId');
    try {
      await _client
          .from('documents')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': user?.id,
          })
          .eq('id', documentId);

      await _client.from('document_activity_logs').insert({
        'document_id': documentId,
        'user_id': user?.id,
        'action': 'moved_to_trash',
        'details': {'reason': 'User moved utility bill to trash'},
      });

      AppLogger.info(
        'UTILITY_DATASET',
        'Document moved to trash successfully.',
      );
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

  /// Updates details of an individual utility bill cycle (e.g. title, amount, dates, payment status, meter).
  Future<void> updateUtilityBillCycle({
    required String documentId,
    required String title,
    String? description,
    required double billAmount,
    required DateTime billDate,
    DateTime? dueDate,
    required String paymentStatus,
    DateTime? paymentDate,
    String? paymentReferenceId,
    String? meterNumber,
    double? unitsConsumed,
  }) async {
    if (DemoDataService.isDemoMode) {
      DemoDataService.updateUtilityBillCycleMock(
        documentId: documentId,
        title: title,
        description: description,
        billAmount: billAmount,
        billDate: billDate,
        dueDate: dueDate,
        paymentStatus: paymentStatus,
        paymentDate: paymentDate,
        paymentReferenceId: paymentReferenceId,
        meterNumber: meterNumber,
        unitsConsumed: unitsConsumed,
      );
      return;
    }

    AppLogger.debug(
      'UTILITY_DATASET',
      'Updating bill cycle: $documentId ($title)',
    );
    try {
      // 1. Update documents title and description
      await _client
          .from('documents')
          .update({
            'title': title,
            'description': description,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', documentId);

      // 2. Update utility_metadata
      final metaUpdate = <String, dynamic>{
        'bill_amount': billAmount,
        'bill_date': billDate.toIso8601String().split('T').first,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'payment_status': paymentStatus,
        'payment_date': paymentDate?.toIso8601String().split('T').first,
        'payment_reference_id': paymentReferenceId,
        if (meterNumber != null && meterNumber.isNotEmpty)
          'meter_number': meterNumber,
        'units_consumed': ?unitsConsumed,
      };

      await _client
          .from('utility_metadata')
          .update(metaUpdate)
          .eq('document_id', documentId);

      AppLogger.info(
        'UTILITY_DATASET',
        'Bill cycle $documentId updated successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_DATASET',
        'Error updating bill cycle $documentId: $e',
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

  /// Obtains a signed preview URL for downloading or viewing.
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
    return await _provider.createSignedUrl(
      storagePath: filePath,
      expiresInSeconds: 3600,
      download: download,
    );
  }

  /// Downloads file binary bytes via API.
  Future<Uint8List> downloadFileBytes(String filePath) async {
    if (DemoDataService.isDemoMode) {
      return Uint8List(0);
    }
    return await _provider.downloadFileBytes(filePath);
  }

  /// Creates a share link for a document.
  Future<String> createShareLink(String documentId) async {
    if (DemoDataService.isDemoMode) {
      return 'demo-utility-share-link';
    }
    final user = _provider.currentUser;
    final token = const Uuid().v4();
    await _client.from('document_shares').insert({
      'document_id': documentId,
      'shared_by': user?.id,
      'share_token': token,
      'access_type': 'view',
      'expires_at': DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String(),
    });
    return token;
  }

  /// Logs a new monthly/bi-monthly bill cycle for an existing utility connection.
  Future<DocumentModel> logNextUtilityBill({
    required String consumerNumber,
    String? meterNumber,
    required String providerName,
    required String utilityType,
    String? premiseName,
    String? flatHouseNo,
    String? buildingName,
    String? streetAddress,
    String? areaLocality,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    required String title,
    String? description,
    required double billAmount,
    required DateTime billDate,
    DateTime? dueDate,
    required String paymentStatus, // 'pending' or 'paid'
    DateTime? paymentDate,
    String? paymentReferenceId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final catId = await _getUtilityCategoryId();
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'pdf';
    final mimeType = ext == 'pdf'
        ? 'application/pdf'
        : 'application/octet-stream';
    final storagePath =
        'utility_bills/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final effectiveAreaLocality =
        (areaLocality != null && areaLocality.trim().isNotEmpty)
        ? areaLocality.trim()
        : (premiseName != null && premiseName.trim().isNotEmpty
              ? premiseName.trim()
              : (city ?? 'Rajkot'));
    final effectiveCity = city ?? 'Rajkot';
    final effectiveState = state ?? 'Gujarat';
    final effectiveCountry = country ?? 'India';

    if (DemoDataService.isDemoMode) {
      final mockId = 'doc-util-${DateTime.now().millisecondsSinceEpoch}';
      final newDoc = DocumentModel(
        id: mockId,
        title: title,
        description: description,
        categoryId: catId,
        categoryName: 'Utility Bills',
        categoryCode: 'utility_bills',
        subCategory: utilityType,
        fileName: fileName,
        filePath: 'mock/$fileName',
        fileType: ext,
        mimeType: mimeType,
        fileSize: fileBytes.length,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        utilityMetadata: UtilityMetadataModel(
          documentId: mockId,
          utilityType: utilityType,
          providerName: providerName,
          consumerNumber: consumerNumber,
          meterNumber: meterNumber,
          billDate: billDate,
          dueDate: dueDate,
          billAmount: billAmount,
          paymentStatus: paymentStatus,
          paymentDate: paymentDate,
          paymentReferenceId: paymentReferenceId,
        ),
        address: AddressModel(
          premiseName: premiseName,
          flatHouseNo: flatHouseNo,
          buildingName: buildingName,
          streetAddress: streetAddress,
          areaLocality: effectiveAreaLocality,
          city: effectiveCity,
          state: effectiveState,
          postalCode: postalCode,
          country: effectiveCountry,
        ),
      );
      DemoDataService.getAllDocuments().insert(0, newDoc);
      return newDoc;
    }

    // 1. Upload new bill binary to Supabase Storage
    await _client.storage
        .from(AppConstants.storageBucket)
        .uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // 2. Insert main document record
    final docPayload = {
      'title': title,
      'description': description,
      'category_id': catId,
      'sub_category': utilityType,
      'file_name': fileName,
      'file_path': storagePath,
      'file_type': ext,
      'mime_type': mimeType,
      'file_size': fileBytes.length,
      'document_number': consumerNumber,
      'status': 'active',
      'uploaded_by': _client.auth.currentUser?.id,
      'extra_attributes': {'storage_provider': 'supabase'},
    };

    final docRes = await _client
        .from('documents')
        .insert(docPayload)
        .select()
        .single();
    final newDocId = docRes['id'] as String;

    // 3. Insert utility metadata
    final utilPayload = {
      'document_id': newDocId,
      'utility_type': utilityType,
      'provider_name': providerName,
      'consumer_number': consumerNumber,
      'meter_number': meterNumber,
      'bill_date': billDate.toIso8601String().split('T').first,
      if (dueDate != null)
        'due_date': dueDate.toIso8601String().split('T').first,
      'bill_amount': billAmount,
      'payment_status': paymentStatus,
      if (paymentDate != null)
        'payment_date': paymentDate.toIso8601String().split('T').first,
      if (paymentReferenceId != null && paymentReferenceId.isNotEmpty)
        'payment_reference_id': paymentReferenceId,
    };
    await _client.from('utility_metadata').insert(utilPayload);

    // 4. Insert address if available
    if (city != null ||
        premiseName != null ||
        flatHouseNo != null ||
        areaLocality != null) {
      final addrPayload = {
        'document_id': newDocId,
        'premise_name': premiseName,
        'flat_house_no': flatHouseNo,
        if (buildingName != null) 'building_name': buildingName,
        if (streetAddress != null) 'street_address': streetAddress,
        'area_locality': effectiveAreaLocality,
        'city': effectiveCity,
        'state': effectiveState,
        if (postalCode != null) 'postal_code': postalCode,
        'country': effectiveCountry,
      };
      try {
        await _client.from('document_addresses').insert(addrPayload);
      } catch (e, st) {
        AppLogger.warning(
          'UTILITY_DATASET',
          'Could not insert document_addresses record for $newDocId: $e ($st)',
        );
      }
    }

    return DocumentModel(
      id: newDocId,
      title: title,
      description: description,
      categoryId: catId,
      categoryName: 'Utility Bills',
      categoryCode: 'utility_bills',
      subCategory: utilityType,
      fileName: fileName,
      filePath: storagePath,
      fileType: ext,
      mimeType: mimeType,
      fileSize: fileBytes.length,
      documentNumber: consumerNumber,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      utilityMetadata: UtilityMetadataModel(
        documentId: newDocId,
        utilityType: utilityType,
        providerName: providerName,
        consumerNumber: consumerNumber,
        meterNumber: meterNumber,
        billDate: billDate,
        dueDate: dueDate,
        billAmount: billAmount,
        paymentStatus: paymentStatus,
        paymentDate: paymentDate,
        paymentReferenceId: paymentReferenceId,
      ),
      address: AddressModel(
        premiseName: premiseName,
        flatHouseNo: flatHouseNo,
        buildingName: buildingName,
        streetAddress: streetAddress,
        areaLocality: effectiveAreaLocality,
        city: effectiveCity,
        state: effectiveState,
        postalCode: postalCode,
        country: effectiveCountry,
      ),
    );
  }

  /// Fetches one bounded page of bill cycles for a consumer account.
  Future<List<DocumentModel>> getUtilityConnectionHistory(
    String consumerNumber, {
    int page = 1,
    int pageSize = AppConstants.historyPageSize,
  }) async {
    if (page < 1 || pageSize < 1 || pageSize > 100) {
      throw ArgumentError('Invalid utility history page bounds');
    }
    if (DemoDataService.isDemoMode) {
      final clean = consumerNumber.trim().toLowerCase();
      final docs = DemoDataService.getAllDocuments().where((d) {
        final cNum =
            d.utilityMetadata?.consumerNumber.trim().toLowerCase() ?? '';
        return cNum.isNotEmpty && cNum == clean;
      }).toList();
      docs.sort((a, b) {
        final byCreatedAt = b.createdAt.compareTo(a.createdAt);
        return byCreatedAt != 0 ? byCreatedAt : a.id.compareTo(b.id);
      });
      return docs.skip((page - 1) * pageSize).take(pageSize).toList();
    }

    try {
      final response = await _client
          .from('documents')
          .select('''
            *,
            document_categories(id, name, code, color_hex, icon),
            folders(id, name),
            profiles:uploaded_by(id, full_name, email),
            document_addresses(*),
            utility_metadata!inner(*),
            document_favorites(document_id, user_id)
          ''')
          .eq('utility_metadata.consumer_number', consumerNumber)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .order('id', ascending: true)
          .range((page - 1) * pageSize, page * pageSize - 1);

      final list = (response as List)
          .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_DATASET',
        'Error fetching utility connection history for $consumerNumber: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
