import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class PersonalDocHistoryDialog extends StatelessWidget {
  final DocumentModel document;
  final Future<List<DocumentModel>> Function() loadHistory;
  final void Function(DocumentModel doc) onPreview;
  final void Function(DocumentModel doc) onDownload;

  const PersonalDocHistoryDialog({
    super.key,
    required this.document,
    required this.loadHistory,
    required this.onPreview,
    required this.onDownload,
  });

  static Future<void> show({
    required DocumentModel document,
    required Future<List<DocumentModel>> Function() loadHistory,
    required void Function(DocumentModel doc) onPreview,
    required void Function(DocumentModel doc) onDownload,
  }) {
    return AppDialog.show<void>(
      PersonalDocHistoryDialog(
        document: document,
        loadHistory: loadHistory,
        onPreview: onPreview,
        onDownload: onDownload,
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = document.personalMetadata;
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
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_edu_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${meta?.docTypeName ?? "Personal Document"} Version & Renewal History',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${meta?.personName ?? "Person"} • ${meta?.idNumber ?? ""}',
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
                            Icons.history_toggle_off_outlined,
                            size: 48,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Past History Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'This document is currently on its initial cycle.',
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
                    final isCurrentActive = doc.status == 'active';
                    final docMeta = doc.personalMetadata;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCurrentActive
                            ? AppColors.primary.withValues(alpha: 0.04)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentActive
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentActive
                                      ? AppColors.success.withValues(alpha: 0.15)
                                      : AppColors.textSecondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCurrentActive ? 'CURRENT ACTIVE' : 'SUPERSEDED / ARCHIVED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: isCurrentActive
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (docMeta?.expiryDate != null)
                                Text(
                                  'Expiry: ${AppFormatters.formatDate(docMeta!.expiryDate!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrentActive
                                        ? docMeta.statusBadgeColor
                                        : AppColors.textSecondary,
                                  ),
                                )
                              else
                                const Text(
                                  'Lifetime Validity (No Expiry)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
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
                              if (docMeta?.idNumber != null && docMeta!.idNumber!.isNotEmpty)
                                Text(
                                  'Policy/ID: ${docMeta.idNumber}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (docMeta?.insuranceCompany != null &&
                                  docMeta!.insuranceCompany!.isNotEmpty)
                                Text(
                                  'Insurer: ${docMeta.insuranceCompany}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (docMeta?.policyType != null &&
                                  docMeta!.policyType!.isNotEmpty)
                                Text(
                                  'Type: ${docMeta.policyType}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (docMeta?.sumInsured != null)
                                Text(
                                  'Sum Insured: ₹${AppFormatters.formatCurrency(docMeta!.sumInsured!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (docMeta?.premiumAmount != null)
                                Text(
                                  'Premium: ₹${AppFormatters.formatCurrency(docMeta!.premiumAmount!)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              if (docMeta?.issueDate != null)
                                Text(
                                  'Issued: ${AppFormatters.formatDate(docMeta!.issueDate!)}',
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
                                onPressed: () => onPreview(doc),
                                icon: const Icon(Icons.visibility_outlined, size: 14),
                                label: const Text('View File', style: TextStyle(fontSize: 12)),
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
                      '${historyDocs.length} total records logged',
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
            height: 120,
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
