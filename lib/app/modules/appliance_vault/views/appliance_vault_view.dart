import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/controllers/appliance_vault_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class ApplianceVaultView extends GetView<ApplianceVaultController> {
  const ApplianceVaultView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Appliance & Warranty Vault',
      subtitle:
          'Invoices, serial numbers, customer care contacts & warranty expiration trackers',
      currentRoute: AppRoutes.APPLIANCES,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ApplianceVaultSkeletonView();
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadApplianceVault(resetPage: true),
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Top Section: Brand Filter Chips & Financial/Warranty Metric Cards
              SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand Filter Chips
                      _buildBrandFilterChips(),

                      const SizedBox(height: 16),

                      // Metrics Row (Responsive 1/2/4 Columns)
                      _buildMetricsRow(),
                    ],
                  ),
                ),
              ),

              // 2. Secondary Filter Bar (Subcategory + Warranty Status + Summary)
              SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: AppColors.background,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Subcategory Dropdown
                      _buildSubcategoryDropdown(),

                      // Warranty Status Filter Dropdown
                      _buildWarrantyStatusDropdown(),

                      // Results Counter
                      Text(
                        '${controller.totalCount.value} documents (${controller.totalAppliancesCount.value} appliances)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Appliance Cards List or Empty State
              if (controller.applianceDocuments.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = controller.applianceDocuments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildApplianceCard(doc),
                        );
                      },
                      childCount: controller.applianceDocuments.length,
                    ),
                  ),
                ),

              // 4. Infinite Scroll Pagination Loader / End Indicator
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.isLoadingMore.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: BottomShimmerLoader(),
                    );
                  }
                  if (!controller.hasMore.value &&
                      controller.applianceDocuments.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Showing all ${controller.applianceDocuments.length} of ${controller.totalCount.value} records',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 24);
                }),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBrandFilterChips() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final brandList = controller.dynamicBrands.isNotEmpty
            ? ['All Brands', ...controller.dynamicBrands]
            : ['All Brands', ...AppConstants.popularBrands];

        final chipListView = SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: brandList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final brand = brandList[index];
              final isSelected = controller.selectedBrand.value.toLowerCase() ==
                  brand.toLowerCase();

              return InkWell(
                onTap: () => controller.onBrandSelected(brand),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.warrantyEmerald
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.warrantyEmerald
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      brand,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FILTER BY BRAND:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              chipListView,
            ],
          );
        }

        return Row(
          children: [
            const Text(
              'FILTER BY BRAND:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: chipListView),
          ],
        );
      },
    );
  }

  Widget _buildMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final card1 = MetricCard(
          title: 'TOTAL APPLIANCES',
          value: '${controller.totalAppliancesCount.value}',
          icon: Icons.devices_other_outlined,
          accentColor: AppColors.warrantyEmerald,
        );
        final card2 = MetricCard(
          title: 'ACTIVE WARRANTIES',
          value: '${controller.activeWarrantiesCount.value}',
          icon: Icons.verified_user_outlined,
          accentColor: AppColors.success,
        );
        final card3 = MetricCard(
          title: 'EXPIRING IN 30 DAYS',
          value: '${controller.expiringSoonCount.value}',
          icon: Icons.warning_amber_rounded,
          accentColor: AppColors.warning,
        );
        final card4 = MetricCard(
          title: 'EXPIRED WARRANTIES',
          value: '${controller.expiredCount.value}',
          icon: Icons.gpp_bad_outlined,
          accentColor: AppColors.textMuted,
        );

        if (width < 600) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 10),
              card2,
              const SizedBox(height: 10),
              card3,
              const SizedBox(height: 10),
              card4,
            ],
          );
        } else if (width < 950) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 14),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 14),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 14),
              Expanded(child: card2),
              const SizedBox(width: 14),
              Expanded(child: card3),
              const SizedBox(width: 14),
              Expanded(child: card4),
            ],
          );
        }
      },
    );
  }

  Widget _buildSubcategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedSubcategory.value,
          items: [
            const DropdownMenuItem(
              value: 'All Appliances',
              child: Text(
                'All Appliances',
                style: TextStyle(fontSize: 13),
              ),
            ),
            ...(controller.dynamicSubcategories.isNotEmpty
                    ? controller.dynamicSubcategories
                    : AppConstants.applianceSubcategories)
                .map(
                  (sub) => DropdownMenuItem(
                    value: sub,
                    child: Text(
                      sub,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
          ],
          onChanged: (val) {
            if (val != null) {
              controller.onSubcategorySelected(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWarrantyStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedWarrantyStatus.value,
          items: const [
            DropdownMenuItem(
              value: 'all',
              child: Text(
                'All Warranty Statuses',
                style: TextStyle(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'active',
              child: Text(
                'Active Warranty',
                style: TextStyle(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'expiring_soon',
              child: Text(
                'Expiring in 30 Days',
                style: TextStyle(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'expired',
              child: Text(
                'Expired',
                style: TextStyle(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'no_warranty',
              child: Text(
                'No Warranty (Invoice Only)',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              controller.onWarrantyStatusSelected(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No appliances or warranty invoices found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload a new AC, Refrigerator, Fan, Laptop, or Geyser invoice to track warranties.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Upload Appliance Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplianceCard(DocumentModel doc) {
    final w = doc.applianceWarranty;
    final addr = doc.address;
    final isMulti = w?.hasMultipleItems == true;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: w?.isExpiringSoon == true
                ? AppColors.warning.withValues(alpha: 0.5)
                : (w?.isExpired == true
                    ? AppColors.border
                    : AppColors.warrantyEmerald.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildApplianceIcon(doc.subCategory),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    doc.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isMulti) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warrantyEmerald
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.warrantyEmerald
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${w!.itemsCount} Products',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warrantyEmerald,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isMulti
                                  ? 'Brands: ${w?.brandsSummary ?? "N/A"}'
                                  : 'Brand: ${w?.brand ?? "N/A"} • Serial: ${w?.serialNumber ?? "N/A"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: w?.warrantyStatusDisplay ?? 'ACTIVE',
                        type: w?.hasWarranty == false
                            ? StatusBadgeType.inactive
                            : (w?.isExpired == true
                                ? StatusBadgeType.inactive
                                : (w?.isExpiringSoon == true
                                    ? StatusBadgeType.warning
                                    : StatusBadgeType.success)),
                      ),
                    ],
                  ),
                  if (isMulti && w != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COVERED PRODUCTS:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...w.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 13,
                                      color: AppColors.warrantyEmerald,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${item.productName} (${item.brand})'
                                        '${item.serialNumber != null && item.serialNumber!.isNotEmpty ? " • S/N: ${item.serialNumber}" : ""}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      item.hasWarranty
                                          ? AppFormatters.formatDate(
                                              item.warrantyValidUpto)
                                          : 'No Warranty',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: item.isExpired
                                            ? AppColors.error
                                            : (item.isExpiringSoon
                                                ? AppColors.warning
                                                : AppColors.success),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w?.hasWarranty == true
                                ? 'City: ${addr?.city ?? "N/A"} • Valid To: ${AppFormatters.formatDate(w?.warrantyValidUpto)}'
                                : 'City: ${addr?.city ?? "N/A"} • No Warranty (Bill Only)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (w?.customerCareNumber != null &&
                              w!.customerCareNumber!.isNotEmpty)
                            Text(
                              'Care: ${w.customerCareNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            tooltip: 'Preview Invoice',
                            onPressed: () =>
                                controller.previewDocument(doc),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.download_outlined,
                              size: 18,
                            ),
                            tooltip: 'Download Invoice',
                            onPressed: () =>
                                controller.downloadDocument(doc),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.share_outlined,
                              size: 18,
                            ),
                            tooltip: 'Share Document',
                            onPressed: () => controller.shareDocument(doc),
                          ),
                          if (controller.canEdit)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Invoice Details',
                              onPressed: () =>
                                  controller.openEditDocumentDialog(doc),
                            ),
                          if (controller.canDelete)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              tooltip: 'Move to Trash',
                              onPressed: () =>
                                  controller.confirmMoveToTrash(doc),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildApplianceIcon(doc.subCategory),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  doc.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMulti) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warrantyEmerald
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.warrantyEmerald
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${w!.itemsCount} Products',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warrantyEmerald,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMulti
                                ? 'Brands: ${w?.brandsSummary ?? "N/A"}'
                                : 'Brand: ${w?.brand ?? "N/A"} • Serial: ${w?.serialNumber ?? "N/A"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (w?.storeVendorName != null &&
                              w!.storeVendorName.isNotEmpty)
                            Text(
                              'Store: ${w.storeVendorName} • Invoice: ${w.invoiceNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addr?.city ?? 'All Premises',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Purchased: ${AppFormatters.formatDate(w?.purchaseDate)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w?.hasWarranty == true
                                ? 'Valid: ${AppFormatters.formatDate(w?.warrantyValidUpto)}'
                                : 'Valid: N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            w?.hasWarranty == false
                                ? 'Invoice Only'
                                : (w?.isExpired == true
                                    ? 'Expired'
                                    : '${w?.daysUntilExpiry ?? 0} days remaining'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: w?.hasWarranty == false
                                  ? AppColors.textSecondary
                                  : (w?.isExpiringSoon == true
                                      ? AppColors.warning
                                      : (w?.isExpired == true
                                          ? AppColors.error
                                          : AppColors.success)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusBadge(
                            label: w?.warrantyStatusDisplay ?? 'ACTIVE',
                            type: w?.hasWarranty == false
                                ? StatusBadgeType.inactive
                                : (w?.isExpired == true
                                    ? StatusBadgeType.inactive
                                    : (w?.isExpiringSoon == true
                                        ? StatusBadgeType.warning
                                        : StatusBadgeType.success)),
                          ),
                          if (w?.customerCareNumber != null &&
                              w!.customerCareNumber!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Care: ${w.customerCareNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 20),
                          tooltip: 'Preview Invoice',
                          onPressed: () => controller.previewDocument(doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download_outlined, size: 20),
                          tooltip: 'Download Invoice',
                          onPressed: () => controller.downloadDocument(doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 20),
                          tooltip: 'Share Document',
                          onPressed: () => controller.shareDocument(doc),
                        ),
                        if (controller.canEdit)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit Invoice Details',
                            onPressed: () =>
                                controller.openEditDocumentDialog(doc),
                          ),
                        if (controller.canDelete)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.error,
                            ),
                            tooltip: 'Move to Trash',
                            onPressed: () =>
                                controller.confirmMoveToTrash(doc),
                          ),
                      ],
                    ),
                  ],
                ),
                if (isMulti && w != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: w.items.map((item) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: AppColors.warrantyEmerald,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item.productName} (${item.brand})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (item.serialNumber != null &&
                                item.serialNumber!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '[S/N: ${item.serialNumber}]',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: (item.isExpired
                                        ? AppColors.error
                                        : (item.isExpiringSoon
                                            ? AppColors.warning
                                            : (item.hasWarranty
                                                ? AppColors.success
                                                : AppColors.textMuted)))
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.hasWarranty
                                    ? 'Valid: ${AppFormatters.formatDate(item.warrantyValidUpto)}'
                                    : 'No Warranty',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item.isExpired
                                      ? AppColors.error
                                      : (item.isExpiringSoon
                                          ? AppColors.warning
                                          : (item.hasWarranty
                                              ? AppColors.success
                                              : AppColors.textMuted)),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildApplianceIcon(String subCategory) {
    IconData icon;
    Color color;

    switch (subCategory.toLowerCase()) {
      case 'ceiling / table fans':
        icon = Icons.wind_power;
        color = Colors.teal;
        break;
      case 'washing machine':
        icon = Icons.local_laundry_service;
        color = AppColors.financeBlue;
        break;
      case 'geyser / water heater':
        icon = Icons.water_damage;
        color = Colors.deepOrange;
        break;
      case 'air conditioner (ac)':
        icon = Icons.ac_unit;
        color = AppColors.primary;
        break;
      case 'refrigerator':
        icon = Icons.kitchen;
        color = Colors.indigo;
        break;
      case 'laptop / computer':
        icon = Icons.laptop_mac;
        color = AppColors.warrantyEmerald;
        break;
      default:
        icon = Icons.devices;
        color = AppColors.warrantyEmerald;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
