import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/activity_logs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/activity_log_model.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Controller for Activity & Audit Logs.
/// Strictly conforms to 3-tier MVC: View -> Controller -> Dataset -> Supabase.
class ActivityLogsController extends GetxController {
  final ActivityLogsDataset _dataset;

  ActivityLogsController(this._dataset);

  // Observables
  final isLoading = true.obs;
  final isTableLoading = false.obs;
  final activities = <ActivityLogModel>[].obs;
  final totalCount = 0.obs;

  // Pagination Observables (Section 6.B: Table Paginated Standards)
  final currentPage = 1.obs;
  final pageSize = 25.obs;

  // Filters & Search
  final selectedActionFilter = 'all'.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  // Action Filter Options
  final actionFilters = const [
    {'key': 'all', 'label': 'All Actions', 'icon': Icons.all_inclusive},
    {'key': 'uploaded', 'label': 'Uploads', 'icon': Icons.cloud_upload_outlined},
    {'key': 'viewed', 'label': 'Views', 'icon': Icons.visibility_outlined},
    {'key': 'downloaded', 'label': 'Downloads', 'icon': Icons.download_outlined},
    {'key': 'shared', 'label': 'Shares', 'icon': Icons.share_outlined},
    {'key': 'updated', 'label': 'Updates', 'icon': Icons.edit_outlined},
    {'key': 'trashed', 'label': 'Trashed', 'icon': Icons.delete_outline},
    {'key': 'restored', 'label': 'Restored', 'icon': Icons.restore},
    {'key': 'permanently_deleted', 'label': 'Purged', 'icon': Icons.delete_forever},
  ];

  // Pagination Computations
  int get totalPages => (totalCount.value / pageSize.value).ceil().clamp(1, 99999);
  bool get hasNextPage => currentPage.value < totalPages;
  bool get hasPrevPage => currentPage.value > 1;
  int get startEntry => totalCount.value == 0 ? 0 : (currentPage.value - 1) * pageSize.value + 1;
  int get endEntry => (currentPage.value * pageSize.value).clamp(0, totalCount.value);

  @override
  void onInit() {
    super.onInit();
    loadActivityLogs(isInitial: true);
  }

  /// Loads paginated activity logs from the dataset.
  Future<void> loadActivityLogs({bool isInitial = false, bool isReset = false}) async {
    if (isReset) {
      currentPage.value = 1;
    }

    if (isInitial) {
      isLoading.value = true;
    } else {
      isTableLoading.value = true;
    }

    try {
      final res = await _dataset.getActivityLogs(
        page: currentPage.value,
        pageSize: pageSize.value,
        actionFilter: selectedActionFilter.value,
        searchQuery: searchQuery.value,
      );

      activities.assignAll(res.logs);
      totalCount.value = res.totalCount;
    } catch (e, st) {
      AppLogger.error(
        'ACTIVITY_LOGS_CTRL',
        'Error loading logs: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Logs', e.toString());
    } finally {
      isLoading.value = false;
      isTableLoading.value = false;
    }
  }

  void changePage(int page) {
    if (page == currentPage.value || page < 1 || page > totalPages) return;
    currentPage.value = page;
    loadActivityLogs();
  }

  void changePageSize(int newSize) {
    if (pageSize.value == newSize) return;
    pageSize.value = newSize;
    currentPage.value = 1;
    loadActivityLogs();
  }

  void setActionFilter(String action) {
    if (selectedActionFilter.value == action) return;
    selectedActionFilter.value = action;
    currentPage.value = 1;
    loadActivityLogs();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    loadActivityLogs();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    currentPage.value = 1;
    loadActivityLogs();
  }

  /// Opens dialog displaying detailed log metadata payload.
  void openLogDetailsDialog(ActivityLogModel log) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        backgroundColor: AppColors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Audit Event Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                      onPressed: () => Get.back(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),

                // Details Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Event ID', log.id),
                        _buildDetailRow('Timestamp', AppFormatters.formatDateTime(log.createdAt)),
                        _buildDetailRow('Action', log.actionDisplay),
                        _buildDetailRow('User Name', log.userName ?? 'System User'),
                        if (log.userEmail != null) _buildDetailRow('User Email', log.userEmail!),
                        if (log.documentTitle != null) _buildDetailRow('Document Title', log.documentTitle!),
                        if (log.documentId != null) _buildDetailRow('Document ID', log.documentId!),
                        const SizedBox(height: 12),
                        const Text(
                          'Additional Event Metadata (JSON)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: SelectableText(
                            log.details.isNotEmpty
                                ? const JsonEncoder.withIndent('  ').convert(log.details)
                                : 'No additional metadata logged.',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
