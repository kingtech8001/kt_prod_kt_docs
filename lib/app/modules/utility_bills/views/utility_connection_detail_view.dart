import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_connection_account.dart';
import 'package:kt_prod_kt_docs/app/modules/utility_bills/controllers/utility_connection_detail_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/google_drive_logo.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class UtilityConnectionDetailView
    extends GetView<UtilityConnectionDetailController> {
  const UtilityConnectionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Utility Account & Connection Details',
      subtitle:
          'Manage premises address, meter numbers, provider info, and view full billing history',
      currentRoute: AppRoutes.UTILITY_BILLS,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: UtilityBillsSkeletonView());
        }

        final acc = controller.connection.value;
        if (acc == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                const Text(
                  'Connection account not found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Utility Bills'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.reloadHistory,
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
                    // 1. Back Navigation Row
                    _buildBackNavigationRow(acc),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // 2. Hero Header Card
                    _buildHeroHeaderCard(acc),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // 3. Metrics Summary Row
                    _buildMetricsRow(acc),
                    const SizedBox(height: AppConstants.paddingLarge),

                    // 4. Main Body: Split into Address/Details Form & Billing Cycles History
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >=
                            AppConstants.desktopBreakpoint;

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Editable Connection & Address Form
                              Expanded(
                                flex: 5,
                                child: _buildAddressAndAccountForm(acc),
                              ),
                              const SizedBox(width: AppConstants.paddingLarge),
                              // Right: Billing Cycles Timeline
                              Expanded(
                                flex: 6,
                                child: _buildBillingHistorySection(),
                              ),
                            ],
                          );
                        }

                        // Tablet / Mobile: Stacked
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAddressAndAccountForm(acc),
                            const SizedBox(height: AppConstants.paddingLarge),
                            _buildBillingHistorySection(),
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

  Widget _buildBackNavigationRow(UtilityConnectionAccount acc) {
    return Row(
      children: [
        InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16, color: AppColors.textPrimary),
                SizedBox(width: 6),
                Text(
                  'Back to Utility Bills',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          acc.displayName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeaderCard(UtilityConnectionAccount acc) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;

          final info = Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: acc.accentColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(
                    color: acc.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(acc.iconData, color: acc.accentColor, size: 28),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            acc.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${controller.historyBills.length} CYCLES',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${acc.providerName} • Consumer #: ${acc.consumerNumber}${acc.meterNumber != null && acc.meterNumber!.isNotEmpty ? " • Meter: ${acc.meterNumber}" : ""}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            acc.fullAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                ),
                icon: const Icon(Icons.post_add_rounded, size: 18),
                label: const Text('Upload Next Bill'),
                onPressed: controller.openUploadNextBillDialog,
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: AppConstants.paddingMedium),
                actions,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: info),
              const SizedBox(width: AppConstants.paddingMedium),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricsRow(UtilityConnectionAccount acc) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final card1 = MetricCard(
          title: 'TOTAL SPEND (ALL CYCLES)',
          value: AppFormatters.formatCurrency(controller.totalSpent.value),
          icon: Icons.account_balance_wallet_outlined,
          accentColor: AppColors.financeBlue,
        );
        final card2 = MetricCard(
          title: 'LATEST BILL AMOUNT',
          value: AppFormatters.formatCurrency(acc.latestBillAmount),
          icon: Icons.receipt_long_rounded,
          accentColor: acc.accentColor,
        );
        final card3 = MetricCard(
          title: 'LATEST DUE DATE',
          value: AppFormatters.formatDate(acc.latestDueDate),
          icon: Icons.calendar_today_rounded,
          accentColor: acc.isOverdue ? AppColors.error : AppColors.primary,
        );
        final card4 = MetricCard(
          title: 'PAYMENT STATUS',
          value: acc.isPaid ? 'PAID' : (acc.isOverdue ? 'OVERDUE' : 'PENDING'),
          icon: acc.isPaid
              ? Icons.check_circle_outline
              : Icons.warning_amber_rounded,
          accentColor: acc.isPaid
              ? AppColors.success
              : (acc.isOverdue ? AppColors.error : AppColors.warning),
        );

        final width = constraints.maxWidth;
        if (width < AppConstants.tabletBreakpoint) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 8),
              card2,
              const SizedBox(height: 8),
              card3,
              const SizedBox(height: 8),
              card4,
            ],
          );
        } else if (width < AppConstants.desktopBreakpoint) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 12),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
            const SizedBox(width: 12),
            Expanded(child: card3),
            const SizedBox(width: 12),
            Expanded(child: card4),
          ],
        );
      },
    );
  }

  Widget _buildAddressAndAccountForm(UtilityConnectionAccount acc) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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
                  color: AppColors.primarySurface,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: const Icon(
                  Icons.edit_location_alt_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection & Address Details (Editable)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Changes save across all recurring cycles of this account',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Premise / Display Name
          const Text(
            'Premises / Office Name *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller.premiseNameController,
            decoration: const InputDecoration(
              hintText: 'e.g. RK Iconic, B-1118, Corporate HQ',
            ),
          ),
          const SizedBox(height: 12),

          // Provider & Utility Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provider Name *',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.providerNameController,
                      decoration:
                          const InputDecoration(hintText: 'e.g. PGVCL, Torrent'),
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
                      'Utility Type',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.utilityTypeController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Electricity / Light',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Consumer & Meter Number
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consumer Number / ID *',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.consumerNumberController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 61647126444',
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
                      'Meter Number',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.meterNumberController,
                      decoration:
                          const InputDecoration(hintText: 'e.g. MTR-1118'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'PHYSICAL PREMISES ADDRESS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Flat & Building
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flat / House / Unit No',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.flatHouseNoController,
                      decoration: const InputDecoration(hintText: 'e.g. B-1118'),
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
                      'Building / Tower Name',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.buildingNameController,
                      decoration:
                          const InputDecoration(hintText: 'e.g. RK Iconic'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Street Address & Area
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Street Address / Road',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.streetAddressController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 150 Feet Ring Road',
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
                      'Area / Locality',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.areaLocalityController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Sheetal Park, Nana Mava',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // City & Pincode
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'City *',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.cityController,
                      decoration:
                          const InputDecoration(hintText: 'e.g. Rajkot'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pincode',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.postalCodeController,
                      decoration:
                          const InputDecoration(hintText: 'e.g. 360005'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // State & Country
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'State',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.stateController,
                      decoration:
                          const InputDecoration(hintText: 'e.g. Gujarat'),
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
                      'Country',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.countryController,
                      decoration:
                          const InputDecoration(hintText: 'e.g. India'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                ),
                icon: controller.isSaving.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  controller.isSaving.value
                      ? 'Saving Address Changes...'
                      : 'Save Account & Address Changes',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveConnectionDetails,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingHistorySection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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
                  color: AppColors.surfaceMuted,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: const Icon(
                  Icons.history_edu_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Billing Cycles History',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Obx(
                      () => Text(
                        'Chronological ledger of all ${controller.historyBills.length} recorded bill cycles',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          Obx(() {
            final bills = controller.historyBills;
            if (bills.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No billing cycles found for this connection.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bills.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final doc = bills[index];
                final meta = doc.utilityMetadata;
                final isPaid = meta?.isPaid ?? false;
                final isOverdue = meta?.isOverdue ?? false;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted.withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                      color: isOverdue
                          ? AppColors.error.withValues(alpha: 0.4)
                          : AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cycle Index Badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            '#${bills.length - index}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Cycle Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (doc.isGoogleAttachment) ...[
                                  const GoogleDriveLogo(size: 14),
                                  const SizedBox(width: 5),
                                ],
                                Flexible(
                                  child: Text(
                                    doc.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bill Date: ${AppFormatters.formatDate(meta?.billDate ?? doc.createdAt)} • Due: ${AppFormatters.formatDate(meta?.dueDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                fontWeight: isOverdue
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Amount & Status Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(meta?.billAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          StatusBadge(
                            label: isPaid
                                ? 'PAID'
                                : (isOverdue ? 'OVERDUE' : 'PENDING'),
                            type: isPaid
                                ? StatusBadgeType.success
                                : (isOverdue
                                    ? StatusBadgeType.error
                                    : StatusBadgeType.warning),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            tooltip: 'Preview Bill',
                            onPressed: () => controller.previewDocument(doc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_outlined, size: 18),
                            tooltip: 'Download Bill',
                            onPressed: () => controller.downloadDocument(doc),
                          ),
                          IconButton(
                            icon: Icon(
                              isPaid
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isPaid
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              size: 18,
                            ),
                            tooltip: isPaid ? 'Mark as Pending' : 'Mark as Paid',
                            onPressed: () => controller.togglePaymentStatus(doc),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
