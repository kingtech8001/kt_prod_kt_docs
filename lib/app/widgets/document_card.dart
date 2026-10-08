import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/widgets/google_drive_logo.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onPreview;
  final VoidCallback? onDownload;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final bool isTrash;

  const DocumentCard({
    super.key,
    required this.document,
    this.onPreview,
    this.onDownload,
    this.onToggleFavorite,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.isTrash = false,
  });

  IconData _getFileIcon() {
    if (document.isPdf) return Icons.picture_as_pdf;
    if (document.isImage) return Icons.image;
    return Icons.insert_drive_file;
  }

  Color _getFileColor() {
    if (document.isPdf) return AppColors.error;
    if (document.isImage) return AppColors.secondary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final doc = document;
    final hasAddress = doc.address != null && doc.address!.city.isNotEmpty;
    final hasUtility = doc.utilityMetadata != null;
    final hasWarranty = doc.applianceWarranty != null;
    final fileColor = _getFileColor();
    final fileIcon = _getFileIcon();

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPreview,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header Row: Icon + Title + Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: doc.isGoogleAttachment
                            ? const Color(0xFFF0FDF4)
                            : fileColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: doc.isGoogleAttachment
                            ? Border.all(color: const Color(0xFF86EFAC), width: 1.2)
                            : null,
                      ),
                      child: doc.isGoogleAttachment
                          ? const GoogleDriveLogo(size: 24)
                          : Icon(fileIcon, color: fileColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (doc.isGoogleAttachment) ...[
                                const GoogleDriveLogo(size: 16),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  doc.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doc.subCategory,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isTrash && onToggleFavorite != null)
                      IconButton(
                        icon: Icon(
                          doc.isFavorite ? Icons.star : Icons.star_border,
                          color: doc.isFavorite
                              ? AppColors.warning
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: onToggleFavorite,
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Metadata Badges Row (City, Status, Warranty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (doc.isGoogleAttachment)
                      const GoogleDriveBadge(compact: true),
                    if (hasAddress)
                      StatusBadge.city(cityName: doc.address!.city),
                    if (hasUtility) ...[
                      if (doc.utilityMetadata!.isPaid)
                        StatusBadge.paid()
                      else if (doc.utilityMetadata!.isOverdue)
                        StatusBadge.overdue()
                      else
                        StatusBadge.pending(),
                    ],
                    if (hasWarranty) ...[
                      if (doc.applianceWarranty!.hasMultipleItems)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warrantyEmerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.warrantyEmerald.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${doc.applianceWarranty!.itemsCount} Products',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warrantyEmerald,
                            ),
                          ),
                        ),
                      if (!doc.applianceWarranty!.hasWarranty)
                        StatusBadge.noWarranty()
                      else if (doc.applianceWarranty!.isExpired)
                        StatusBadge.warrantyExpired()
                      else if (doc.applianceWarranty!.isExpiringSoon)
                        StatusBadge.warrantyExpiringSoon(
                          daysRemaining: doc.applianceWarranty!.remainingDays,
                        )
                      else
                        StatusBadge.warrantyActive(
                          daysRemaining: doc.applianceWarranty!.remainingDays,
                        ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Specific Utility / Appliance Information
                if (hasUtility)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount: ${AppFormatters.formatCurrency(doc.utilityMetadata!.billAmount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (doc.utilityMetadata!.dueDate != null)
                          Text(
                            'Due: ${AppFormatters.formatDate(doc.utilityMetadata!.dueDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                if (hasWarranty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              doc.applianceWarranty!.hasMultipleItems
                                  ? 'Brands: ${doc.applianceWarranty!.brandsSummary}'
                                  : 'Brand: ${doc.applianceWarranty!.brand}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              doc.applianceWarranty!.hasWarranty
                                  ? 'Warranty: ${AppFormatters.formatDate(doc.applianceWarranty!.warrantyValidUpto)}'
                                  : 'Warranty: None (Invoice Only)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (doc.applianceWarranty!.hasMultipleItems) ...[
                          const SizedBox(height: 3),
                          Text(
                            doc.applianceWarranty!.items
                                .map((i) => i.productName)
                                .join(' • '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Footer: Size + Date + Quick Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppFormatters.formatFileSize(doc.fileSize)} • ${AppFormatters.formatDate(doc.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Row(
                      children: [
                        if (!isTrash) ...[
                          if (doc.isGoogleAttachment)
                            IconButton(
                              icon: const GoogleDriveLogo(size: 18),
                              tooltip: 'Open in Google Drive',
                              onPressed: onPreview,
                            ),
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(
                                Icons.upload_file_outlined,
                                size: 18,
                              ),
                              tooltip: 'Re-upload / Replace file',
                              onPressed: onEdit,
                            ),
                          if (onPreview != null && !doc.isGoogleAttachment)
                            IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 18,
                              ),
                              tooltip: 'Preview',
                              onPressed: onPreview,
                            ),
                          if (onDownload != null)
                            IconButton(
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 18,
                              ),
                              tooltip: 'Download',
                              onPressed: onDownload,
                            ),
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit details',
                              onPressed: onEdit,
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              tooltip: 'Move to Trash',
                              onPressed: onDelete,
                            ),
                        ] else ...[
                          if (onRestore != null)
                            TextButton.icon(
                              icon: const Icon(
                                Icons.restore,
                                size: 16,
                                color: AppColors.success,
                              ),
                              label: const Text(
                                'Restore',
                                style: TextStyle(color: AppColors.success),
                              ),
                              onPressed: onRestore,
                            ),
                          if (onDelete != null)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever,
                                size: 18,
                                color: AppColors.error,
                              ),
                              tooltip: 'Permanent Delete',
                              onPressed: onDelete,
                            ),
                        ],
                      ],
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
}
