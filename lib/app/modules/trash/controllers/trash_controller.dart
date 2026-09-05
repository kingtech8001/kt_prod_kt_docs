import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/trash_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class TrashController extends GetxController {
  final TrashDataset _trashDataset;

  TrashController(this._trashDataset);

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final currentPage = 1.obs;
  final pageSize = 20;
  final totalCount = 0.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  final scrollController = ScrollController();

  final trashDocuments = <DocumentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadTrashDocuments();
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

  void onSearchChanged(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    hasMore.value = true;
    loadTrashDocuments();
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  Future<void> loadTrashDocuments({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage.value = 1;
      hasMore.value = true;
    }
    isLoading.value = true;

    try {
      final response = await _trashDataset.getTrashDocuments(
        page: 1,
        pageSize: pageSize,
        searchQuery: searchQuery.value,
      );

      trashDocuments.assignAll(response.documents);
      totalCount.value = response.totalCount;
      hasMore.value = response.documents.length == pageSize &&
          trashDocuments.length < response.totalCount;
    } catch (e, st) {
      AppLogger.error(
        'TRASH_CTRL',
        'Error loading trash documents: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Trash', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final response = await _trashDataset.getTrashDocuments(
        page: nextPage,
        pageSize: pageSize,
        searchQuery: searchQuery.value,
      );

      if (response.documents.isEmpty) {
        hasMore.value = false;
      } else {
        currentPage.value = nextPage;
        trashDocuments.addAll(response.documents);
        totalCount.value = response.totalCount;
        if (response.documents.length < pageSize ||
            trashDocuments.length >= totalCount.value) {
          hasMore.value = false;
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'TRASH_CTRL',
        'Error loading next page: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Failed to load more', e.toString());
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> restoreDocument(DocumentModel doc) async {
    try {
      await _trashDataset.restoreDocument(doc.id);
      trashDocuments.removeWhere((d) => d.id == doc.id);
      totalCount.value = (totalCount.value - 1).clamp(0, 999999);
      AppSnackbar.showSuccess(
        'Document Restored',
        'Restored "${doc.title}" to active documents.',
      );
    } catch (e, st) {
      AppLogger.error(
        'TRASH_CTRL',
        'Error restoring document: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Restoring', e.toString());
    }
  }

  void confirmPermanentDelete(DocumentModel doc) {
    Get.dialog(
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
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Permanently Delete?',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Are you sure you want to permanently delete ',
                      ),
                      TextSpan(
                        text: '"${doc.title}"',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(
                        text:
                            '?\n\nThis action cannot be undone and will purge the file from encrypted storage permanently.',
                      ),
                    ],
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                        ),
                      ),
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text(
                        'Delete Permanently',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        Get.back();
                        await _executePermanentDelete(doc);
                      },
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

  Future<void> _executePermanentDelete(DocumentModel doc) async {
    try {
      await _trashDataset.permanentDeleteDocument(doc.id, doc.filePath);
      trashDocuments.removeWhere((d) => d.id == doc.id);
      totalCount.value = (totalCount.value - 1).clamp(0, 999999);
      AppSnackbar.showSuccess(
        'Document Purged',
        '"${doc.title}" permanently removed from vault.',
      );
    } catch (e, st) {
      AppLogger.error(
        'TRASH_CTRL',
        'Error permanently deleting: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Deleting', e.toString());
    }
  }
}

