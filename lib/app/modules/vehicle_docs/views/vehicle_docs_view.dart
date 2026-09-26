import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/controllers/vehicle_docs_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class VehicleDocsView extends GetView<VehicleDocsController> {
  const VehicleDocsView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Vehicle Documents Vault',
      subtitle:
          'Track RC Books, Insurance Policies, PUC, Road Tax, and Service Bills by vehicle',
      currentRoute: AppRoutes.VEHICLE_DOCS,
      headerActions: [
        if (controller.canEdit) ...[
          OutlinedButton.icon(
            onPressed: () => controller.openAddVehicleDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Vehicle'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => controller.openAddServiceDialog(),
            icon: const Icon(Icons.build_circle_outlined, size: 16),
            label: const Text('Log Service'),
          ),
        ],
      ],
      body: Obx(() {
        if (controller.isLoading.value) {
          return VehicleDocsSkeletonView(isGridView: controller.isGridView.value);
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadVehicleDocuments(resetPage: true),
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Top Section: Vehicles Bar & Metric Cards
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle Filter Chips (with + Add Vehicle action)
                      _buildVehicleFilterChips(),

                      const SizedBox(height: 16),

                      // Selected Vehicle Details Banner (when a single vehicle is selected!)
                      if (controller.selectedVehicle.value != null) ...[
                        _buildSelectedVehicleBanner(
                          controller.selectedVehicle.value!,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Metrics Row (Responsive 1/2/4 Columns)
                      _buildMetricsRow(),

                      const SizedBox(height: 18),

                      // Section Tabs: Documents & Passes vs Service & Maintenance
                      _buildSectionTabs(),
                    ],
                  ),
                ),
              ),

              if (controller.selectedTab.value == 0) ...[
                // 2. Secondary Filter Toolbar (Doc Types, Expiry Filters, Search, Grid/List)
                SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: AppColors.background,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Doc Type Dropdown / Tabs
                      _buildDocTypeFilter(),

                      // Expiry Status Filter
                      _buildExpiryStatusFilter(),

                      // Search Input
                      _buildSearchBox(),

                      // Grid / List Toggle
                      _buildViewModeToggle(),

                      // Count text
                      Text(
                        '${controller.totalCount.value} documents'
                        '${controller.selectedVehicle.value != null ? " for ${controller.selectedVehicle.value!.vehicleNumber}" : " (${controller.totalVehiclesCount.value} vehicles)"}',
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

              // 3. Main Content: Grid, List, or Empty State
              if (controller.vehicleDocuments.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else if (controller.isGridView.value)
                _buildSliverGrid()
              else
                _buildSliverList(),

              // 4. Infinite Scroll Pagination Loader
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.isLoadingMore.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: AppShimmer(
                          child: ShimmerBox(
                            width: 220,
                            height: 24,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                        ),
                      ),
                    );
                  }
                  if (!controller.hasMore.value &&
                      controller.vehicleDocuments.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Showing all ${controller.vehicleDocuments.length} vehicle documents',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 32);
                }),
              ),
            ] else ...[
              // Service & Maintenance Logs Section
              SliverToBoxAdapter(
                child: _buildServiceSectionToolbar(),
              ),

              if (controller.vehicleServices.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyServicesState(),
                )
              else
                _buildServiceLogsSliverList(),
            ],
          ],
          ),
        );
      }),
    );
  }

  // --- Subcomponents & Widgets ---

  Widget _buildVehicleFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Vehicle:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // All Vehicles Chip
              Obx(() {
                final isSelected = controller.selectedVehicle.value == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      Icons.apps,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    label: const Text('All Vehicles'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    onSelected: (_) => controller.selectVehicle(null),
                  ),
                );
              }),

              // Vehicle Master Chips
              Obx(
                () => Row(
                  children: controller.masterVehicles.map((vehicle) {
                    final isSelected =
                        controller.selectedVehicle.value?.id == vehicle.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          vehicle.vehicleType.toLowerCase().contains('two')
                              ? Icons.two_wheeler
                              : Icons.directions_car,
                          size: 16,
                          color:
                              isSelected ? Colors.white : AppColors.primary,
                        ),
                        label: Text(vehicle.shortLabel),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (_) => controller.selectVehicle(vehicle),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // + Add Vehicle Button
              if (controller.canEdit)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),
                    label: const Text('Add Vehicle'),
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    onPressed: () => controller.openAddVehicleDialog(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedVehicleBanner(MasterVehicleModel vehicle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;

              final identityWidget = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_car,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.vehicleNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.textPrimary,
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
                        Text(
                          vehicle.nickname ??
                              vehicle.modelName ??
                              'Registered Vehicle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.vehicleType} • ${vehicle.brandMake ?? ""} ${vehicle.modelName ?? ""} • Fuel: ${vehicle.fuelType ?? "Petrol"}'
                          '${vehicle.ownerName != null ? " • Owner: ${vehicle.ownerName}" : ""}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionsWidget = Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (controller.canEdit)
                    OutlinedButton.icon(
                      onPressed: () =>
                          controller.openEditVehicleDialog(vehicle),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit Vehicle'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => controller.selectVehicle(null),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('View All'),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    identityWidget,
                    const SizedBox(height: 10),
                    actionsWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: identityWidget),
                  const SizedBox(width: 12),
                  actionsWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Next Service & Maintenance Information Strip
          _buildNextServiceStrip(vehicle),
        ],
      ),
    );
  }

  Widget _buildNextServiceStrip(MasterVehicleModel vehicle) {
    return Obx(() {
      final latest = controller.latestService;
      final hasNextService = latest != null &&
          (latest.nextServiceDate != null || latest.nextServiceKm != null);

      Color statusColor;
      Color statusBg;
      String statusText;
      IconData statusIcon;

      if (!hasNextService) {
        statusColor = AppColors.primary;
        statusBg = AppColors.primary.withValues(alpha: 0.08);
        statusText = latest != null
            ? 'No Next Service Date Set'
            : 'No Service Records Yet';
        statusIcon = Icons.build_circle_outlined;
      } else if (latest.isNextServiceOverdue) {
        statusColor = AppColors.error;
        statusBg = AppColors.error.withValues(alpha: 0.1);
        statusText = latest.daysUntilNextService != null
            ? 'Overdue by ${latest.daysUntilNextService!.abs()} days!'
            : 'Overdue!';
        statusIcon = Icons.warning_rounded;
      } else if (latest.isNextServiceDueSoon) {
        statusColor = AppColors.warning;
        statusBg = AppColors.warning.withValues(alpha: 0.12);
        statusText = 'Due in ${latest.daysUntilNextService} days';
        statusIcon = Icons.alarm;
      } else {
        statusColor = AppColors.success;
        statusBg = AppColors.success.withValues(alpha: 0.1);
        statusText = latest.daysUntilNextService != null
            ? 'Due in ${latest.daysUntilNextService} days'
            : 'Scheduled';
        statusIcon = Icons.check_circle_outline;
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasNextService && latest.isNextServiceOverdue
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;
            return Flex(
              direction: isNarrow ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: isNarrow
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: isNarrow ? 0 : 1,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  hasNextService
                                      ? 'Next Service: ${latest.nextServiceKm != null ? "${AppFormatters.formatNumber(latest.nextServiceKm!)} KM" : ""}'
                                          '${latest.nextServiceKm != null && latest.nextServiceDate != null ? " or " : ""}'
                                          '${latest.nextServiceDate != null ? AppFormatters.formatDate(latest.nextServiceDate!) : ""}'
                                      : (latest != null
                                          ? 'Last Service: ${AppFormatters.formatNumber(latest.odometerKm)} KM'
                                          : 'Service & Maintenance'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              latest != null
                                  ? 'Last serviced at ${AppFormatters.formatNumber(latest.odometerKm)} KM on ${AppFormatters.formatDate(latest.serviceDate)} (${latest.serviceTypesSummary})'
                                  : 'No service records logged yet for ${vehicle.vehicleNumber}. Track oil changes & service schedules.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isNarrow) const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => controller.setTab(1),
                      icon: const Icon(Icons.history, size: 14),
                      label: const Text('View Logs'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => controller.openAddServiceDialog(),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Log Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildSectionTabs() {
    return Obx(() {
      final tab = controller.selectedTab.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabButton(
                title: 'Documents & Passes',
                icon: Icons.folder_shared_outlined,
                badgeCount: controller.totalCount.value,
                isSelected: tab == 0,
                onTap: () => controller.setTab(0),
              ),
              const SizedBox(width: 4),
              _buildTabButton(
                title: 'Service & Maintenance Logs',
                icon: Icons.build_circle_outlined,
                badgeCount: controller.vehicleServices.length,
                isSelected: tab == 1,
                onTap: () => controller.setTab(1),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required int badgeCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSectionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          return Flex(
            direction: isNarrow ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isNarrow
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => Text(
                      'Service History (${controller.vehicleServices.length} records'
                      '${controller.selectedVehicle.value != null ? " for ${controller.selectedVehicle.value!.vehicleNumber}" : " across all vehicles"})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Obx(() {
                    if (controller.totalServiceCost <= 0) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'Total Spent: ${AppFormatters.formatCurrency(controller.totalServiceCost)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              if (isNarrow) const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => controller.openAddServiceDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Service Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyServicesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.build_circle_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Service & Maintenance Records Logged',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log oil changes, filter replacements, periodic services, and brake inspections.\nTrack upcoming due kilometers and dates automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => controller.openAddServiceDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log First Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceLogsSliverList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      sliver: Obx(
        () => SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final service = controller.vehicleServices[index];
              return _buildServiceLogCard(service);
            },
            childCount: controller.vehicleServices.length,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceLogCard(VehicleServiceModel service) {
    final vehicle = controller.masterVehicles.firstWhereOrNull(
      (v) => v.id == service.vehicleId,
    );

    final odometerPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.speed_rounded,
            size: 16,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            '${AppFormatters.formatNumber(service.odometerKm)} KM',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    final dateWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          AppFormatters.formatDate(service.serviceDate),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );

    Widget? plateBadge;
    if (controller.selectedVehicle.value == null && vehicle != null) {
      plateBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          vehicle.vehicleNumber,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
    }

    Widget? nextServiceTag;
    if (service.nextServiceKm != null || service.nextServiceDate != null) {
      nextServiceTag = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: service.isNextServiceOverdue
              ? AppColors.error.withValues(alpha: 0.1)
              : (service.isNextServiceDueSoon
                  ? AppColors.warning.withValues(alpha: 0.12)
                  : AppColors.success.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: service.isNextServiceOverdue
                ? AppColors.error.withValues(alpha: 0.3)
                : (service.isNextServiceDueSoon
                    ? AppColors.warning.withValues(alpha: 0.3)
                    : AppColors.success.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              service.isNextServiceOverdue
                  ? Icons.error_outline
                  : (service.isNextServiceDueSoon
                      ? Icons.warning_amber_rounded
                      : Icons.alarm),
              size: 13,
              color: service.isNextServiceOverdue
                  ? AppColors.error
                  : (service.isNextServiceDueSoon
                      ? AppColors.warning
                      : AppColors.success),
            ),
            const SizedBox(width: 5),
            Text(
              'Next: ${service.nextServiceKm != null ? "${AppFormatters.formatNumber(service.nextServiceKm!)} KM" : ""}'
              '${service.nextServiceKm != null && service.nextServiceDate != null ? " • " : ""}'
              '${service.nextServiceDate != null ? AppFormatters.formatDate(service.nextServiceDate!) : ""}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: service.isNextServiceOverdue
                    ? AppColors.error
                    : (service.isNextServiceDueSoon
                        ? AppColors.warning
                        : AppColors.success),
              ),
            ),
          ],
        ),
      );
    }

    final costWidget = service.costAmount > 0
        ? Text(
            AppFormatters.formatCurrency(service.costAmount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          )
        : null;

    final actionsWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.canEdit)
          IconButton(
            onPressed: () => controller.openEditServiceDialog(service),
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit Service Log',
            color: AppColors.textSecondary,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        if (controller.canDelete)
          IconButton(
            onPressed: () => controller.deleteServiceRecord(service),
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Delete Service Log',
            color: AppColors.error,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, cardConstraints) {
              final isCompact = cardConstraints.maxWidth < 680;

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        odometerPill,
                        const SizedBox(width: 8),
                        dateWidget,
                        const Spacer(),
                        ?costWidget,
                        const SizedBox(width: 4),
                        actionsWidget,
                      ],
                    ),
                    if (plateBadge != null || nextServiceTag != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ?plateBadge,
                          ?nextServiceTag,
                        ],
                      ),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        odometerPill,
                        dateWidget,
                        ?plateBadge,
                        ?nextServiceTag,
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ?costWidget,
                  const SizedBox(width: 6),
                  actionsWidget,
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Service Items Chips (Engine Oil, Filters, etc.)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: service.serviceTypes.map((type) {
              final isOil = type.toLowerCase().contains('oil');
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOil
                      ? const Color(0xFFFFF7ED)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isOil
                        ? const Color(0xFFFDBA74)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOil ? Icons.opacity : Icons.build,
                      size: 13,
                      color:
                          isOil ? const Color(0xFFEA580C) : AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOil
                            ? const Color(0xFFC2410C)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Details Row (Service Center, Bill No, Notes)
          if ((service.serviceCenterName != null &&
                  service.serviceCenterName!.isNotEmpty) ||
              (service.billNumber != null &&
                  service.billNumber!.isNotEmpty) ||
              (service.notes != null && service.notes!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (service.serviceCenterName != null &&
                    service.serviceCenterName!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        service.serviceCenterName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                if (service.billNumber != null &&
                    service.billNumber!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Inv: ${service.billNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                if (service.notes != null && service.notes!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        service.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final int crossAxisCount = w > 1024 ? 4 : (w > 600 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final cards = [
              MetricCard(
                title: 'Total Vehicle Docs',
                value: '${controller.totalDocumentsCount.value}',
                icon: Icons.description_outlined,
                accentColor: AppColors.primary,
                subtitle: 'Active & historical files',
              ),
              MetricCard(
                title: 'Registered Vehicles',
                value: '${controller.totalVehiclesCount.value}',
                icon: Icons.directions_car_outlined,
                accentColor: const Color(0xFF0284C7),
                subtitle: 'Two/four wheelers linked',
              ),
              MetricCard(
                title: 'Expiring Soon',
                value: '${controller.expiringSoonCount.value}',
                icon: Icons.alarm,
                accentColor: AppColors.warning,
                subtitle: 'Due within 30 days',
              ),
              MetricCard(
                title: 'Expired Docs',
                value: '${controller.expiredCount.value}',
                icon: Icons.error_outline,
                accentColor: AppColors.error,
                subtitle: 'Immediate renewal required',
              ),
            ];
            return cards[index];
          },
        );
      },
    );
  }

  Widget _buildDocTypeFilter() {
    return Obx(() {
      final docTypes = [
        'All Docs',
        'RC Book',
        'Insurance Policy',
        'PUC Certificate',
        'Fitness Certificate',
        'Service & Maintenance Bill',
        'Road Tax Receipt',
        'Purchase Invoice / Bill',
        'Fastag / Toll Pass',
        'Loan / Hypothecation NOC',
      ];

      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: docTypes.contains(controller.selectedDocType.value)
                ? controller.selectedDocType.value
                : 'All Docs',
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            items: docTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) controller.selectDocType(val);
            },
          ),
        ),
      );
    });
  }

  Widget _buildExpiryStatusFilter() {
    return Obx(() {
      final statuses = [
        'All',
        'Active',
        'Expiring in 30 Days',
        'Expired',
      ];

      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedExpiryFilter.value,
            icon: const Icon(Icons.filter_list, size: 18),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            items: statuses.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status == 'All' ? 'All Statuses' : status),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) controller.selectExpiryFilter(val);
            },
          ),
        ),
      );
    });
  }

  Widget _buildSearchBox() {
    return SizedBox(
      width: 240,
      height: 38,
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search policy, vehicle, file...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: controller.clearSearch,
              );
            }
            return const SizedBox.shrink();
          }),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Obx(
      () => Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: controller.isGridView.value
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              onPressed: () {
                if (!controller.isGridView.value) controller.toggleViewMode();
              },
              tooltip: 'Grid View',
            ),
            Container(width: 1, height: 20, color: AppColors.border),
            IconButton(
              icon: Icon(
                Icons.view_list_rounded,
                size: 20,
                color: !controller.isGridView.value
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              onPressed: () {
                if (controller.isGridView.value) controller.toggleViewMode();
              },
              tooltip: 'List View',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Vehicle Documents Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No documents match your current filter criteria.\nUpload RC, Insurance, or PUC to begin organizing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (controller.canEdit)
              ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Document Now'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.crossAxisExtent;
          final int crossAxisCount = w > 1200 ? 3 : (w > 768 ? 2 : 1);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: crossAxisCount == 1 ? 245.0 : 285.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = controller.vehicleDocuments[index];
                return _VehicleDocumentCard(
                  doc: doc,
                  controller: controller,
                );
              },
              childCount: controller.vehicleDocuments.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final doc = controller.vehicleDocuments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VehicleDocumentListTile(
                doc: doc,
                controller: controller,
              ),
            );
          },
          childCount: controller.vehicleDocuments.length,
        ),
      ),
    );
  }
}

