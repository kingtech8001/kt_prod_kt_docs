import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class ApplianceHistoryDialog extends StatelessWidget {
  final DocumentModel document;
  final Future<List<DocumentModel>> Function() loadHistory;
  final void Function(DocumentModel doc) onPreview;
  final void Function(DocumentModel doc) onDownload;

  const ApplianceHistoryDialog({
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
      ApplianceHistoryDialog(
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
    final w = document.applianceWarranty;
    final primaryItem = w?.primaryItem;
    final productName = primaryItem?.productName ?? w?.productName ?? document.title;
    final brand = primaryItem?.brand ?? w?.brand ?? 'Appliance';
    final serial = primaryItem?.serialNumber ?? w?.serialNumber;

    final isLoading = true.obs;
    final historyDocs = <DocumentModel>[].obs;

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
                      Icons.history_rounded,
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
                          '$productName Version & Renewal History',
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
                          '$brand${serial != null && serial.isNotEmpty ? " • S/N: $serial" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    tooltip: 'Close',
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppShimmer(
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppShimmer(
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppShimmer(
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (historyDocs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_toggle_off_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No warranty history found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Only the current invoice exists for this appliance.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  itemCount: historyDocs.length,
                  itemBuilder: (context, index) {
                    final item = historyDocs[index];
                    final isCurrent = item.id == document.id;
                    final itemW = item.applianceWarranty;
                    final versionNum = historyDocs.length - index;
                    final isFirst = index == 0;
                    final isLast = index == historyDocs.length - 1;

                    return _buildTimelineItem(
                      doc: item,
                      warranty: itemW,
                      isCurrent: isCurrent,
                      versionNum: versionNum,
                      isFirst: isFirst,
                      isLast: isLast,
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
                  Obx(() {
                    return Text(
                      '${historyDocs.length} version cycle${historyDocs.length == 1 ? "" : "s"} on file',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required DocumentModel doc,
    required ApplianceWarrantyModel? warranty,
    required bool isCurrent,
    required int versionNum,
    required bool isFirst,
    required bool isLast,
  }) {
    final wType = warranty?.warrantyType ?? 'standard';
    final isLifetime = warranty?.isLifetime ?? false;
    final validUpto = warranty?.effectiveValidUpto;
    final isExpired = warranty?.isExpired ?? false;

    Color badgeColor = AppColors.primary;
    if (wType == 'amc') badgeColor = Colors.teal;
    if (wType == 'extended') badgeColor = Colors.indigo;
    if (wType == 'component') badgeColor = Colors.orange;
    if (isLifetime) badgeColor = Colors.purple;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.primary : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCurrent
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : Text(
                            '$versionNum',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.04)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          warranty?.warrantyTypeDisplay ?? 'Manufacturer Invoice',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CURRENT ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      StatusBadge(
                        label: isLifetime
                            ? 'LIFETIME'
                            : (wType == 'no_warranty'
                                ? 'NO WARRANTY'
                                : (isExpired ? 'EXPIRED' : 'ACTIVE')),
                        type: isLifetime || (!isExpired && wType != 'no_warranty')
                            ? StatusBadgeType.success
                            : StatusBadgeType.inactive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (warranty?.amcProvider != null && warranty!.amcProvider!.isNotEmpty) ...[
                        Text(
                          'Provider: ${warranty.amcProvider}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        'Invoice / Ref: ${warranty?.policyNumber ?? warranty?.invoiceNumber ?? doc.documentNumber ?? "N/A"}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isLifetime
                            ? 'Lifetime Validity (No Expiration)'
                            : (validUpto != null
                                ? 'Valid Until: ${AppFormatters.formatDate(validUpto)}'
                                : 'No Expiry Tracked'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isExpired ? AppColors.error : AppColors.textPrimary,
                        ),
                      ),
                      if (warranty?.renewalAmount != null && warranty!.renewalAmount! > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Cost: ₹${warranty.renewalAmount!.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ],
                  ),
                  if (warranty?.renewalNotes != null && warranty!.renewalNotes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Notes: ${warranty.renewalNotes}',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Uploaded: ${AppFormatters.formatDate(doc.createdAt)}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () => onPreview(doc),
                            icon: const Icon(Icons.visibility_outlined, size: 14),
                            label: const Text('Preview', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 6),
                          TextButton.icon(
                            onPressed: () => onDownload(doc),
                            icon: const Icon(Icons.download_outlined, size: 14),
                            label: const Text('Download', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
