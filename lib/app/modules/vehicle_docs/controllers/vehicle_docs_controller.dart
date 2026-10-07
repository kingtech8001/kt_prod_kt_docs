import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/vehicle_docs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/views/widgets/add_vehicle_dialog.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/views/widgets/add_vehicle_service_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_download_helper.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDocsController extends GetxController {
  final VehicleDocsDataset _dataset;

  VehicleDocsController(this._dataset);

  // Section Tab: 0 = Documents & Passes, 1 = Service & Maintenance Logs
  final selectedTab = 0.obs;

  // Loading & Pagination State (Infinite Scroll)
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final currentPage = 1.obs;
  final pageSize = 20;
  final totalCount = 0.obs;

  final scrollController = ScrollController();
  final searchController = TextEditingController();

  // Data Collections
  final vehicleDocuments = <DocumentModel>[].obs;
  final masterVehicles = <MasterVehicleModel>[].obs;
  final masterDocTypes = <MasterVehicleDocTypeModel>[].obs;
  final vehicleServices = <VehicleServiceModel>[].obs;
  final isLoadingServices = false.obs;

  // Selection & Filters
  final selectedVehicle = Rx<MasterVehicleModel?>(null);
  final selectedDocType = 'All Docs'.obs;
  final selectedExpiryFilter = 'All'.obs; // 'All', 'Active', 'Expiring in 30 Days', 'Expired'
  final searchQuery = ''.obs;
  final isGridView = true.obs;

  // Aggregated Summary Metrics
  final totalDocumentsCount = 0.obs;
  final totalVehiclesCount = 0.obs;
  final expiringSoonCount = 0.obs;
  final expiredCount = 0.obs;

  Timer? _searchDebounceTimer;

  // Role Permissions
  bool get canDelete {
    try {
      return AuthService.to.isAdmin;
    } catch (_) {
      return false;
    }
  }

  bool get canEdit {
    try {
      final role = AuthService.to.currentProfile.value?.role.toLowerCase();
      return role == 'admin' || role == 'super_admin' || role == 'editor';
    } catch (_) {
      return true;
    }
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadMasterData();
    loadVehicleDocuments(resetPage: true);
    loadVehicleServices();
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    if (maxScroll > 100 && currentScroll >= maxScroll - 200) {
      loadNextPage();
    }
  }

  Future<void> loadMasterData() async {
    try {
      final vehicles = await _dataset.getMasterVehicles(activeOnly: true);
      masterVehicles.assignAll(vehicles);

      final docTypes = await _dataset.getMasterVehicleDocTypes(activeOnly: true);
      masterDocTypes.assignAll(docTypes);
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_CTRL',
        'Error loading master vehicle data: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> loadVehicleDocuments({bool resetPage = false}) async {
    if (resetPage) {
      currentPage.value = 1;
      hasMore.value = true;
      isLoading.value = true;
      vehicleDocuments.clear();
    }

    try {
      final response = await _dataset.getVehicleDocuments(
        page: currentPage.value,
        pageSize: pageSize,
        vehicleNumber: selectedVehicle.value?.vehicleNumber,
        docType: selectedDocType.value != 'All Docs'
            ? selectedDocType.value
            : null,
        expiryFilter: selectedExpiryFilter.value,
        searchQuery: searchQuery.value,
      );

      if (resetPage) {
        vehicleDocuments.assignAll(response.documents);
      } else {
        vehicleDocuments.addAll(response.documents);
      }

      totalCount.value = response.totalCount;
      totalDocumentsCount.value = response.totalDocumentsCount;
      totalVehiclesCount.value = response.totalVehiclesCount;
      expiringSoonCount.value = response.expiringSoonCount;
      expiredCount.value = response.expiredCount;

      hasMore.value = response.documents.length >= pageSize;
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_CTRL',
        'Error loading vehicle documents: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError(
        'Loading Failed',
        'Unable to load vehicle documents. Please try again.',
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadVehicleServices() async {
    try {
      isLoadingServices.value = true;
      final list = await _dataset.getVehicleServices(
        vehicleId: selectedVehicle.value?.id,
      );
      vehicleServices.assignAll(list);
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_CTRL',
        'Error loading vehicle services: $e',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoadingServices.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    currentPage.value++;
    await loadVehicleDocuments(resetPage: false);
  }

  // --- Filtering & Selection Actions ---

  void selectVehicle(MasterVehicleModel? vehicle) {
    if (selectedVehicle.value?.id == vehicle?.id) return;
    selectedVehicle.value = vehicle;
    selectedDocType.value = 'All Docs';
    loadVehicleDocuments(resetPage: true);
    loadVehicleServices();
  }

  void selectDocType(String docType) {
    if (selectedDocType.value == docType) return;
    selectedDocType.value = docType;
    loadVehicleDocuments(resetPage: true);
  }

  void selectExpiryFilter(String filter) {
    if (selectedExpiryFilter.value == filter) return;
    selectedExpiryFilter.value = filter;
    loadVehicleDocuments(resetPage: true);
  }

  void onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      searchQuery.value = query.trim();
      loadVehicleDocuments(resetPage: true);
    });
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    loadVehicleDocuments(resetPage: true);
  }

  void toggleViewMode() {
    isGridView.value = !isGridView.value;
  }

  void setTab(int index) {
    selectedTab.value = index;
  }

  // --- Service Intelligence Computed Helpers ---

  VehicleServiceModel? get latestService {
    if (vehicleServices.isEmpty) return null;
    return vehicleServices.first;
  }

  double get totalServiceCost =>
      vehicleServices.fold(0.0, (sum, item) => sum + item.costAmount);

  // --- Vehicle Master Management Actions ---

  Future<void> openAddVehicleDialog() async {
    final success = await AddVehicleDialog.show(
      onSave: (newVehicle) async {
        final created = await _dataset.createMasterVehicle(newVehicle);
        masterVehicles.add(created);
        masterVehicles.sort((a, b) => a.vehicleNumber.compareTo(b.vehicleNumber));
        selectedVehicle.value = created;
        loadVehicleDocuments(resetPage: true);
        loadVehicleServices();
      },
    );
    if (success == true) {
      AppSnackbar.showSuccess(
        'Vehicle Registered',
        'Vehicle added and selected successfully.',
      );
    }
  }

  Future<void> openEditVehicleDialog(MasterVehicleModel vehicle) async {
    final success = await AddVehicleDialog.show(
      vehicleToEdit: vehicle,
      onSave: (updated) async {
        await _dataset.updateMasterVehicle(updated);
        final index = masterVehicles.indexWhere((v) => v.id == updated.id);
        if (index != -1) {
          masterVehicles[index] = updated;
        }
        if (selectedVehicle.value?.id == updated.id) {
          selectedVehicle.value = updated;
        }
      },
    );
    if (success == true) {
      AppSnackbar.showSuccess(
        'Vehicle Updated',
        '${vehicle.vehicleNumber} updated successfully.',
      );
    }
  }

  // --- Vehicle Service Record Management Actions ---

  Future<void> openAddServiceDialog() async {
    final success = await AddVehicleServiceDialog.show(
      vehicles: masterVehicles,
      initialVehicle: selectedVehicle.value,
      onSave: (newService) async {
        final created = await _dataset.createVehicleService(newService);
        vehicleServices.insert(0, created);
        vehicleServices.sort((a, b) {
          final comp = b.serviceDate.compareTo(a.serviceDate);
          if (comp != 0) return comp;
          return b.odometerKm.compareTo(a.odometerKm);
        });
      },
    );
    if (success == true) {
      AppSnackbar.showSuccess(
        'Service Logged',
        'Service record added successfully.',
      );
    }
  }

  Future<void> openEditServiceDialog(VehicleServiceModel service) async {
    final success = await AddVehicleServiceDialog.show(
      vehicles: masterVehicles,
      serviceToEdit: service,
      onSave: (updated) async {
        final saved = await _dataset.updateVehicleService(updated);
        final idx = vehicleServices.indexWhere((s) => s.id == saved.id);
        if (idx != -1) {
          vehicleServices[idx] = saved;
        }
        vehicleServices.sort((a, b) {
          final comp = b.serviceDate.compareTo(a.serviceDate);
          if (comp != 0) return comp;
          return b.odometerKm.compareTo(a.odometerKm);
        });
      },
    );
    if (success == true) {
      AppSnackbar.showSuccess(
        'Service Updated',
        'Service record updated successfully.',
      );
    }
  }

  Future<void> deleteServiceRecord(VehicleServiceModel service) async {
    final confirmed = await AppDialog.show<bool>(
      AlertDialog(
        title: const Text('Delete Service Record'),
        content: Text(
          'Are you sure you want to delete the service record for ${service.odometerKm} KM on ${service.serviceDate.toIso8601String().split('T').first}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dataset.deleteVehicleService(service.id);
        vehicleServices.removeWhere((s) => s.id == service.id);
        AppSnackbar.showSuccess(
          'Deleted',
          'Service record has been removed.',
        );
      } catch (e) {
        AppSnackbar.showError(
          'Delete Failed',
          'Could not delete service record: $e',
        );
      }
    }
  }

  // --- Document Interaction Actions ---

  Future<void> previewDocument(DocumentModel doc) async {
    try {
      AppLogger.info('VEHICLE_DOCS_CTRL', 'Opening preview for doc: ${doc.id}');
      final url = await _dataset.getSignedPreviewUrl(doc.filePath);

      final mime = doc.mimeType.toLowerCase();
      final fileType = doc.fileType.toLowerCase();
      final isPdf = mime.contains('pdf') || fileType == 'pdf';
      final isImage = mime.contains('image') ||
          ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(fileType);

      if (isPdf) {
        PdfViewerDialog.show(
          title: doc.title,
          signedPdfUrl: url,
          fileName: doc.fileName,
        );
      } else if (isImage) {
        ImageLightboxDialog.show(
          title: doc.title,
          imageUrl: url,
        );
      } else {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          AppSnackbar.showError(
            'Preview Unavailable',
            'Unable to open file type ($fileType).',
          );
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_CTRL',
        'Error opening preview: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError(
        'Preview Error',
        'Could not load document preview.',
      );
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    try {
      AppLogger.info('VEHICLE_DOCS_CTRL', 'Downloading doc: ${doc.id}');
      final bytes = await _dataset.downloadFileBytes(doc.filePath);
      FileDownloadHelper.download(
        bytes: bytes,
        fileName: doc.fileName,
        mimeType: doc.mimeType,
      );
      AppSnackbar.showSuccess(
        'Download Complete',
        '${doc.fileName} downloaded successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_CTRL',
        'Error downloading document: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError(
        'Download Failed',
        'Could not download ${doc.fileName}.',
      );
    }
  }

  Future<void> shareDocument(DocumentModel doc) async {
    try {
      final token = await _dataset.createShareLink(doc.id);
      final shareUrl = '${AppConstants.webBaseUrl}/share/$token';

      ShareDocumentDialog.show(
        documentTitle: doc.title,
        shareUrl: shareUrl,
      );
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_CTRL',
        'Error creating share link: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError(
        'Share Failed',
        'Could not create shareable link.',
      );
    }
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    try {
      final newStatus = await _dataset.toggleFavorite(doc.id, doc.isFavorite);
      final index = vehicleDocuments.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        vehicleDocuments[index] = doc.copyWith(isFavorite: newStatus);
      }
    } catch (e) {
      AppLogger.error('VEHICLE_DOCS_CTRL', 'Error toggling favorite: $e');
    }
  }

  Future<void> softDeleteDocument(DocumentModel doc) async {
    if (!canDelete) {
      AppSnackbar.showError(
        'Permission Denied',
        'Only administrators can delete documents.',
      );
      return;
    }

    final confirmed = await AppDialog.show<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text('Move to Trash?'),
          ],
        ),
        content: Text(
          'Are you sure you want to move "${doc.title}" to trash? You can restore it later from Trash.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _dataset.softDeleteDocument(doc.id);
      vehicleDocuments.removeWhere((d) => d.id == doc.id);
      totalCount.value = totalCount.value > 0 ? totalCount.value - 1 : 0;
      totalDocumentsCount.value =
          totalDocumentsCount.value > 0 ? totalDocumentsCount.value - 1 : 0;

      AppSnackbar.showSuccess(
        'Moved to Trash',
        '"${doc.title}" has been moved to trash.',
      );
    } catch (e, st) {
      AppLogger.error(
        'VEHICLE_DOCS_CTRL',
        'Error soft deleting document: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError(
        'Delete Failed',
        'Could not delete "${doc.title}".',
      );
    }
  }

  void openEditDocumentDialog(DocumentModel doc) {
    if (!canEdit) {
      AppSnackbar.showError(
        'Permission Denied',
        'You do not have permission to edit this document.',
      );
      return;
    }

    DocumentEditDialog.show(
      document: doc,
      onSave: ({
        required title,
        description,
        documentNumber,
        applianceWarranty,
        vehicleMetadata,
        newFileName,
        newFileBytes,
        newMimeType,
        attachmentUrl,
      }) async {
        try {
          await _dataset.updateDocumentDetails(
            documentId: doc.id,
            title: title,
            description: description,
            documentNumber: documentNumber,
            vehicleMetadata: vehicleMetadata,
          );
          await loadVehicleDocuments();
        } catch (e, st) {
          AppLogger.error(
            'VEHICLE_DOCS_CTRL',
            'Error editing vehicle document: $e',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      },
    );
  }
}
