import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/utility_bills_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class UtilityBillsController extends GetxController {
  final UtilityBillsDataset _dataset;

  UtilityBillsController(this._dataset);

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final currentPage = 1.obs;
  final pageSize = 20;
  final totalCount = 0.obs;

  final utilityBills = <DocumentModel>[].obs;
  final dynamicCities = <String>[].obs;
  final dynamicUtilityTypes = <String>[].obs;

  // Filters
  final selectedCity = 'All Cities'.obs;
  final selectedUtilityType = 'All Utilities'.obs;
  final selectedPaymentStatus = 'all'.obs; // 'all', 'paid', 'pending', 'overdue'
  final searchQuery = ''.obs;
  final searchController = TextEditingController();
  final scrollController = ScrollController();

  // Summary Metrics
  final totalBillsAmount = 0.0.obs;
  final pendingBillsAmount = 0.0.obs;
  final paidCount = 0.obs;
  final pendingCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadMasterData();
    loadUtilityBills();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      loadNextPage();
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadMasterData() async {
    try {
      final cities = await _dataset.getMasterCities(activeOnly: true);
      dynamicCities.assignAll(cities.map((c) => c.name));

      final providers = await _dataset.getUtilityProviders(activeOnly: true);
      final types = providers.map((p) => p.utilityType).toSet().toList();
      dynamicUtilityTypes.assignAll(types);
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_CTRL',
        'Error loading master data: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> loadUtilityBills({bool isReset = false}) async {
    if (isReset) {
      currentPage.value = 1;
      hasMore.value = true;
    }

    AppLogger.debug(
      'UTILITY_CTRL',
      'Loading utility bills (page: 1, city: ${selectedCity.value}, type: ${selectedUtilityType.value}, status: ${selectedPaymentStatus.value}, search: ${searchQuery.value})',
    );
    isLoading.value = true;

    try {
      final res = await _dataset.getUtilityBills(
        page: 1,
        pageSize: pageSize,
        city: selectedCity.value != 'All Cities' ? selectedCity.value : null,
        subCategory: selectedUtilityType.value != 'All Utilities'
            ? selectedUtilityType.value
            : null,
        paymentStatus: selectedPaymentStatus.value,
        searchQuery: searchQuery.value,
      );

      utilityBills.assignAll(res.documents);
      totalCount.value = res.totalCount;
      totalBillsAmount.value = res.totalAmount;
      pendingBillsAmount.value = res.pendingAmount;
      paidCount.value = res.paidCount;
      pendingCount.value = res.pendingCount;

      hasMore.value = res.documents.length == pageSize &&
          utilityBills.length < res.totalCount;
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_CTRL',
        'Error loading utility bills: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Utility Bills', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final res = await _dataset.getUtilityBills(
        page: nextPage,
        pageSize: pageSize,
        city: selectedCity.value != 'All Cities' ? selectedCity.value : null,
        subCategory: selectedUtilityType.value != 'All Utilities'
            ? selectedUtilityType.value
            : null,
        paymentStatus: selectedPaymentStatus.value,
        searchQuery: searchQuery.value,
      );

      if (res.documents.isEmpty) {
        hasMore.value = false;
      } else {
        currentPage.value = nextPage;
        utilityBills.addAll(res.documents);
        totalCount.value = res.totalCount;
        if (res.documents.length < pageSize ||
            utilityBills.length >= totalCount.value) {
          hasMore.value = false;
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_CTRL',
        'Error loading next page: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Failed to load more', e.toString());
    } finally {
      isLoadingMore.value = false;
    }
  }

  void onCitySelected(String city) {
    selectedCity.value = city;
    loadUtilityBills(isReset: true);
  }

  void onUtilityTypeSelected(String type) {
    selectedUtilityType.value = type;
    loadUtilityBills(isReset: true);
  }

  void onPaymentStatusSelected(String status) {
    selectedPaymentStatus.value = status;
    loadUtilityBills(isReset: true);
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    loadUtilityBills(isReset: true);
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  Future<void> togglePaymentStatus(DocumentModel doc) async {
    final meta = doc.utilityMetadata;
    if (meta == null || meta.id == null) return;

    final newStatus = !meta.isPaid;
    AppLogger.debug(
      'UTILITY_CTRL',
      'Toggling payment status for doc ${doc.id} -> $newStatus',
    );

    try {
      final paymentDate = newStatus
          ? DateTime.now().toIso8601String().split('T').first
          : null;

      await _dataset.updatePaymentStatus(
        metadataId: meta.id!,
        isPaid: newStatus,
        paymentDate: paymentDate,
      );

      AppSnackbar.showSuccess(
        'Payment Updated',
        newStatus ? 'Bill marked as Paid' : 'Bill marked as Pending Payment',
      );

      loadUtilityBills();
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_CTRL',
        'Error updating payment status: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error', e.toString());
    }
  }

  void confirmPaymentStatus(DocumentModel doc) {
    final metadata = doc.utilityMetadata;
    if (metadata == null) return;

    final isUndoingPayment = metadata.isPaid;

    AppDialog.show(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUndoingPayment ? AppColors.warningLight : AppColors.successLight,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: Icon(
                        isUndoingPayment ? Icons.history_rounded : Icons.check_circle_outline_rounded,
                        color: isUndoingPayment ? AppColors.warning : AppColors.success,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isUndoingPayment ? 'Mark Bill as Pending?' : 'Mark Bill as Paid?',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isUndoingPayment
                      ? 'Confirm that "${doc.title}" should be reverted to pending payment.'
                      : 'Confirm payment for "${doc.title}". This will mark the bill as paid.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUndoingPayment ? AppColors.warning : AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();
                        await togglePaymentStatus(doc);
                      },
                      child: Text(
                        isUndoingPayment ? 'Mark as Pending' : 'Confirm Payment',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void previewDocument(DocumentModel doc) async {
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
        'UTILITY_CTRL',
        'Error opening preview: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Preview Error', e.toString());
    }
  }

  void downloadDocument(DocumentModel doc) async {
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
        'UTILITY_CTRL',
        'Error downloading document: $e',
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

  void openShareDialog(DocumentModel doc) async {
    try {
      final token = await _dataset.createShareLink(doc.id);
      final shareUrl = '${AppConstants.webBaseUrl}/share/$token';
      ShareDocumentDialog.show(documentTitle: doc.title, shareUrl: shareUrl);
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_CTRL',
        'Error creating share link: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Share Error', e.toString());
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    try {
      await _dataset.softDeleteDocument(doc.id);
      utilityBills.removeWhere((d) => d.id == doc.id);
      totalCount.value = (totalCount.value - 1).clamp(0, 999999);
      AppSnackbar.showWarning(
        'Moved to Trash',
        '${doc.title} moved to trash bin.',
      );
    } catch (e, st) {
      AppLogger.error(
        'UTILITY_CTRL',
        'Error moving to trash: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error', e.toString());
    }
  }

  void confirmMoveToTrash(DocumentModel doc) {
    DocumentDeleteDialog.show(
      documentTitle: doc.title,
      onConfirm: () => moveToTrash(doc),
    );
  }

  void openEditDocumentDialog(DocumentModel doc) {
    DocumentEditDialog.show(
      document: doc,
      onSave: ({
        required title,
        description,
        documentNumber,
        applianceWarranty,
      }) async {
        try {
          await _dataset.updateDocumentDetails(
            documentId: doc.id,
            title: title,
            description: description,
            documentNumber: documentNumber,
          );
          await loadUtilityBills();
        } catch (e, st) {
          AppLogger.error(
            'UTILITY_CTRL',
            'Error editing bill: $e',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      },
    );
  }
}

