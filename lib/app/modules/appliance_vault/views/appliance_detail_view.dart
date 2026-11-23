import 'package:kt_prod_kt_docs/app/widgets/inline_form_error.dart';
import 'package:kt_prod_kt_docs/app/widgets/detail_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/controllers/appliance_detail_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/google_drive_logo.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class ApplianceDetailView extends GetView<ApplianceDetailController> {
  const ApplianceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Appliance & Warranty Details',
      subtitle:
          'Manage appliance serial numbers, invoice metadata, customer care, and track warranty & AMC renewal lineage',
      currentRoute: AppRoutes.APPLIANCES,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const DetailSkeleton();
        }

        final doc = controller.document.value;
        if (doc == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Appliance document not found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Appliance Vault'),
                ),
              ],
            ),
          );
        }

        final w = doc.applianceWarranty;
        final primaryItem = w?.primaryItem;
        final productName =
            primaryItem?.productName ?? w?.productName ?? doc.title;
        final brand = primaryItem?.brand ?? w?.brand ?? 'Appliance';

        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InlineFormError(message: controller.formError.value),
                    // 1. Back Navigation Row
                    _buildBackNavigationRow(productName),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // 2. Hero Header Card
                    _buildHeroHeaderCard(doc, w, productName, brand),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // 3. Metrics Summary Row
                    _buildMetricsRow(w),
                    const SizedBox(height: AppConstants.paddingLarge),

                    // 4. Responsive 2-Column Main Section
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop =
                            constraints.maxWidth >=
                            AppConstants.desktopBreakpoint;

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Details, Protection Banner, Covered Items & Form
                              Expanded(
                                flex: 5,
                                child: _buildLeftDetailsColumn(doc, w),
                              ),
                              const SizedBox(width: AppConstants.paddingLarge),
                              // Right: Warranty & AMC Lineage Timeline
                              Expanded(
                                flex: 6,
                                child: _buildRightHistorySection(doc),
                              ),
                            ],
                          );
                        }

                        // Tablet / Mobile: Stacked
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLeftDetailsColumn(doc, w),
                            const SizedBox(height: AppConstants.paddingLarge),
                            _buildRightHistorySection(doc),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBackNavigationRow(String productName) {
    return Row(
      children: [
        InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: const [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Text(
                  'Appliance Vault',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '/',
          style: TextStyle(color: AppColors.border, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            productName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeaderCard(
    DocumentModel doc,
    ApplianceWarrantyModel? w,
    String productName,
    String brand,
  ) {
    final isLifetime = w?.isLifetime ?? false;
    final hasWarranty = w?.hasWarranty ?? false;
    final isExpired = w?.isExpired ?? false;
    final isExpiringSoon = w?.isExpiringSoon ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (doc.isGoogleAttachment) ...[
                          const GoogleDriveLogo(size: 18),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: w?.warrantyStatusDisplay ?? 'ACTIVE',
                          type:
                              isLifetime ||
                                  (!isExpired && hasWarranty && !isExpiringSoon)
                              ? StatusBadgeType.success
                              : (isExpiringSoon
                                    ? StatusBadgeType.warning
                                    : StatusBadgeType.inactive),
                        ),
                        if ((w?.renewalCount ?? 0) > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Cycle #${w!.renewalCount + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$brand • ${doc.subCategory.isNotEmpty ? doc.subCategory : "Appliance"} • Invoice #${w?.invoiceNumber ?? doc.documentNumber ?? "N/A"}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: controller.openRenewWarrantyDialog,
                    icon: const Icon(Icons.add_moderator_outlined, size: 16),
                    label: const Text('Renew / Extend Warranty'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => controller.previewDocument(),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Preview Invoice'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => controller.downloadDocument(),
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Download'),
                  ),
                ],
              ),
              if (controller.canDelete)
                TextButton.icon(
                  onPressed: controller.confirmMoveToTrash,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(ApplianceWarrantyModel? w) {
    final isLifetime = w?.isLifetime ?? false;
    final isExpired = w?.isExpired ?? false;
    final hasWarranty = w?.hasWarranty ?? false;
    final days = w?.daysUntilExpiry ?? 0;

    String expirySubtitle = 'Standard cycle';
    if (isLifetime) {
      expirySubtitle = 'No expiration date';
    } else if (!hasWarranty) {
      expirySubtitle = 'Invoice Only';
    } else if (isExpired) {
      expirySubtitle = 'Expired';
    } else {
      expirySubtitle = '$days days remaining';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final itemWidth = isNarrow
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: MetricCard(
                title: 'PURCHASE AMOUNT',
                value: (w?.purchaseAmount != null && w!.purchaseAmount > 0)
                    ? AppFormatters.formatCurrency(w.purchaseAmount)
                    : 'N/A',
                subtitle: 'Original invoice cost',
                icon: Icons.currency_rupee_outlined,
                accentColor: AppColors.primary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: MetricCard(
                title: 'COVERAGE TIER',
                value: w?.warrantyTypeDisplay ?? 'Standard',
                subtitle: w?.amcProvider ?? 'Manufacturer',
                icon: Icons.verified_user_outlined,
                accentColor: w?.warrantyType == 'amc'
                    ? Colors.teal
                    : Colors.indigo,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: MetricCard(
                title: 'VALID UNTIL',
                value: isLifetime
                    ? 'Lifetime'
                    : (hasWarranty && w?.effectiveValidUpto != null
                          ? AppFormatters.formatDate(w!.effectiveValidUpto)
                          : 'No Expiry'),
                subtitle: expirySubtitle,
                icon: Icons.calendar_today_outlined,
                accentColor: isExpired ? AppColors.error : AppColors.success,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: MetricCard(
                title: 'VERSION LINEAGE',
                value: '${controller.historyDocs.length} Cycles',
                subtitle: 'Historical extensions',
                icon: Icons.history_rounded,
                accentColor: Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeftDetailsColumn(DocumentModel doc, ApplianceWarrantyModel? w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A. Warranty & AMC Protection Status Banner
        _buildProtectionBanner(w),
        const SizedBox(height: AppConstants.paddingMedium),

        // B. Editable Details & Invoice Information Card
        _buildEditableDetailsCard(doc, w),
        const SizedBox(height: AppConstants.paddingMedium),

        // C. Covered Products / Items Card
        _buildCoveredProductsCard(w, doc),
      ],
    );
  }

  Widget _buildProtectionBanner(ApplianceWarrantyModel? w) {
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
                      w?.warrantyTypeDisplay ??
                          'Standard Manufacturer Warranty',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: txt,
                      ),
                    ),
                    if (w?.amcProvider != null &&
                        w!.amcProvider!.isNotEmpty) ...[
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailsCard(
    DocumentModel doc,
    ApplianceWarrantyModel? w,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PURCHASE & INVOICE DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              if (controller.canEdit)
                Obx(() {
                  return ElevatedButton.icon(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.saveApplianceDetails,
                    icon: controller.isSaving.value
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 14),
                    label: Text(
                      controller.isSaving.value ? 'Saving...' : 'Save Details',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
            ],
          ),
          const Divider(height: 20),

          // Store Vendor & Invoice #
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Store / Vendor Name',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.storeVendorController,
                      enabled: controller.canEdit,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Vijay Sales',
                        prefixIcon: Icon(Icons.storefront_outlined, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice / Bill Number',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.invoiceNumberController,
                      enabled: controller.canEdit,
                      decoration: const InputDecoration(
                        hintText: 'e.g. INV-99128',
                        prefixIcon: Icon(Icons.receipt_outlined, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Billing Name & Purchase Amount
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Billing Name',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.billingNameController,
                      enabled: controller.canEdit,
                      decoration: const InputDecoration(
                        hintText: 'e.g. King Technology Pvt Ltd',
                        prefixIcon: Icon(Icons.person_outline, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Purchase Amount (₹)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.purchaseAmountController,
                      enabled: controller.canEdit,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 45000',
                        prefixIcon: Icon(
                          Icons.currency_rupee_outlined,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Customer Care Contact & Location
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Care Number',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.customerCareController,
                      enabled: controller.canEdit,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1800 102 9300',
                        prefixIcon: Icon(
                          Icons.phone_in_talk_outlined,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premise / City Location',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              doc.address?.city != null &&
                                      doc.address!.city.isNotEmpty
                                  ? '${doc.address!.city}${doc.address?.premiseName != null ? " • ${doc.address!.premiseName}" : ""}'
                                  : 'All Premises',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoveredProductsCard(
    ApplianceWarrantyModel? w,
    DocumentModel doc,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COVERED PRODUCTS (${w?.items.length ?? 1})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (w != null && w.items.isNotEmpty)
            ...w.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildProductItemCard(item),
              ),
            )
          else
            _buildProductItemCard(
              ApplianceItemModel(
                productName: doc.title,
                productCategory: doc.subCategory,
                brand: 'Generic',
                warrantyPeriodMonths: 12,
                warrantyValidUpto: DateTime.now(),
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
                child: const Icon(
                  Icons.devices_other_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
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
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: item.warrantyStatusDisplay,
                type:
                    item.isLifetime ||
                        (!item.isExpired &&
                            item.hasWarranty &&
                            !item.isExpiringSoon)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Serial Number (S/N)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.serialNumber ?? 'Not recorded',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Standard Warranty',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.isLifetime
                          ? 'Lifetime'
                          : (item.hasWarranty
                                ? '${item.warrantyPeriodMonths} Mos (${AppFormatters.formatDate(item.warrantyValidUpto)})'
                                : 'No Warranty'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.extendedWarrantyUpto != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Extended / AMC Upto',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.formatDate(item.extendedWarrantyUpto),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.amcProvider != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Provider',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.amcProvider!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRightHistorySection(DocumentModel doc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'WARRANTY & RENEWAL HISTORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Obx(() {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${controller.historyDocs.length} Cycles',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }),
            ],
          ),
          const Divider(height: 20),

          Obx(() {
            if (controller.historyDocs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(
                        Icons.history_toggle_off_outlined,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No past warranty renewals or AMCs on file',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Use "Renew / Extend Warranty" to attach new certificates or AMCs.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.historyDocs.length,
              itemBuilder: (context, index) {
                final item = controller.historyDocs[index];
                final isCurrent = item.id == doc.id;
                final itemW = item.applianceWarranty;
                final versionNum = controller.historyDocs.length - index;
                final isLast = index == controller.historyDocs.length - 1;

                return _buildTimelineNode(
                  doc: item,
                  warranty: itemW,
                  isCurrent: isCurrent,
                  versionNum: versionNum,
                  isLast: isLast,
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required DocumentModel doc,
    required ApplianceWarrantyModel? warranty,
    required bool isCurrent,
    required int versionNum,
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
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Card Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.04)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          warranty?.warrantyTypeDisplay ??
                              'Manufacturer Invoice',
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                        type:
                            isLifetime || (!isExpired && wType != 'no_warranty')
                            ? StatusBadgeType.success
                            : StatusBadgeType.inactive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (warranty?.amcProvider != null &&
                          warranty!.amcProvider!.isNotEmpty) ...[
                        Text(
                          'Provider: ${warranty.amcProvider}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        'Ref: ${warranty?.policyNumber ?? warranty?.invoiceNumber ?? doc.documentNumber ?? "N/A"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        isLifetime
                            ? 'Lifetime Validity'
                            : (validUpto != null
                                  ? 'Valid Until: ${AppFormatters.formatDate(validUpto)}'
                                  : 'No Expiry Tracked'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isExpired
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (warranty?.renewalAmount != null &&
                          warranty!.renewalAmount! > 0) ...[
                        const SizedBox(width: 10),
                        Text(
                          'Cost: ₹${warranty.renewalAmount!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (warranty?.renewalNotes != null &&
                      warranty!.renewalNotes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${warranty.renewalNotes}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Logged ${AppFormatters.formatDate(doc.createdAt)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => controller.previewDocument(doc),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                'Preview',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => controller.downloadDocument(doc),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                'Download',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
