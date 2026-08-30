import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/controllers/appliance_vault_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
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
        return Column(
          children: [
            // Top Summary Cards & Brand Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Filter Chips Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 600;
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
                            SizedBox(
                              height: 36,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: [
                                  'All Brands',
                                  ...AppConstants.popularBrands,
                                ].length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final brand = [
                                    'All Brands',
                                    ...AppConstants.popularBrands,
                                  ][index];
                                  final isSelected =
                                      controller.selectedBrand.value
                                          .toLowerCase() ==
                                      brand.toLowerCase();

                                  return InkWell(
                                    onTap: () =>
                                        controller.onBrandSelected(brand),
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
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
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
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: Builder(
                                builder: (context) {
                                  final brandList =
                                      controller.dynamicBrands.isNotEmpty
                                      ? [
                                          'All Brands',
                                          ...controller.dynamicBrands,
                                        ]
                                      : [
                                          'All Brands',
                                          ...AppConstants.popularBrands,
                                        ];
                                  return ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: brandList.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final brand = brandList[index];
                                      final isSelected =
                                          controller.selectedBrand.value
                                              .toLowerCase() ==
                                          brand.toLowerCase();

                                      return InkWell(
                                        onTap: () =>
                                            controller.onBrandSelected(brand),
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Metrics Row (Responsive 1/2/4 Columns)
                  LayoutBuilder(
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
                  ),
                ],
              ),
            ),

            // Secondary Filter Bar (Subcategory + Warranty Status)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.background,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Subcategory Dropdown
                  Container(
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
                  ),

                  // Warranty Status Filter
                  Container(
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
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            controller.onWarrantyStatusSelected(val);
                          }
                        },
                      ),
                    ),
                  ),

                  Text(
                    '${controller.applianceDocuments.length} appliances',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Appliance List Area
            Expanded(
              child: controller.isLoading.value
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : controller.applianceDocuments.isEmpty
                  ? _buildEmptyState()
                  : _buildApplianceList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
            label: const Text('Upload Appliance Invoice'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: controller.applianceDocuments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = controller.applianceDocuments[index];
        final w = doc.applianceWarranty;
        final addr = doc.address;

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
                        children: [
                          _buildApplianceIcon(doc.subCategory),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Brand: ${w?.brand ?? "N/A"} • Serial: ${w?.serialNumber ?? "N/A"}',
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
                            type: w?.isExpired == true
                                ? StatusBadgeType.inactive
                                : (w?.isExpiringSoon == true
                                      ? StatusBadgeType.warning
                                      : StatusBadgeType.success),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'City: ${addr?.city ?? "N/A"} • Valid To: ${AppFormatters.formatDate(w?.warrantyValidUpto)}',
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
                                onPressed: () =>
                                    controller.previewDocument(doc),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.download_outlined,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    controller.downloadDocument(doc),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share_outlined,
                                  size: 18,
                                ),
                                onPressed: () => controller.shareDocument(doc),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit invoice details',
                                onPressed: () =>
                                    controller.openEditDocumentDialog(doc),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    _buildApplianceIcon(doc.subCategory),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Brand: ${w?.brand ?? "N/A"} • Serial: ${w?.serialNumber ?? "N/A"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (w?.storeVendorName != null)
                            Text(
                              'Store: ${w!.storeVendorName} • Invoice: ${w.invoiceNumber}',
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
                            'Valid: ${AppFormatters.formatDate(w?.warrantyValidUpto)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            w?.isExpired == true
                                ? 'Expired'
                                : '${w?.daysUntilExpiry ?? 0} days remaining',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: w?.isExpiringSoon == true
                                  ? AppColors.warning
                                  : (w?.isExpired == true
                                        ? AppColors.error
                                        : AppColors.success),
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
                            type: w?.isExpired == true
                                ? StatusBadgeType.inactive
                                : (w?.isExpiringSoon == true
                                      ? StatusBadgeType.warning
                                      : StatusBadgeType.success),
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
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Invoice Details',
                          onPressed: () =>
                              controller.openEditDocumentDialog(doc),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.error,
                          ),
                          tooltip: 'Move to Trash',
                          onPressed: () => controller.confirmMoveToTrash(doc),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
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
