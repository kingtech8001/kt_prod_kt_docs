import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class ApplianceDetailDialog extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onRenew;
  final VoidCallback onHistory;
  final VoidCallback? onEdit;

  const ApplianceDetailDialog({
    super.key,
    required this.document,
    required this.onPreview,
    required this.onDownload,
    required this.onRenew,
    required this.onHistory,
    this.onEdit,
  });

  static Future<void> show({
    required DocumentModel document,
    required VoidCallback onPreview,
    required VoidCallback onDownload,
    required VoidCallback onRenew,
    required VoidCallback onHistory,
    VoidCallback? onEdit,
  }) {
    return AppDialog.show<void>(
      ApplianceDetailDialog(
        document: document,
        onPreview: onPreview,
        onDownload: onDownload,
        onRenew: onRenew,
        onHistory: onHistory,
        onEdit: onEdit,
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
    final addr = document.address;

    final isLifetime = w?.isLifetime ?? false;
    final hasWarranty = w?.hasWarranty ?? false;
    final isExpired = w?.isExpired ?? false;
    final isExpiringSoon = w?.isExpiringSoon ?? false;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 860),
        child: Column(
          children: [
            // 1. Header
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
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                productName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: w?.warrantyStatusDisplay ?? 'ACTIVE',
                              type: isLifetime || (!isExpired && hasWarranty && !isExpiringSoon)
                                  ? StatusBadgeType.success
                                  : (isExpiringSoon
                                      ? StatusBadgeType.warning
                                      : StatusBadgeType.inactive),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$brand • ${document.subCategory.isNotEmpty ? document.subCategory : "Home Appliance"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
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

            // 2. Action Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      onRenew();
                    },
                    icon: const Icon(Icons.add_moderator_outlined, size: 16),
                    label: const Text('Renew / Extend Warranty'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      onHistory();
                    },
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('History & Versions'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Preview'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  if (onEdit != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        onEdit!();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                ],
              ),
            ),

            // 3. Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Warranty & AMC Protection Status Banner
                    _buildWarrantyProtectionBanner(w),

                    const SizedBox(height: 20),

                    // Section 2: Purchase & Invoice Information
                    const Text(
                      'PURCHASE & INVOICE DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDataCell(
                                  'Store / Vendor',
                                  w?.storeVendorName.isNotEmpty == true ? w!.storeVendorName : 'N/A',
                                  icon: Icons.storefront_outlined,
                                ),
                              ),
                              Expanded(
                                child: _buildDataCell(
                                  'Invoice / Bill #',
                                  w?.invoiceNumber.isNotEmpty == true
                                      ? w!.invoiceNumber
                                      : (document.documentNumber ?? 'N/A'),
                                  icon: Icons.receipt_outlined,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDataCell(
                                  'Billing Name',
                                  w?.billingName.isNotEmpty == true ? w!.billingName : 'King Technology',
                                  icon: Icons.person_outline,
                                ),
                              ),
                              Expanded(
                                child: _buildDataCell(
                                  'Purchase Date',
                                  w?.purchaseDate != null
                                      ? AppFormatters.formatDate(w!.purchaseDate)
                                      : 'N/A',
                                  icon: Icons.calendar_today_outlined,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDataCell(
                                  'Purchase Amount',
                                  w?.purchaseAmount != null && w!.purchaseAmount > 0
                                      ? AppFormatters.formatCurrency(w.purchaseAmount)
                                      : 'N/A',
                                  icon: Icons.currency_rupee_outlined,
                                ),
                              ),
                              Expanded(
                                child: _buildDataCell(
                                  'Location / Premise',
                                  (addr != null && addr.city.isNotEmpty)
                                      ? '${addr.city}${addr.premiseName != null ? " • ${addr.premiseName}" : ""}'
                                      : 'All Premises',
                                  icon: Icons.location_on_outlined,
                                ),
                              ),
                            ],
                          ),
                          if (w != null && w.customerCareNumber != null && w.customerCareNumber!.isNotEmpty) ...[
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDataCell(
                                    'Customer Care Contact',
                                    w.customerCareNumber!,
                                    icon: Icons.phone_in_talk_outlined,
                                    isPhone: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Covered Products & Items
                    Text(
                      'COVERED PRODUCTS (${w?.items.length ?? 1})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (w != null && w.items.isNotEmpty)
                      ...w.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildProductItemCard(item),
                          ))
                    else
                      _buildProductItemCard(
                        ApplianceItemModel(
                          productName: productName,
                          productCategory: document.subCategory,
                          brand: brand,
                          warrantyPeriodMonths: 12,
                          warrantyValidUpto: DateTime.now(),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 4. Footer
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
                  Text(
                    'Added ${AppFormatters.formatDate(document.createdAt)} • File: ${document.fileName}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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

  Widget _buildWarrantyProtectionBanner(ApplianceWarrantyModel? w) {
    final isLifetime = w?.isLifetime ?? false;
    final wType = w?.warrantyType ?? 'standard';
    final isExp = w?.isExpired ?? false;
    final days = w?.daysUntilExpiry ?? 0;

    Color bg = AppColors.success.withValues(alpha: 0.08);
    Color border = AppColors.success.withValues(alpha: 0.3);
    Color txt = AppColors.success;
    IconData icon = Icons.verified_user_outlined;

    if (isLifetime) {
      bg = Colors.purple.withValues(alpha: 0.08);
      border = Colors.purple.withValues(alpha: 0.3);
      txt = Colors.purple;
      icon = Icons.all_inclusive_outlined;
    } else if (wType == 'no_warranty') {
      bg = AppColors.border.withValues(alpha: 0.3);
      border = AppColors.border;
      txt = AppColors.textSecondary;
      icon = Icons.receipt_long_outlined;
    } else if (isExp) {
      bg = AppColors.error.withValues(alpha: 0.08);
      border = AppColors.error.withValues(alpha: 0.3);
      txt = AppColors.error;
      icon = Icons.error_outline;
    } else if (w?.isExpiringSoon == true) {
      bg = AppColors.warning.withValues(alpha: 0.08);
      border = AppColors.warning.withValues(alpha: 0.3);
      txt = AppColors.warning;
      icon = Icons.warning_amber_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: txt),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      w?.warrantyTypeDisplay ?? 'Standard Manufacturer Warranty',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: txt,
                      ),
                    ),
                    if (w?.amcProvider != null && w!.amcProvider!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${w.amcProvider})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: txt,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isLifetime
                      ? 'Protected by permanent lifetime guarantee. No expiration date.'
                      : (wType == 'no_warranty'
                          ? 'This document is filed as an asset invoice / repair bill without active warranty.'
                          : (isExp
                              ? 'Warranty coverage expired on ${AppFormatters.formatDate(w?.effectiveValidUpto)}. Renew to restore protection.'
                              : 'Valid until ${AppFormatters.formatDate(w?.effectiveValidUpto)} ($days days remaining).')),
                  style: TextStyle(
                    fontSize: 12,
                    color: txt.withValues(alpha: 0.9),
                  ),
                ),
                if (w?.renewalNotes != null && w!.renewalNotes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Coverage Terms: ${w.renewalNotes}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItemCard(ApplianceItemModel item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.devices_other_outlined, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${item.brand} • Model: ${item.modelNumber ?? "N/A"}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: item.warrantyStatusDisplay,
                type: item.isLifetime || (!item.isExpired && item.hasWarranty && !item.isExpiringSoon)
                    ? StatusBadgeType.success
                    : (item.isExpiringSoon
                        ? StatusBadgeType.warning
                        : StatusBadgeType.inactive),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDataCell(
                  'Serial Number (S/N)',
                  item.serialNumber ?? 'Not recorded',
                  icon: Icons.qr_code_outlined,
                ),
              ),
              Expanded(
                child: _buildDataCell(
                  'Standard Warranty',
                  item.isLifetime
                      ? 'Lifetime'
                      : (item.hasWarranty
                          ? '${item.warrantyPeriodMonths} Months (${AppFormatters.formatDate(item.warrantyValidUpto)})'
                          : 'No Warranty'),
                  icon: Icons.security_outlined,
                ),
              ),
            ],
          ),
          if (item.extendedWarrantyUpto != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDataCell(
                    'Extended / AMC Upto',
                    AppFormatters.formatDate(item.extendedWarrantyUpto),
                    icon: Icons.add_moderator_outlined,
                  ),
                ),
                if (item.amcProvider != null)
                  Expanded(
                    child: _buildDataCell(
                      'Provider',
                      item.amcProvider!,
                      icon: Icons.business_outlined,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataCell(String label, String value, {required IconData icon, bool isPhone = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPhone ? AppColors.primary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
