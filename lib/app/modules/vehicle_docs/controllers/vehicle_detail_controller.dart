import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/vehicle_docs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/views/widgets/add_vehicle_service_dialog.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/views/widgets/renew_vehicle_doc_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDetailController extends GetxController {
  final VehicleDocsDataset _dataset;

  VehicleDetailController(this._dataset);

  final vehicle = Rxn<MasterVehicleModel>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final formError = ''.obs;

  // Role Permissions
  bool get canEdit {
    try {
      return AuthService.to.canEdit;
    } catch (error, stackTrace) {
      AppLogger.error(
        'VEHICLE_DETAIL_CONTROLLER',
        'Operation failed; applying fallback.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Editable Form Controllers
  final vehicleNumberController = TextEditingController();
  final nicknameController = TextEditingController();
  final brandMakeController = TextEditingController();
  final modelNameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final chassisNumberController = TextEditingController();
  final engineNumberController = TextEditingController();
  final selectedVehicleType = 'Four Wheeler'.obs;
  final selectedFuelType = 'Petrol'.obs;
  final registrationDate = Rxn<DateTime>();

  // Data Collections for History
  final documents = <DocumentModel>[].obs;
  final services = <VehicleServiceModel>[].obs;
  final selectedHistoryTab =
      0.obs; // 0 = Documents & Policies, 1 = Service History
  final selectedDocSubFilter =
      'All'.obs; // All, Insurance, PUC, RC & Registration

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  void _loadInitialData() {
    isLoading.value = true;
    final args = Get.arguments;
    if (args is MasterVehicleModel) {
      _populateFromVehicle(args);
      _loadHistory(args.vehicleNumber);
    } else {
      final regNumber = Get.parameters['regNumber'] ?? Get.parameters['id'];
      if (regNumber != null && regNumber.isNotEmpty) {
        _fetchVehicleByNumber(regNumber);
        return;
      }
      isLoading.value = false;
    }
  }

  void _populateFromVehicle(MasterVehicleModel v) {
    vehicle.value = v;
    vehicleNumberController.text = v.vehicleNumber;
    nicknameController.text = v.nickname ?? '';
    brandMakeController.text = v.brandMake ?? '';
    modelNameController.text = v.modelName ?? '';
    ownerNameController.text = v.ownerName ?? '';
    chassisNumberController.text = v.chassisNumber ?? '';
    engineNumberController.text = v.engineNumber ?? '';
    selectedVehicleType.value = v.vehicleType;
    selectedFuelType.value = v.fuelType ?? 'Petrol';
    registrationDate.value = v.registrationDate;
  }

  Future<void> _fetchVehicleByNumber(String regNumber) async {
    try {
      final vehicles = await _dataset.getMasterVehicles();
      final match = vehicles.firstWhereOrNull(
        (v) =>
            v.vehicleNumber.toUpperCase() == regNumber.toUpperCase() ||
            v.id == regNumber,
      );
      if (match != null) {
        _populateFromVehicle(match);
        await _loadHistory(match.vehicleNumber);
      }
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DETAIL_CTRL',
        'Error loading vehicle: $e',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadHistory(String vehicleNumber) async {
    try {
      isLoading.value = true;
      final docsResponse = await _dataset.getVehicleDocuments(
        vehicleNumber: vehicleNumber,
        page: 1,
        pageSize: 100,
      );
      documents.assignAll(docsResponse.documents);

      final serviceList = await _dataset.getVehicleServices(
        vehicleId: vehicle.value?.id,
      );
      services.assignAll(serviceList);
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DETAIL_CTRL',
        'Error loading history: $e',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reloadData() async {
    final current = vehicle.value;
    if (current == null) return;
    await _loadHistory(current.vehicleNumber);
  }

  Future<void> saveVehicleDetails() async {
    if (isSaving.value) return;
    formError.value = '';
    final current = vehicle.value;
    if (current == null) return;

    if (!canEdit) {
      formError.value = 'Your role cannot edit vehicle details.';
      return;
    }

    final regNumber = vehicleNumberController.text.trim().toUpperCase();
    if (regNumber.isEmpty) {
      formError.value = 'Vehicle registration number is required.';
      return;
    }

    isSaving.value = true;
    try {
      final updatedVehicle = current.copyWith(
        vehicleNumber: regNumber,
        nickname: nicknameController.text.trim().isNotEmpty
            ? nicknameController.text.trim()
            : null,
        brandMake: brandMakeController.text.trim().isNotEmpty
            ? brandMakeController.text.trim()
            : null,
        modelName: modelNameController.text.trim().isNotEmpty
            ? modelNameController.text.trim()
            : null,
        vehicleType: selectedVehicleType.value,
        fuelType: selectedFuelType.value,
        ownerName: ownerNameController.text.trim().isNotEmpty
            ? ownerNameController.text.trim()
            : null,
        chassisNumber: chassisNumberController.text.trim().isNotEmpty
            ? chassisNumberController.text.trim()
            : null,
        engineNumber: engineNumberController.text.trim().isNotEmpty
            ? engineNumberController.text.trim()
            : null,
        registrationDate: registrationDate.value,
        updatedAt: DateTime.now(),
      );

      await _dataset.updateMasterVehicle(updatedVehicle);
      vehicle.value = updatedVehicle;

      AppSnackbar.showSuccess(
        'Vehicle Saved',
        'Vehicle details for $regNumber have been updated successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DETAIL_CTRL',
        'Error saving vehicle details: $e',
        error: e,
        stackTrace: st,
      );
      formError.value = 'Could not save vehicle details: $e';
    } finally {
      isSaving.value = false;
    }
  }

  // Filtered documents
  List<DocumentModel> get filteredDocuments {
    final filter = selectedDocSubFilter.value;
    if (filter == 'All') return documents;
    if (filter == 'Insurance') {
      return documents.where((d) {
        final t = (d.vehicleMetadata?.docTypeName ?? d.subCategory)
            .toLowerCase();
        return t.contains('insurance') || t.contains('policy');
      }).toList();
    }
    if (filter == 'PUC') {
      return documents.where((d) {
        final t = (d.vehicleMetadata?.docTypeName ?? d.subCategory)
            .toLowerCase();
        return t.contains('puc') || t.contains('emission');
      }).toList();
    }
    if (filter == 'RC & Registration') {
      return documents.where((d) {
        final t = (d.vehicleMetadata?.docTypeName ?? d.subCategory)
            .toLowerCase();
        return t.contains('rc') ||
            t.contains('registration') ||
            t.contains('smart card') ||
            t.contains('tax');
      }).toList();
    }
    return documents;
  }

  // Document actions
  Future<void> previewDocument(DocumentModel doc) async {
    try {
      final resolvedUrl =
          (doc.isGoogleAttachment ||
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
      AppSnackbar.showError('Preview Failed', 'Could not preview file: $e');
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    try {
      if (doc.isGoogleAttachment ||
          doc.filePath.startsWith('gdrive://') ||
          doc.filePath.startsWith('http://') ||
          doc.filePath.startsWith('https://')) {
        final gUrl =
            doc.googleAttachmentUrl ??
            (doc.filePath.startsWith('gdrive://')
                ? 'https://drive.google.com/file/d/${doc.filePath.replaceFirst("gdrive://", "")}/view?usp=sharing'
                : doc.filePath);
        final uri = Uri.tryParse(gUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      final signedUrl = await _dataset.getSignedPreviewUrl(
        doc.filePath,
        download: true,
      );
      await FileApiHelper.downloadFileFromUrl(
        url: signedUrl,
        fileName: doc.fileName,
        mimeType: doc.mimeType,
      );
      AppSnackbar.showSuccess(
        'Downloaded',
        'File downloading: ${doc.fileName}',
      );
    } catch (e) {
      AppSnackbar.showError('Download Failed', 'Could not download file: $e');
    }
  }

  Future<void> openRenewDialog(DocumentModel doc) async {
    final success = await RenewVehicleDocDialog.show(
      previousDocument: doc,
      onRenew:
          ({
            required previousDocument,
            required newMetadata,
            required newTitle,
            required fileBytes,
            required fileName,
            newDescription,
          }) async {
            await _dataset.renewVehicleDocument(
              previousDocument: previousDocument,
              newMetadata: newMetadata,
              newTitle: newTitle,
              fileBytes: fileBytes,
              fileName: fileName,
              newDescription: newDescription,
            );
          },
    );

    if (success == true) {
      await reloadData();
      AppSnackbar.showSuccess(
        'Renewal Activated',
        'Document renewed successfully with full version lineage.',
      );
    }
  }

  Future<void> openAddServiceDialog() async {
    final cur = vehicle.value;
    if (cur == null) return;

    final success = await AddVehicleServiceDialog.show(
      vehicles: [cur],
      initialVehicle: cur,
      onSave: (service) async {
        await _dataset.createVehicleService(service);
      },
    );

    if (success == true) {
      await reloadData();
      AppSnackbar.showSuccess('Service Logged', 'Service entry saved.');
    }
  }

  Future<void> openEditServiceDialog(VehicleServiceModel service) async {
    final cur = vehicle.value;
    if (cur == null) return;

    final success = await AddVehicleServiceDialog.show(
      vehicles: [cur],
      initialVehicle: cur,
      serviceToEdit: service,
      onSave: (updated) async {
        await _dataset.updateVehicleService(updated);
      },
    );

    if (success == true) {
      await reloadData();
      AppSnackbar.showSuccess('Service Updated', 'Service entry updated.');
    }
  }

  @override
  void onClose() {
    vehicleNumberController.dispose();
    nicknameController.dispose();
    brandMakeController.dispose();
    modelNameController.dispose();
    ownerNameController.dispose();
    chassisNumberController.dispose();
    engineNumberController.dispose();
    super.onClose();
  }
}
