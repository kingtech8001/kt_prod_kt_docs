import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/utility_bills/controllers/utility_bills_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/city_filter_chips.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class UtilityBillsView extends GetView<UtilityBillsController> {
  const UtilityBillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Utility & Operational Bills',
      subtitle:
          'Electricity, Piped Gas, Water, Broadband & Property Tax bills by city and premises',
      currentRoute: AppRoutes.UTILITY_BILLS,
      body: Obx(() {
        return Column(
          children: [
            // Top Summary Cards & City Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City Filter Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 600;
                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FILTER BY CITY:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CityFilterChips(
                              selectedCity: controller.selectedCity.value,
                              onCitySelected: controller.onCitySelected,
                              customCities: controller.dynamicCities.isNotEmpty
                                  ? controller.dynamicCities
                                  : null,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          const Text(
                            'FILTER BY CITY:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CityFilterChips(
                              selectedCity: controller.selectedCity.value,
                              onCitySelected: controller.onCitySelected,
                              customCities: controller.dynamicCities.isNotEmpty
                                  ? controller.dynamicCities
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Metrics Row (Responsive 1/2/4 Columns)
                  LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxis = 4;
                    if (width < 600) {
                      crossAxis = 1;
                    } else if (width < 950) {
                      crossAxis = 2;
                    }

                    final items = [
                      MetricCard(
                        title: 'TOTAL UTILITY SPEND',
                        value: AppFormatters.formatCurrency(
                            controller.totalBillsAmount.value),
                        icon: Icons.account_balance_wallet_outlined,
                        accentColor: AppColors.financeBlue,
                      ),
                      MetricCard(
                        title: 'PENDING BILLS AMOUNT',
                        value: AppFormatters.formatCurrency(
                            controller.pendingBillsAmount.value),
                        icon: Icons.pending_actions_outlined,
                        accentColor: AppColors.warning,
                      ),
                      MetricCard(
                        title: 'PAID BILLS',
                        value: '${controller.paidCount.value}',
                        icon: Icons.check_circle_outline,
                        accentColor: AppColors.success,
                      ),
                      MetricCard(
                        title: 'PENDING / OVERDUE',
                        value: '${controller.pendingCount.value}',
                        icon: Icons.warning_amber_rounded,
                        accentColor: AppColors.error,
                      ),
                    ];

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxis,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 110,
                      ),
                      itemBuilder: (context, index) => items[index],
                    );
                  }),
                ],
              ),
            ),

            // Secondary Filter Bar (Utility Type + Status)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.background,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Utility Type Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedUtilityType.value,
                        items: [
                          const DropdownMenuItem(
                            value: 'All Utilities',
                            child: Text('All Utilities',
                                style: TextStyle(fontSize: 13)),
                          ),
                          ...(controller.dynamicUtilityTypes.isNotEmpty
                                  ? controller.dynamicUtilityTypes
                                  : AppConstants.utilitySubcategories)
                              .map((sub) => DropdownMenuItem(
                                    value: sub,
                                    child: Text(sub,
                                        style: const TextStyle(fontSize: 13)),
                                  )),
                        ],
                        onChanged: (val) {
                          if (val != null) controller.onUtilityTypeSelected(val);
                        },
                      ),
                    ),
                  ),

                  // Payment Status Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedPaymentStatus.value,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Payment Statuses',
                                style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'paid',
                            child:
                                Text('Paid Only', style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending Only',
                                style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: 'overdue',
                            child: Text('Overdue Only',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            controller.onPaymentStatusSelected(val);
                          }
                        },
                      ),
                    ),
                  ),

                  Text(
                    '${controller.utilityBills.length} records',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // Bills List / Table Area
            Expanded(
              child: controller.isLoading.value
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : controller.utilityBills.isEmpty
                      ? _buildEmptyState()
                      : _buildBillsList(),
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
          const Icon(Icons.receipt_outlined,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No utility bills found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a new electricity, water, gas or broadband bill to track it here.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
            label: const Text('Upload Utility Bill'),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: controller.utilityBills.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = controller.utilityBills[index];
        final u = doc.utilityMetadata;
        final addr = doc.address;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: u?.isOverdue == true
                  ? AppColors.error.withValues(alpha: 0.4)
                  : AppColors.border,
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
                        _buildCategoryIcon(doc.subCategory),
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
                                '${u?.providerName ?? "Provider"} • Consumer: ${u?.consumerNumber ?? "N/A"}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: u?.isPaid == true
                              ? 'PAID'
                              : (u?.isOverdue == true ? 'OVERDUE' : 'PENDING'),
                          type: u?.isPaid == true
                              ? StatusBadgeType.success
                              : (u?.isOverdue == true
                                  ? StatusBadgeType.error
                                  : StatusBadgeType.warning),
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
                              'City: ${addr?.city ?? "N/A"} • Due: ${AppFormatters.formatDate(u?.dueDate)}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              'Amount: ${AppFormatters.formatCurrency(u?.billAmount)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              onPressed: () => controller.previewDocument(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_outlined, size: 18),
                              onPressed: () => controller.downloadDocument(doc),
                            ),
                            IconButton(
                              icon: Icon(
                                u?.isPaid == true
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: u?.isPaid == true
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                size: 20,
                              ),
                              tooltip: u?.isPaid == true
                                  ? 'Mark as Pending'
                                  : 'Mark as Paid',
                              onPressed: () => controller.togglePaymentStatus(doc),
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
                  _buildCategoryIcon(doc.subCategory),
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
                          '${u?.providerName ?? "Provider"} • Consumer No: ${u?.consumerNumber ?? "N/A"}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
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
                          addr?.city ?? 'All Cities',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          addr?.premiseName ??
                              addr?.areaLocality ??
                              'Premises',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
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
                          'Due: ${AppFormatters.formatDate(u?.dueDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: u?.isOverdue == true
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Bill: ${AppFormatters.formatDate(u?.billDate)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
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
                          AppFormatters.formatCurrency(u?.billAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(
                          label: u?.isPaid == true
                              ? 'PAID'
                              : (u?.isOverdue == true ? 'OVERDUE' : 'PENDING'),
                          type: u?.isPaid == true
                              ? StatusBadgeType.success
                              : (u?.isOverdue == true
                                  ? StatusBadgeType.error
                                  : StatusBadgeType.warning),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          u?.isPaid == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: u?.isPaid == true
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        tooltip: u?.isPaid == true
                            ? 'Mark as Pending'
                            : 'Mark as Paid',
                        onPressed: () => controller.togglePaymentStatus(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        tooltip: 'Preview Bill',
                        onPressed: () => controller.previewDocument(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download_outlined, size: 20),
                        tooltip: 'Download File',
                        onPressed: () => controller.downloadDocument(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: AppColors.error),
                        tooltip: 'Move to Trash',
                        onPressed: () => controller.moveToTrash(doc),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryIcon(String subCategory) {
    IconData icon;
    Color color;

    switch (subCategory.toLowerCase()) {
      case 'electricity / light bill':
        icon = Icons.bolt;
        color = AppColors.utilityAmber;
        break;
      case 'piped gas / lpg':
        icon = Icons.local_fire_department;
        color = Colors.deepOrange;
        break;
      case 'water bill':
        icon = Icons.water_drop;
        color = AppColors.financeBlue;
        break;
      case 'internet / broadband':
        icon = Icons.wifi;
        color = AppColors.primary;
        break;
      case 'property tax':
        icon = Icons.home_work;
        color = Colors.purple;
        break;
      default:
        icon = Icons.receipt_long;
        color = AppColors.primary;
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
