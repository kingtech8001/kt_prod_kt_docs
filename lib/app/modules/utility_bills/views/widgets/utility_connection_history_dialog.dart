import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_connection_account.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class UtilityConnectionHistoryDialog extends StatelessWidget {
  final UtilityConnectionAccount connection;
  final Future<List<DocumentModel>> Function() loadHistory;
  final void Function(DocumentModel doc) onPreview;
  final void Function(DocumentModel doc) onDownload;
  final Future<void> Function(DocumentModel doc) onTogglePayment;

  const UtilityConnectionHistoryDialog({
    super.key,
    required this.connection,
    required this.loadHistory,
    required this.onPreview,
    required this.onDownload,
    required this.onTogglePayment,
  });

  static Future<void> show({
    required UtilityConnectionAccount connection,
    required Future<List<DocumentModel>> Function() loadHistory,
    required void Function(DocumentModel doc) onPreview,
    required void Function(DocumentModel doc) onDownload,
    required Future<void> Function(DocumentModel doc) onTogglePayment,
  }) {
    return AppDialog.show<void>(
      UtilityConnectionHistoryDialog(
        connection: connection,
        loadHistory: loadHistory,
        onPreview: onPreview,
        onDownload: onDownload,
        onTogglePayment: onTogglePayment,
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = true.obs;
    final historyDocs = <DocumentModel>[].obs;

    // Load history asynchronously
    loadHistory().then((docs) {
      historyDocs.assignAll(docs);
      isLoading.value = false;
    }).catchError((_) {
      isLoading.value = false;
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: connection.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      connection.iconData,
                      color: connection.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${connection.providerName} • Consumer #: ${connection.consumerNumber}${connection.city != null ? " • ${connection.city}" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return _buildSkeletonTimeline();
                }

                if (historyDocs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Past Bills Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'This connection does not have any recorded cycles yet.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: historyDocs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = historyDocs[index];
                    final meta = doc.utilityMetadata;
                    final isLatest = index == 0;
                    final isPaid = meta?.isPaid ?? false;
                    final isOverdue = meta?.isOverdue ?? false;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLatest
                            ? connection.accentColor.withValues(alpha: 0.04)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLatest
                              ? connection.accentColor.withValues(alpha: 0.4)
                              : (isOverdue
                                  ? AppColors.error.withValues(alpha: 0.4)
                                  : AppColors.border),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isLatest) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'LATEST BILL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              StatusBadge(
                                label: isPaid
                                    ? 'PAID'
                                    : (isOverdue ? 'OVERDUE' : 'PENDING'),
                                type: isPaid
                                    ? StatusBadgeType.success
                                    : (isOverdue
                                        ? StatusBadgeType.error
                                        : StatusBadgeType.warning),
                              ),
                              const Spacer(),
                              Text(
                                '₹${AppFormatters.formatCurrency(meta?.billAmount ?? 0.0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              if (meta?.billDate != null)
                                Text(
                                  'Bill Date: ${AppFormatters.formatDate(meta!.billDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (meta?.dueDate != null)
                                Text(
                                  'Due Date: ${AppFormatters.formatDate(meta!.dueDate!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOverdue ? AppColors.error : AppColors.textSecondary,
                                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              if (meta?.paymentDate != null)
                                Text(
                                  'Paid On: ${AppFormatters.formatDate(meta!.paymentDate!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (meta?.paymentReferenceId != null &&
                                  meta!.paymentReferenceId!.isNotEmpty)
                                Text(
                                  'Ref: ${meta.paymentReferenceId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              Text(
                                'File: ${doc.fileName} (${AppFormatters.formatFileSize(doc.fileSize)})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await onTogglePayment(doc);
                                  // Refresh list
                                  final updated = await loadHistory();
                                  historyDocs.assignAll(updated);
                                },
                                icon: Icon(
                                  isPaid ? Icons.undo_rounded : Icons.check_circle_outline,
                                  size: 14,
                                  color: isPaid ? AppColors.warning : AppColors.success,
                                ),
                                label: Text(
                                  isPaid ? 'Mark Unpaid' : 'Mark as Paid',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isPaid ? AppColors.warning : AppColors.success,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => onPreview(doc),
                                icon: const Icon(Icons.visibility_outlined, size: 14),
                                label: const Text('View Bill', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => onDownload(doc),
                                icon: const Icon(Icons.download_outlined, size: 14),
                                label: const Text('Download', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(
                    () => Text(
                      '${historyDocs.length} total billing cycles recorded',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppShimmer(
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
