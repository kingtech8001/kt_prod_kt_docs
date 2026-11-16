import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/settings_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/utility_bills_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_connection_account.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_metadata_model.dart';
import 'package:kt_prod_kt_docs/app/modules/utility_bills/views/widgets/edit_utility_bill_dialog.dart';
import 'package:kt_prod_kt_docs/app/modules/utility_bills/views/widgets/upload_next_utility_bill_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class UtilityConnectionDetailController extends GetxController {
  final UtilityBillsDataset _dataset;
  final SettingsDataset _settingsDataset;

  UtilityConnectionDetailController(this._dataset, this._settingsDataset);

  final connection = Rxn<UtilityConnectionAccount>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final historyBills = <DocumentModel>[].obs;

  // Settings Locations
  final dynamicLocations = <MasterLocationModel>[].obs;
  final selectedLocation = Rxn<MasterLocationModel>();

  // Editable Form Controllers
  final premiseNameController = TextEditingController();
  final flatHouseNoController = TextEditingController();
  final buildingNameController = TextEditingController();
  final streetAddressController = TextEditingController();
  final areaLocalityController = TextEditingController();
  final cityController = TextEditingController();
  final postalCodeController = TextEditingController();
  final stateController = TextEditingController(text: 'Gujarat');
  final countryController = TextEditingController(text: 'India');
  final consumerNumberController = TextEditingController();
  final meterNumberController = TextEditingController();
  final providerNameController = TextEditingController();
  final utilityTypeController = TextEditingController();

  // Metrics
  final totalSpent = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      final locs = await _settingsDataset.getLocations(activeOnly: true);
      dynamicLocations.assignAll(locs);
    } catch (e, st) {
      AppLogger.error('UTILITY_DETAIL_CTRL', 'Error loading settings locations: $e', error: e, stackTrace: st);
    }

    final args = Get.arguments;
    if (args is UtilityConnectionAccount) {
      _populateFromAccount(args);
    } else {
      // Fallback: check query parameter
      final consumer = Get.parameters['consumerNumber'];
      if (consumer != null && consumer.isNotEmpty) {
        await _fetchAccountByConsumer(consumer);
        return;
      }
    }
    isLoading.value = false;
  }

  void _populateFromAccount(UtilityConnectionAccount acc) {
    connection.value = acc;
    historyBills.assignAll(acc.historicalBills);

    // Try to match setting location
    if (dynamicLocations.isNotEmpty) {
      final accPremise = (acc.premiseName ?? acc.displayName).toLowerCase().trim();
      final match = dynamicLocations.firstWhereOrNull((l) =>
          (l.premiseName?.toLowerCase().trim() == accPremise) ||
          (l.name.toLowerCase().trim() == accPremise) ||
          (accPremise.contains(l.name.toLowerCase().trim())) ||
          (l.name.toLowerCase().trim().contains(accPremise)));
      selectedLocation.value = match ?? dynamicLocations.first;
      if (match != null) {
        premiseNameController.text = match.premiseName ?? match.name;
        flatHouseNoController.text = match.flatHouseNo ?? '';
        buildingNameController.text = match.buildingName ?? '';
        streetAddressController.text = match.streetAddress ?? '';
        areaLocalityController.text = match.areaLocality;
        cityController.text = match.city;
        postalCodeController.text = match.postalCode ?? '';
        stateController.text = match.state;
        countryController.text = match.country;
      } else {
        premiseNameController.text = acc.premiseName ?? acc.displayName;
        flatHouseNoController.text = acc.flatHouseNo ?? '';
        buildingNameController.text = acc.buildingName ?? '';
        streetAddressController.text = acc.streetAddress ?? '';
        areaLocalityController.text = acc.areaLocality ?? '';
        cityController.text = acc.city ?? 'Rajkot';
        postalCodeController.text = acc.postalCode ?? '';
        stateController.text = acc.state;
        countryController.text = acc.country;
      }
    } else {
      premiseNameController.text = acc.premiseName ?? acc.displayName;
      flatHouseNoController.text = acc.flatHouseNo ?? '';
      buildingNameController.text = acc.buildingName ?? '';
      streetAddressController.text = acc.streetAddress ?? '';
      areaLocalityController.text = acc.areaLocality ?? '';
      cityController.text = acc.city ?? 'Rajkot';
      postalCodeController.text = acc.postalCode ?? '';
      stateController.text = acc.state;
      countryController.text = acc.country;
    }

    consumerNumberController.text = acc.consumerNumber;
    meterNumberController.text = acc.meterNumber ?? '';
    providerNameController.text = acc.providerName;
    utilityTypeController.text = acc.utilityType;

    _calculateTotalSpent();
  }

  void onLocationSelected(MasterLocationModel? loc) {
    selectedLocation.value = loc;
    if (loc != null) {
      premiseNameController.text = loc.premiseName ?? loc.name;
      flatHouseNoController.text = loc.flatHouseNo ?? '';
      buildingNameController.text = loc.buildingName ?? '';
      streetAddressController.text = loc.streetAddress ?? '';
      areaLocalityController.text = loc.areaLocality;
      cityController.text = loc.city;
      postalCodeController.text = loc.postalCode ?? '';
      stateController.text = loc.state;
      countryController.text = loc.country;
    }
  }

  void _calculateTotalSpent() {
    double sum = 0.0;
    for (final b in historyBills) {
      sum += (b.utilityMetadata?.billAmount ?? 0.0);
    }
    totalSpent.value = sum;
  }

  Future<void> _fetchAccountByConsumer(String consumerNumber) async {
    try {
      final bills = await _dataset.getUtilityConnectionHistory(consumerNumber);
      if (bills.isNotEmpty) {
        final accounts = UtilityConnectionAccount.groupFromDocuments(bills);
        if (accounts.isNotEmpty) {
          _populateFromAccount(accounts.first);
        }
      }
    } catch (e, st) {
      AppLogger.error('UTILITY_DETAIL_CTRL', 'Error fetching account: $e', error: e, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reloadHistory() async {
    final current = connection.value;
    if (current == null) return;
    try {
      final bills = await _dataset.getUtilityConnectionHistory(current.consumerNumber);
      historyBills.assignAll(bills);
      if (bills.isNotEmpty) {
        final accounts = UtilityConnectionAccount.groupFromDocuments(bills);
        if (accounts.isNotEmpty) {
          connection.value = accounts.first;
        }
      }
      _calculateTotalSpent();
    } catch (e, st) {
      AppLogger.error('UTILITY_DETAIL_CTRL', 'Error reloading history: $e', error: e, stackTrace: st);
    }
  }

  Future<void> saveConnectionDetails() async {
    final current = connection.value;
    if (current == null) return;

    final loc = selectedLocation.value;
    final newPremise = loc != null
        ? (loc.premiseName ?? loc.name)
        : premiseNameController.text.trim();
    final newConsumer = consumerNumberController.text.trim();
    final newProvider = providerNameController.text.trim();
    final newCity = loc?.city ?? (cityController.text.trim().isNotEmpty ? cityController.text.trim() : 'Rajkot');

    if (newConsumer.isEmpty) {
      AppSnackbar.showError('Validation Error', 'Consumer number is required.');
      return;
    }
    if (newProvider.isEmpty) {
      AppSnackbar.showError('Validation Error', 'Provider name is required.');
      return;
    }

    isSaving.value = true;
    try {
      final newFlat = loc?.flatHouseNo ??
          (flatHouseNoController.text.trim().isNotEmpty
              ? flatHouseNoController.text.trim()
              : null);
      final newBuilding = loc?.buildingName ??
          (buildingNameController.text.trim().isNotEmpty
              ? buildingNameController.text.trim()
              : null);
      final newStreet = loc?.streetAddress ??
          (streetAddressController.text.trim().isNotEmpty
              ? streetAddressController.text.trim()
              : null);
      final newArea = loc != null
          ? loc.areaLocality
          : (areaLocalityController.text.trim().isNotEmpty
              ? areaLocalityController.text.trim()
              : 'General');
      final newPostal = loc?.postalCode ??
          (postalCodeController.text.trim().isNotEmpty
              ? postalCodeController.text.trim()
              : null);
      final newState = loc?.state ??
          (stateController.text.trim().isNotEmpty
              ? stateController.text.trim()
              : 'Gujarat');
      final newCountry = loc?.country ??
          (countryController.text.trim().isNotEmpty
              ? countryController.text.trim()
              : 'India');

      await _dataset.updateConnectionAccountDetails(
        oldConsumerNumber: current.consumerNumber,
        newConsumerNumber: newConsumer,
        meterNumber: meterNumberController.text.trim().isNotEmpty
            ? meterNumberController.text.trim()
            : null,
        providerName: newProvider,
        utilityType: utilityTypeController.text.trim().isNotEmpty
            ? utilityTypeController.text.trim()
            : current.utilityType,
        premiseName: newPremise.isNotEmpty ? newPremise : null,
        flatHouseNo: newFlat,
        buildingName: newBuilding,
        streetAddress: newStreet,
        areaLocality: newArea,
        city: newCity,
        state: newState,
        postalCode: newPostal,
        country: newCountry,
      );

      await reloadHistory();
      AppSnackbar.showSuccess(
        'Details Saved',
        'Account & address details updated successfully for $newPremise.',
      );
    } catch (e, st) {
      AppLogger.error('UTILITY_DETAIL_CTRL', 'Error saving account details: $e', error: e, stackTrace: st);
      AppSnackbar.showError('Save Failed', 'Could not save account details: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> openEditBillCycleDialog(DocumentModel bill) async {
    final success = await EditUtilityBillDialog.show(
      bill: bill,
      onSave: ({
        required documentId,
        required title,
        description,
        required billAmount,
        required billDate,
        dueDate,
        required paymentStatus,
        paymentDate,
        paymentReferenceId,
        meterNumber,
        unitsConsumed,
      }) async {
        await _dataset.updateUtilityBillCycle(
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
      },
    );

    if (success == true) {
      await reloadHistory();
      AppSnackbar.showSuccess(
        'Bill Cycle Saved',
        'Updated bill details for "${bill.title}" successfully.',
      );
    }
  }

  Future<void> openUploadNextBillDialog() async {
    final current = connection.value;
    if (current == null) return;

    final success = await UploadNextUtilityBillDialog.show(
      connection: current,
      onLogBill: ({
        required consumerNumber,
        meterNumber,
        required providerName,
        required utilityType,
        premiseName,
        flatHouseNo,
        city,
        required title,
        description,
        required billAmount,
        required billDate,
        dueDate,
        required paymentStatus,
        paymentDate,
        paymentReferenceId,
        required fileBytes,
        required fileName,
      }) async {
        await _dataset.logNextUtilityBill(
          consumerNumber: consumerNumber,
          meterNumber: meterNumber,
          providerName: providerName,
          utilityType: utilityType,
          premiseName: premiseName,
          flatHouseNo: flatHouseNo,
          city: city,
          title: title,
          description: description,
          billAmount: billAmount,
          billDate: billDate,
          dueDate: dueDate,
          paymentStatus: paymentStatus,
          paymentDate: paymentDate,
          paymentReferenceId: paymentReferenceId,
          fileBytes: fileBytes,
          fileName: fileName,
        );
      },
    );

    if (success == true) {
      await reloadHistory();
      AppSnackbar.showSuccess(
        'Bill Logged',
        'New bill cycle logged successfully for ${current.displayName}.',
      );
    }
  }

  Future<void> togglePaymentStatus(DocumentModel doc) async {
    final meta = doc.utilityMetadata;
    if (meta == null) return;

    final currentPaid = meta.isPaid;
    final newPaid = !currentPaid;

    try {
      await _dataset.updatePaymentStatus(
        metadataId: meta.id ?? doc.id,
        isPaid: newPaid,
        paymentDate: newPaid ? DateTime.now().toIso8601String().split('T').first : null,
      );

      final index = historyBills.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        final updatedMeta = UtilityMetadataModel(
          id: meta.id,
          documentId: meta.documentId,
          utilityType: meta.utilityType,
          providerName: meta.providerName,
          consumerNumber: meta.consumerNumber,
          meterNumber: meta.meterNumber,
          billDate: meta.billDate,
          dueDate: meta.dueDate,
          billingPeriodStart: meta.billingPeriodStart,
          billingPeriodEnd: meta.billingPeriodEnd,
          billAmount: meta.billAmount,
          paymentStatus: newPaid ? 'paid' : 'pending',
          paymentDate: newPaid ? DateTime.now() : null,
          paymentReferenceId: meta.paymentReferenceId,
          unitsConsumed: meta.unitsConsumed,
        );
        historyBills[index] = doc.copyWith(utilityMetadata: updatedMeta);
      }
      _calculateTotalSpent();

      AppSnackbar.showSuccess(
        'Status Updated',
        '${doc.title} marked as ${newPaid ? "PAID" : "PENDING"}.',
      );
    } catch (e) {
      AppSnackbar.showError('Update Failed', 'Failed to update payment status: $e');
    }
  }

  Future<void> previewDocument(DocumentModel doc) async {
    try {
      final resolvedUrl = (doc.isGoogleAttachment ||
              doc.filePath.startsWith('gdrive://') ||
              doc.filePath.startsWith('http://') ||
              doc.filePath.startsWith('https://'))
          ? (doc.googleAttachmentUrl ??
              (doc.filePath.startsWith('gdrive://')
                  ? 'https://drive.google.com/file/d/${doc.filePath.replaceFirst("gdrive://", "")}/preview'
                  : doc.filePath))
          : await _dataset.getSignedPreviewUrl(doc.filePath);

      if (doc.isImage) {
        ImageLightboxDialog.show(
          title: doc.title,
          imageUrl: resolvedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
      } else {
        PdfViewerDialog.show(
          title: doc.title,
          filePath: doc.filePath,
          signedPdfUrl: resolvedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
      }
    } catch (e) {
      AppSnackbar.showError('Preview Failed', 'Could not generate preview: $e');
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    try {
      if (doc.isGoogleAttachment ||
          doc.filePath.startsWith('gdrive://') ||
          doc.filePath.startsWith('http://') ||
          doc.filePath.startsWith('https://')) {
        final gUrl = doc.googleAttachmentUrl ??
            (doc.filePath.startsWith('gdrive://')
                ? 'https://drive.google.com/file/d/${doc.filePath.replaceFirst("gdrive://", "")}/view?usp=sharing'
                : doc.filePath);
        final uri = Uri.tryParse(gUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      final signedUrl = await _dataset.getSignedPreviewUrl(doc.filePath, download: true);
      await FileApiHelper.downloadFileFromUrl(
        url: signedUrl,
        fileName: doc.fileName,
        mimeType: doc.mimeType,
      );
      AppSnackbar.showSuccess('Download Started', '${doc.fileName} is downloading.');
    } catch (e) {
      AppSnackbar.showError('Download Failed', 'Could not download file: $e');
    }
  }

  @override
  void onClose() {
    premiseNameController.dispose();
    flatHouseNoController.dispose();
    buildingNameController.dispose();
    streetAddressController.dispose();
    areaLocalityController.dispose();
    cityController.dispose();
    postalCodeController.dispose();
    stateController.dispose();
    countryController.dispose();
    consumerNumberController.dispose();
    meterNumberController.dispose();
    providerNameController.dispose();
    utilityTypeController.dispose();
    super.onClose();
  }
}
