import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/modules/utility_bills/controllers/utility_bills_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
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
        // Section 5: Strict Shimmer Skeleton Loader - Zero bare spinners
        if (controller.isLoading.value) {
          return const UtilityBillsSkeletonView();
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadUtilityBills(isReset: true),
          color: AppColors.primary,
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Top Section: City Chips & Financial Metric Cards
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // City Filter Row (Snapping at tabletBreakpoint)
                      _buildCityFilter(context),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Metrics Cards Row (Desktop: 4 cols, Tablet / Mobile: 2 cols or 1 col)
                      _buildMetricsRow(context),
                    ],
                  ),
                ),
              ),

              // 2. Secondary Filter & Search Toolbar
              SliverToBoxAdapter(
                child: _buildToolbar(context),
              ),

              // 3. Bills List Area with Infinite Scroll
              if (controller.utilityBills.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = controller.utilityBills[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.paddingMedium,
                          ),
                          child: RepaintBoundary(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMedium,
                                ),
                                border: Border.all(
                                  color: doc.utilityMetadata?.isOverdue == true
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
                              padding: const EdgeInsets.all(
                                AppConstants.paddingMedium,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isMobile = constraints.maxWidth <
                                      AppConstants.tabletBreakpoint;

                                  if (isMobile) {
                                    return _buildMobileBillTile(doc);
                                  }

                                  return _buildDesktopBillTile(doc);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: controller.utilityBills.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Obx(() {
                    if (controller.isLoadingMore.value) {
                      return const BottomShimmerLoader();
                    }
                    if (!controller.hasMore.value &&
                        controller.utilityBills.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingMedium,
                        ),
                        child: Center(
                          child: Text(
                            'All ${controller.totalCount.value} utility bills loaded',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ),
              ],
            ],
          ),
        );

      }),
    );
  }

  Widget _buildCityFilter(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;

        if (isMobile) {
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
              const SizedBox(height: AppConstants.paddingSmall),
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
            const SizedBox(width: AppConstants.paddingMedium),
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
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final card1 = MetricCard(
          title: 'TOTAL UTILITY SPEND',
          value: AppFormatters.formatCurrency(controller.totalBillsAmount.value),
          icon: Icons.account_balance_wallet_outlined,
          accentColor: AppColors.financeBlue,
        );
        final card2 = MetricCard(
          title: 'PENDING BILLS AMOUNT',
          value: AppFormatters.formatCurrency(controller.pendingBillsAmount.value),
          icon: Icons.pending_actions_outlined,
          accentColor: AppColors.warning,
        );
        final card3 = MetricCard(
          title: 'PAID BILLS',
          value: '${controller.paidCount.value}',
          icon: Icons.check_circle_outline,
          accentColor: AppColors.success,
        );
        final card4 = MetricCard(
          title: 'PENDING / OVERDUE',
          value: '${controller.pendingCount.value}',
          icon: Icons.warning_amber_rounded,
          accentColor: AppColors.error,
        );

        if (width < AppConstants.tabletBreakpoint) {
          // Mobile (< 768px): 1 column
          return Column(
            children: [
              card1,
              const SizedBox(height: AppConstants.paddingSmall),
              card2,
              const SizedBox(height: AppConstants.paddingSmall),
              card3,
              const SizedBox(height: AppConstants.paddingSmall),
              card4,
            ],
          );
        } else if (width < AppConstants.desktopBreakpoint) {
          // Tablet (768px - 1024px): 2 columns
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        } else {
          // Desktop (> 1024px): 4 columns
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(child: card2),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(child: card3),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(child: card4),
            ],
          );
        }
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;

          final filters = Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Utility Type Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedUtilityType.value,
                    items: [
                      const DropdownMenuItem(
                        value: 'All Utilities',
                        child: Text(
                          'All Utilities',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      ...(controller.dynamicUtilityTypes.isNotEmpty
                              ? controller.dynamicUtilityTypes
                              : AppConstants.utilitySubcategories)
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
                        controller.onUtilityTypeSelected(val);
                      }
                    },
                  ),
                ),
              ),

              // Payment Status Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedPaymentStatus.value,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(
                          'All Payment Statuses',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'paid',
                        child: Text(
                          'Paid Only',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text(
                          'Pending Only',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'overdue',
                        child: Text(
                          'Overdue Only',
                          style: TextStyle(fontSize: 13),
                        ),
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
            ],
          );

          final searchAndActions = Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Expanded(
                flex: isMobile ? 1 : 0,
                child: SizedBox(
                  width: isMobile ? null : 220,
                  height: 38,
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search bills...',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: Obx(() =>
                          controller.searchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: controller.clearSearch,
                                )
                              : const SizedBox.shrink()),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingSmall,
                        vertical: 8,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${controller.totalCount.value} ${controller.totalCount.value == 1 ? "bill" : "bills"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Tooltip(
                message: 'Refresh Bills',
                child: InkWell(
                  onTap: () => controller.loadUtilityBills(isReset: true),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                filters,
                const SizedBox(height: AppConstants.paddingSmall),
                searchAndActions,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              filters,
              searchAndActions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasActiveFilter = controller.selectedCity.value != 'All Cities' ||
        controller.selectedUtilityType.value != 'All Utilities' ||
        controller.selectedPaymentStatus.value != 'all' ||
        controller.searchQuery.value.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.receipt_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              hasActiveFilter
                  ? 'No utility bills matching criteria'
                  : 'No utility bills found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              hasActiveFilter
                  ? 'Try changing or clearing your selected filters or search query.'
                  : 'Upload a new electricity, water, gas or broadband bill to track it here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasActiveFilter) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLarge,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                    ),
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Clear All Filters'),
                    onPressed: () {
                      controller.selectedCity.value = 'All Cities';
                      controller.selectedUtilityType.value = 'All Utilities';
                      controller.selectedPaymentStatus.value = 'all';
                      controller.clearSearch();
                    },
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                ],
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                  ),
                  onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: const Text('Upload Utility Bill'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBillTile(DocumentModel doc) {
    final u = doc.utilityMetadata;
    final addr = doc.address;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildCategoryIcon(doc.subCategory),
            const SizedBox(width: AppConstants.paddingSmall),
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
                  const SizedBox(height: 2),
                  Text(
                    '${u?.providerName ?? "Provider"} • Consumer: ${u?.consumerNumber ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
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
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'City: ${addr?.city ?? "N/A"} • Due: ${AppFormatters.formatDate(u?.dueDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatCurrency(u?.billAmount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            _buildActionsRow(doc),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopBillTile(DocumentModel doc) {
    final u = doc.utilityMetadata;
    final addr = doc.address;

    return Row(
      children: [
        _buildCategoryIcon(doc.subCategory),
        const SizedBox(width: AppConstants.paddingMedium),
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
                  fontSize: 12,
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
                addr?.city ?? 'All Cities',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                addr?.premiseName ?? addr?.areaLocality ?? 'Premises',
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
                'Due: ${AppFormatters.formatDate(u?.dueDate)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: u?.isOverdue == true
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bill: ${AppFormatters.formatDate(u?.billDate)}',
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
        _buildActionsRow(doc),
      ],
    );
  }

  Widget _buildActionsRow(DocumentModel doc) {
    final u = doc.utilityMetadata;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            u?.isPaid == true
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: u?.isPaid == true ? AppColors.success : AppColors.textMuted,
            size: 20,
          ),
          tooltip: u?.isPaid == true ? 'Mark as Pending' : 'Mark as Paid',
          onPressed: () => controller.confirmPaymentStatus(doc),
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
          icon: const Icon(Icons.edit_outlined, size: 20),
          tooltip: 'Edit Bill Details',
          onPressed: () => controller.openEditDocumentDialog(doc),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: AppColors.error,
          ),
          tooltip: 'Move to Trash',
          onPressed: () => controller.confirmMoveToTrash(doc),
        ),
      ],
    );
  }

  Widget _buildCategoryIcon(String subCategory) {
    IconData icon;
    Color color;

    switch (subCategory.toLowerCase()) {
      case 'electricity / light bill':
      case 'electricity / light':
        icon = Icons.bolt_rounded;
        color = AppColors.utilityAmber;
        break;
      case 'piped gas / lpg':
      case 'gas bill (png / piped)':
      case 'gas cylinder (lpg)':
        icon = Icons.local_fire_department_rounded;
        color = AppColors.error;
        break;
      case 'water bill':
      case 'water & drainage bill':
        icon = Icons.water_drop_rounded;
        color = AppColors.financeBlue;
        break;
      case 'internet / broadband':
      case 'broadband / internet':
      case 'internet / broadband bill':
        icon = Icons.wifi_rounded;
        color = AppColors.primary;
        break;
      case 'property tax':
      case 'property tax / house tax':
        icon = Icons.home_work_rounded;
        color = AppColors.secondary;
        break;
      default:
        icon = Icons.receipt_long_rounded;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

