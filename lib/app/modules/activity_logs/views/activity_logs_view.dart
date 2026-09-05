import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/activity_log_model.dart';
import 'package:kt_prod_kt_docs/app/modules/activity_logs/controllers/activity_logs_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Activity & Audit Logs View.
/// Strictly conforms to AI Master Context: 3-tier MVC, table pagination, responsive layout, zero bare spinners.
class ActivityLogsView extends GetView<ActivityLogsController> {
  const ActivityLogsView({super.key});

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'uploaded':
        return Icons.cloud_upload_outlined;
      case 'viewed':
        return Icons.visibility_outlined;
      case 'downloaded':
        return Icons.download_outlined;
      case 'shared':
        return Icons.share_outlined;
      case 'updated':
        return Icons.edit_outlined;
      case 'trashed':
        return Icons.delete_outline;
      case 'restored':
        return Icons.restore;
      case 'permanently_deleted':
        return Icons.delete_forever;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'uploaded':
        return AppColors.success;
      case 'downloaded':
        return AppColors.primary;
      case 'shared':
        return AppColors.secondary;
      case 'updated':
        return AppColors.taxPurple;
      case 'trashed':
        return AppColors.warning;
      case 'permanently_deleted':
        return AppColors.error;
      case 'restored':
        return AppColors.warrantyEmerald;
      case 'viewed':
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Activity & Audit Logs',
      subtitle:
          'Complete chronological history of document access, uploads, updates, and deletions',
      currentRoute: AppRoutes.ACTIVITY_LOGS,
      body: Obx(() {
        // Section 5: Strict Shimmer Skeleton Loader - Zero bare spinners
        if (controller.isLoading.value) {
          return const ActivityLogsSkeletonView();
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadActivityLogs(isReset: true),
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Search & Filter Toolbar
                _buildToolbar(context),

                const SizedBox(height: AppConstants.paddingMedium),

                // 2. Logs Content Area
                if (controller.isTableLoading.value)
                  const AppShimmer(
                    child: Column(
                      children: [
                        ActivityLogRowSkeleton(),
                        SizedBox(height: 10),
                        ActivityLogRowSkeleton(),
                        SizedBox(height: 10),
                        ActivityLogRowSkeleton(),
                        SizedBox(height: 10),
                        ActivityLogRowSkeleton(),
                      ],
                    ),
                  )
                else if (controller.activities.isEmpty)
                  _buildEmptyState()
                else
                  _buildLogsList(context),

                const SizedBox(height: AppConstants.paddingLarge),

                // 3. Section 6.B Table Pagination Toolbar
                if (controller.totalCount.value > 0)
                  _buildPaginationToolbar(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ================= 1. TOOLBAR =================
  Widget _buildToolbar(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppConstants.desktopBreakpoint;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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
          // Row 1: Search & Counter
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSearchInput(),
                _buildCountBadge(),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchInput(fullWidth: true),
                const SizedBox(height: 10),
                _buildCountBadge(),
              ],
            ),

          const SizedBox(height: 14),

          // Row 2: Action Type Filter Chips (Wrap prevents horizontal overflow)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.actionFilters.map((filter) {
              return Obx(() {
                final isSelected =
                    controller.selectedActionFilter.value == filter['key'];
                final icon = filter['icon'] as IconData;
                final label = filter['label'] as String;

                return InkWell(
                  onTap: () => controller.setActionFilter(filter['key'] as String),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput({bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 280,
      height: 38,
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search audit logs...',
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
              onPressed: controller.clearSearch,
              splashRadius: 14,
            );
          }),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '${controller.totalCount.value} Total Events',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ================= 2. LOGS LIST =================
  Widget _buildLogsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = controller.activities[index];
        return _buildLogCard(context, log);
      },
    );
  }

  Widget _buildLogCard(BuildContext context, ActivityLogModel log) {
    final iconColor = _getActionColor(log.action);
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AppConstants.tabletBreakpoint;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Icon Avatar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Icon(
              _getActionIcon(log.action),
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Main Log Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: User name & Action Badge
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      log.userName ?? 'System User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        log.actionDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                    if (!isCompact)
                      Text(
                        AppFormatters.formatDateTime(log.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Target Document or Details Summary
                if (log.documentTitle != null)
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          log.documentTitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (log.details.isNotEmpty)
                  Text(
                    'Details: ${log.details}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),

                // Compact view timestamp
                if (isCompact) ...[
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.formatDateTime(log.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Details Action Button
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
            tooltip: 'View Audit Details',
            splashRadius: 18,
            onPressed: () => controller.openLogDetailsDialog(log),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              ),
              child: const Icon(Icons.history_toggle_off, size: 42, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'No activity events recorded',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Audit log entries will appear automatically as documents are accessed or modified.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ================= 3. SECTION 6.B TABLE PAGINATION TOOLBAR =================
  Widget _buildPaginationToolbar(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AppConstants.tabletBreakpoint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: isCompact
          ? Column(
              children: [
                _buildItemRangeText(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPageSizeDropdown(),
                    _buildPaginationButtons(),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildItemRangeText(),
                    const SizedBox(width: 16),
                    _buildPageSizeDropdown(),
                  ],
                ),
                _buildPaginationButtons(),
              ],
            ),
    );
  }

  Widget _buildItemRangeText() {
    return Obx(() {
      return Text(
        'Showing ${controller.startEntry}–${controller.endEntry} of ${controller.totalCount.value} entries',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      );
    });
  }

  Widget _buildPageSizeDropdown() {
    return Obx(() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Rows: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: controller.pageSize.value,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 25, child: Text('25')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                  DropdownMenuItem(value: 100, child: Text('100')),
                ],
                onChanged: (val) {
                  if (val != null) controller.changePageSize(val);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPaginationButtons() {
    return Obx(() {
      final current = controller.currentPage.value;
      final total = controller.totalPages;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First Page
          IconButton(
            icon: const Icon(Icons.first_page, size: 18),
            tooltip: 'First Page',
            onPressed: controller.hasPrevPage ? () => controller.changePage(1) : null,
            splashRadius: 16,
          ),
          // Previous Page
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            tooltip: 'Previous Page',
            onPressed: controller.hasPrevPage ? () => controller.changePage(current - 1) : null,
            splashRadius: 16,
          ),
          // Page Indicator Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Text(
              '$current / $total',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          // Next Page
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            tooltip: 'Next Page',
            onPressed: controller.hasNextPage ? () => controller.changePage(current + 1) : null,
            splashRadius: 16,
          ),
          // Last Page
          IconButton(
            icon: const Icon(Icons.last_page, size: 18),
            tooltip: 'Last Page',
            onPressed: controller.hasNextPage ? () => controller.changePage(total) : null,
            splashRadius: 16,
          ),
        ],
      );
    });
  }
}
