import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/appliance_vault_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplianceVaultController extends GetxController {
  final ApplianceVaultDataset _dataset;

  ApplianceVaultController(this._dataset);

  // Loading & Pagination State
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final currentPage = 1.obs;
  final pageSize = 20;
  final totalCount = 0.obs;

  final scrollController = ScrollController();
  final searchController = TextEditingController();

  // Data Collections
  final applianceDocuments = <DocumentModel>[].obs;
  final dynamicBrands = <String>[].obs;
  final dynamicSubcategories = <String>[].obs;

  // Reactive Filters
  final selectedBrand = 'All Brands'.obs;
  final selectedSubcategory = 'All Appliances'.obs;
  final selectedWarrantyStatus =
      'all'.obs; // 'all', 'active', 'expiring_soon', 'expired', 'no_warranty'
  final searchQuery = ''.obs;

  // Aggregated Summary Metrics
  final totalAppliancesCount = 0.obs;
  final activeWarrantiesCount = 0.obs;
  final expiringSoonCount = 0.obs;
  final expiredCount = 0.obs;

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
    loadApplianceVault(resetPage: true);
  }

  @override
  void onClose() {
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
      final brandsList = await _dataset.getMasterBrands(activeOnly: true);
      final names = brandsList.map((b) => b.name).toList();
      if (!names.contains('Other')) {
        names.add('Other');
      }
      dynamicBrands.assignAll(names);

      final subsList = await _dataset.getApplianceSubcategories(activeOnly: true);
      final subs = subsList.map((s) => s.name).toList();
      if (!subs.contains('Other')) {
        subs.add('Other');
      }
      dynamicSubcategories.assignAll(subs);
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_CTRL',
        'Error loading master data: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> loadApplianceVault({bool resetPage = false}) async {
    if (resetPage) {
      currentPage.value = 1;
      hasMore.value = true;
      isLoading.value = true;
    }

    AppLogger.debug(
      'APPLIANCE_CTRL',
      'Loading appliance vault (page: ${currentPage.value}, brand: ${selectedBrand.value}, sub: ${selectedSubcategory.value}, status: ${selectedWarrantyStatus.value})',
    );

    try {
      final response = await _dataset.getApplianceVault(
        page: currentPage.value,
        pageSize: pageSize,
        brand: selectedBrand.value != 'All Brands' ? selectedBrand.value : null,
        subCategory: selectedSubcategory.value != 'All Appliances'
            ? selectedSubcategory.value
            : null,
        warrantyStatus: selectedWarrantyStatus.value != 'all'
            ? selectedWarrantyStatus.value
            : null,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      applianceDocuments.assignAll(response.documents);
      totalCount.value = response.totalCount;
      totalAppliancesCount.value = response.totalAppliancesCount;
      activeWarrantiesCount.value = response.activeWarrantiesCount;
      expiringSoonCount.value = response.expiringSoonCount;
      expiredCount.value = response.expiredCount;

      hasMore.value = applianceDocuments.length < totalCount.value;
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_CTRL',
        'Error loading appliance vault: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Appliance Vault', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    final nextPage = currentPage.value + 1;

    AppLogger.debug('APPLIANCE_CTRL', 'Loading next page: $nextPage...');

    try {
      final response = await _dataset.getApplianceVault(
        page: nextPage,
        pageSize: pageSize,
        brand: selectedBrand.value != 'All Brands' ? selectedBrand.value : null,
        subCategory: selectedSubcategory.value != 'All Appliances'
            ? selectedSubcategory.value
            : null,
        warrantyStatus: selectedWarrantyStatus.value != 'all'
            ? selectedWarrantyStatus.value
            : null,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      if (response.documents.isEmpty) {
        hasMore.value = false;
      } else {
        applianceDocuments.addAll(response.documents);
        currentPage.value = nextPage;
        hasMore.value = applianceDocuments.length < totalCount.value;
      }
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_CTRL',
        'Error loading more appliances: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Failed to load more', e.toString());
    } finally {
      isLoadingMore.value = false;
    }
  }

  void onBrandSelected(String brand) {
    if (selectedBrand.value == brand) return;
    selectedBrand.value = brand;
    loadApplianceVault(resetPage: true);
  }

  void onSubcategorySelected(String subcategory) {
    if (selectedSubcategory.value == subcategory) return;
    selectedSubcategory.value = subcategory;
    loadApplianceVault(resetPage: true);
  }

  void onWarrantyStatusSelected(String status) {
    if (selectedWarrantyStatus.value == status) return;
    selectedWarrantyStatus.value = status;
    loadApplianceVault(resetPage: true);
  }

  void onSearchChanged(String val) {
    searchQuery.value = val;
    loadApplianceVault(resetPage: true);
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    loadApplianceVault(resetPage: true);
  }

  Future<void> previewDocument(DocumentModel doc) async {
    try {
      final signedUrl = await _dataset.getSignedPreviewUrl(doc.filePath);
      if (doc.isPdf) {
        PdfViewerDialog.show(
          title: doc.title,
          signedPdfUrl: signedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
      } else if (doc.isImage) {
        ImageLightboxDialog.show(
          title: doc.title,
          imageUrl: signedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
      } else {
        final uri = Uri.parse(signedUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_CTRL',
        'Error opening preview: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Preview Error', e.toString());
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    try {
      final signedUrl = await _dataset.getSignedPreviewUrl(doc.filePath, download: true);
      await FileApiHelper.downloadFileFromUrl(
        url: signedUrl,
        fileName: doc.fileName,
        mimeType: doc.mimeType,
      );
      AppSnackbar.showSuccess('Download Started', '${doc.fileName} is downloading.');
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_CTRL',
        'Error downloading: $e',
        error: e,
        stackTrace: st,
      );
      try {
        final fallbackUrl = await _dataset.getSignedPreviewUrl(doc.filePath, download: true);
        final uri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (_) {
        AppSnackbar.showError('Download Error', e.toString());
      }
    }
  }

  void openDocument(DocumentModel doc) {
    previewDocument(doc);
  }

  void shareDocument(DocumentModel doc) {
    openShareDialog(doc);
  }

  Future<void> openShareDialog(DocumentModel doc) async {
    try {
      final token = await _dataset.createShareLink(doc.id);
      final shareUrl = '${AppConstants.webBaseUrl}/share/$token';
      ShareDocumentDialog.show(documentTitle: doc.title, shareUrl: shareUrl);
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_CTRL',
        'Error creating share link: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Share Error', e.toString());
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    if (!canDelete) {
      AppSnackbar.showWarning(
        'Permission Denied',
        'Your role does not have permission to delete documents.',
      );
      return;
    }

    try {
      await _dataset.softDeleteDocument(doc.id);
      applianceDocuments.removeWhere((d) => d.id == doc.id);
      totalCount.value = (totalCount.value - 1).clamp(0, 999999);
      AppSnackbar.showWarning(
        'Moved to Trash',
        '${doc.title} moved to trash bin.',
      );
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_CTRL',
        'Error moving to trash: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error', e.toString());
    }
  }

  void confirmMoveToTrash(DocumentModel doc) {
    if (!canDelete) {
      AppSnackbar.showWarning(
        'Permission Denied',
        'Your role does not have permission to delete documents.',
      );
      return;
    }
    DocumentDeleteDialog.show(
      documentTitle: doc.title,
      onConfirm: () => moveToTrash(doc),
    );
  }

  void openEditDocumentDialog(DocumentModel doc) {
    if (!canEdit) {
      AppSnackbar.showWarning(
        'Permission Denied',
        'Your role does not have permission to edit documents.',
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
            applianceWarranty: applianceWarranty,
          );
          await loadApplianceVault(resetPage: true);
        } catch (e, st) {
          AppLogger.error(
            'APPLIANCE_CTRL',
            'Error editing invoice: $e',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      },
    );
  }
}