// --- Dedicated Vehicle Document Card ---

class _VehicleDocumentCard extends StatelessWidget {
  final DocumentModel doc;
  final VehicleDocsController controller;

  const _VehicleDocumentCard({
    required this.doc,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final meta = doc.vehicleMetadata;
    final isExpired = meta?.isExpired ?? false;
    final isExpiringSoon = meta?.isExpiringSoon ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? AppColors.error.withValues(alpha: 0.4)
              : (isExpiringSoon
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : AppColors.border),
          width: isExpired || isExpiringSoon ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.previewDocument(doc),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Vehicle Reg Pill & Expiry Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Vehicle Plate Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            meta?.vehicleNumber ?? 'VEHICLE',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expiry Badge
                    if (meta?.expiryDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: meta!.statusBadgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: meta.statusBadgeColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          meta.expiryStatusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: meta.statusBadgeColor,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'No Expiry',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Document Title & Subcategory
                Text(
                  doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Doc Type & Policy/Cert Number
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meta?.docTypeName ?? doc.subCategory,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (meta?.policyOrCertNumber != null &&
                        meta!.policyOrCertNumber!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '# ${meta.policyOrCertNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const Spacer(),

                // Detailed Specs: Insurance/Vendor, Validity, Amount, FASTag / Pass Info
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      if (meta?.isPassOrFastag == true) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.toll_outlined,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                meta!.tollPlazaName ??
                                    meta.passType ??
                                    'Toll / Annual Pass',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (meta.passType != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  meta.passType!,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (meta.fastagId != null &&
                            meta.fastagId!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.qr_code_scanner,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tag: ${meta.fastagId}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                      ],
                      if (meta != null &&
                          meta.insuranceCompany != null &&
                          meta.insuranceCompany!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              meta.isPassOrFastag == true
                                  ? Icons.account_balance_outlined
                                  : Icons.verified_user_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                meta.insuranceCompany!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (meta.premiumAmount != null &&
                                meta.premiumAmount! > 0)
                              Text(
                                AppFormatters.formatCurrency(meta.premiumAmount!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      if (meta?.expiryDate != null) ...[
                        if (meta?.insuranceCompany != null &&
                            meta!.insuranceCompany!.isNotEmpty)
                          const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.event_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Valid: ${meta?.issueDate != null ? AppFormatters.formatDate(meta!.issueDate!) : "Start"} → ${AppFormatters.formatDate(meta!.expiryDate!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Bottom Action Toolbar (Preview, Download, Share, Fav, Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${doc.fileType.toUpperCase()} • ${AppFormatters.formatFileSize(doc.fileSize)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download_outlined, size: 18),
                          onPressed: () => controller.downloadDocument(doc),
                          tooltip: 'Download',
                          color: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          onPressed: () => controller.shareDocument(doc),
                          tooltip: 'Share',
                          color: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(
                            doc.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: doc.isFavorite
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          onPressed: () => controller.toggleFavorite(doc),
                          tooltip: 'Favorite',
                          visualDensity: VisualDensity.compact,
                        ),
                        if (controller.canDelete)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () =>
                                controller.softDeleteDocument(doc),
                            tooltip: 'Delete',
                            color: AppColors.error,
                            visualDensity: VisualDensity.compact,
                          ),
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

// --- Dedicated Vehicle Document List Tile ---

class _VehicleDocumentListTile extends StatelessWidget {
  final DocumentModel doc;
  final VehicleDocsController controller;

  const _VehicleDocumentListTile({
    required this.doc,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final meta = doc.vehicleMetadata;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Plate + Title + Expiry
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meta?.vehicleNumber ?? 'VEHICLE',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (meta?.expiryDate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              meta!.statusBadgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meta.expiryStatusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: meta.statusBadgeColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Subtitle specs
                Text(
                  '${meta?.docTypeName ?? doc.subCategory}'
                  '${meta?.passType != null ? " [${meta!.passType}]" : ""}'
                  '${meta?.tollPlazaName != null ? " • ${meta!.tollPlazaName}" : ""}'
                  '${meta?.policyOrCertNumber != null ? " • #${meta!.policyOrCertNumber}" : ""}'
                  '${meta?.fastagId != null && meta!.fastagId!.isNotEmpty ? " • Tag: ${meta.fastagId}" : ""}'
                  '${meta?.expiryDate != null ? " • Expires: ${AppFormatters.formatDate(meta!.expiryDate!)}" : ""}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 4),
                // Bottom row: File type/size + Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${doc.fileType.toUpperCase()} • ${AppFormatters.formatFileSize(doc.fileSize)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined,
                              size: 18),
                          onPressed: () => controller.previewDocument(doc),
                          tooltip: 'Preview',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.download_outlined, size: 18),
                          onPressed: () => controller.downloadDocument(doc),
                          tooltip: 'Download',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          onPressed: () => controller.shareDocument(doc),
                          tooltip: 'Share',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                        if (controller.canDelete) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () =>
                                controller.softDeleteDocument(doc),
                            tooltip: 'Delete',
                            color: AppColors.error,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                meta?.isPassOrFastag == true
                    ? Icons.toll
                    : Icons.directions_car,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    meta?.vehicleNumber ?? 'VEHICLE',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${meta?.docTypeName ?? doc.subCategory}'
                '${meta?.passType != null ? " [${meta!.passType}]" : ""}'
                '${meta?.tollPlazaName != null ? " • ${meta!.tollPlazaName}" : ""}'
                '${meta?.policyOrCertNumber != null ? " • #${meta!.policyOrCertNumber}" : ""}'
                '${meta?.fastagId != null && meta!.fastagId!.isNotEmpty ? " • Tag: ${meta.fastagId}" : ""}'
                '${meta?.expiryDate != null ? " • Expires: ${AppFormatters.formatDate(meta!.expiryDate!)}" : ""}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (meta?.expiryDate != null)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: meta!.statusBadgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      meta.expiryStatusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: meta.statusBadgeColor,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  onPressed: () => controller.previewDocument(doc),
                  tooltip: 'Preview',
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined, size: 18),
                  onPressed: () => controller.downloadDocument(doc),
                  tooltip: 'Download',
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 18),
                  onPressed: () => controller.shareDocument(doc),
                  tooltip: 'Share',
                ),
                if (controller.canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => controller.softDeleteDocument(doc),
                    tooltip: 'Delete',
                    color: AppColors.error,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Realistic Shimmer Skeletons (Strict rule: NO bare spinners for content loading!) ---

class VehicleDocsSkeletonView extends StatelessWidget {
  final bool isGridView;

  const VehicleDocsSkeletonView({
    super.key,
    required this.isGridView,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar Skeleton
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Chips Skeleton
                const Row(
                  children: [
                    ShimmerBox(
                        width: 100,
                        height: 32,
                        borderRadius: BorderRadius.all(Radius.circular(16))),
                    SizedBox(width: 8),
                    ShimmerBox(
                        width: 130,
                        height: 32,
                        borderRadius: BorderRadius.all(Radius.circular(16))),
                    SizedBox(width: 8),
                    ShimmerBox(
                        width: 120,
                        height: 32,
                        borderRadius: BorderRadius.all(Radius.circular(16))),
                  ],
                ),
                const SizedBox(height: 16),
                // Metric Cards Skeleton (1/2/4 Grid)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final int count = constraints.maxWidth > 1024
                        ? 4
                        : (constraints.maxWidth > 600 ? 2 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 112,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            ShimmerBox(
                                width: 42,
                                height: 42,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShimmerBox(
                                    width: 80,
                                    height: 12,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4))),
                                SizedBox(height: 8),
                                ShimmerBox(
                                    width: 40,
                                    height: 20,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cards/List Grid Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final int count = constraints.maxWidth > 1200
                    ? 3
                    : (constraints.maxWidth > 768 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: count == 1 ? 245.0 : 285.0,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox(
                                width: 90,
                                height: 22,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(6))),
                            ShimmerBox(
                                width: 70,
                                height: 22,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(6))),
                          ],
                        ),
                        SizedBox(height: 14),
                        ShimmerBox(
                            width: 180,
                            height: 16,
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                        SizedBox(height: 8),
                        ShimmerBox(
                            width: 120,
                            height: 12,
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                        Spacer(),
                        ShimmerBox(
                            width: double.infinity,
                            height: 38,
                            borderRadius: BorderRadius.all(Radius.circular(6))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
