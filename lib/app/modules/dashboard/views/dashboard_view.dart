import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/dashboard_metrics_model.dart';
import 'package:kt_prod_kt_docs/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/google_drive_logo.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Dashboard Overview',
      subtitle:
          'King Technology document analytics, pending utility bills & warranty alerts',
      currentRoute: AppRoutes.DASHBOARD,
      body: Obx(() {
        // Strict Rule: Shimmer loader mirroring layout geometry during loading state. Zero bare spinners.
        if (controller.isLoading.value) {
          return const DashboardSkeletonView();
        }

        final m = controller.metrics.value;

        return RefreshIndicator(
          onRefresh: controller.loadDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Metrics Cards (Responsive PC: 4 cols, Tablet: 2 cols, Mobile: 1 col)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final card1 = MetricCard(
                      title: 'TOTAL DOCUMENTS',
                      value: '${m.totalDocuments}',
                      subtitle: 'Active documents in vault',
                      icon: Icons.description_outlined,
                      accentColor: AppColors.primary,
                      onTap: () => Get.toNamed(AppRoutes.DOCUMENTS),
                    );
                    final card2 = MetricCard(
                      title: 'STORAGE UTILIZED',
                      value: AppFormatters.formatFileSize(m.totalStorageBytes),
                      subtitle: 'Encrypted private storage',
                      icon: Icons.cloud_done_outlined,
                      accentColor: AppColors.financeBlue,
                    );
                    final card3 = MetricCard(
                      title: 'EXPIRING WARRANTIES',
                      value: '${m.expiringWarrantiesCount}',
                      subtitle: 'Due within 30 days',
                      icon: Icons.shield_outlined,
                      accentColor: AppColors.warrantyEmerald,
                      onTap: () => Get.toNamed(AppRoutes.APPLIANCES),
                    );
                    final card4 = MetricCard(
                      title: 'PENDING UTILITIES',
                      value: '${m.pendingBillsCount}',
                      subtitle: 'Light, Gas, Water bills',
                      icon: Icons.bolt_outlined,
                      accentColor: AppColors.utilityAmber,
                      onTap: () => Get.toNamed(AppRoutes.UTILITY_BILLS),
                    );

                    if (width < AppConstants.tabletBreakpoint) {
                      // Mobile (< 768px): 1 column stacked cards
                      return Column(
                        children: [
                          card1,
                          const SizedBox(height: AppConstants.paddingSmall + 4),
                          card2,
                          const SizedBox(height: AppConstants.paddingSmall + 4),
                          card3,
                          const SizedBox(height: AppConstants.paddingSmall + 4),
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
                ),

                const SizedBox(height: 28),

                // 2. Action Alerts: Expiring Warranties & Pending Utility Bills
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop =
                        constraints.maxWidth >= AppConstants.desktopBreakpoint;

                    final warrantiesSection = _buildExpiringWarrantiesCard();
                    final utilitiesSection = _buildPendingUtilitiesCard();

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: warrantiesSection),
                          const SizedBox(width: AppConstants.paddingLarge),
                          Expanded(child: utilitiesSection),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          warrantiesSection,
                          const SizedBox(height: AppConstants.paddingLarge),
                          utilitiesSection,
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 24),

                // 3. Low-Priority Trash Storage & File Count Strip
                _buildTrashSummaryStrip(m),

                const SizedBox(height: AppConstants.paddingHero),

                // 4. Recent Documents Section Header
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile =
                        constraints.maxWidth < AppConstants.tabletBreakpoint;

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Documents',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Latest bills, invoices, and files uploaded across all departments',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: AppConstants.paddingSmall,
                            runSpacing: AppConstants.paddingSmall,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => Get.toNamed(AppRoutes.DOCUMENTS),
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('View All'),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Documents',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Latest bills, invoices, and files uploaded across all departments',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        OutlinedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.DOCUMENTS),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('View All'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // 4. Empty State or Responsive Document Grid
                if (controller.recentDocuments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.paddingHero),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.folder_open_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No documents uploaded yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Click "Upload" in the header to add your first bill or warranty invoice.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
                          icon: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 16,
                          ),
                          label: const Text('Upload Document Now'),
                        ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxis = 3;
                      if (width < AppConstants.tabletBreakpoint) {
                        crossAxis = 1;
                      } else if (width < AppConstants.desktopBreakpoint) {
                        crossAxis = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.recentDocuments.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxis,
                          crossAxisSpacing: AppConstants.paddingMedium,
                          mainAxisSpacing: AppConstants.paddingMedium,
                          mainAxisExtent: 240,
                        ),
                        itemBuilder: (context, index) {
                          final doc = controller.recentDocuments[index];
                          return DocumentCard(
                            document: doc,
                            onPreview: () => controller.previewDocument(doc),
                            onDownload: () => controller.downloadDocument(doc),
                            onToggleFavorite: () =>
                                controller.toggleFavorite(doc),
                            onEdit: () =>
                                controller.openEditDocumentDialog(doc),
                            onDelete: () => controller.confirmMoveToTrash(doc),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildExpiringWarrantiesCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Warranties Expiring Soon',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.APPLIANCES),
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 20),
          if (controller.expiringWarranties.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No warranties expiring in next 30 days 🎉',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.expiringWarranties.take(4).length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final doc = controller.expiringWarranties[index];
                final w = doc.applianceWarranty;
                final days = w?.daysUntilExpiry ?? 0;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      decoration: BoxDecoration(
                        color: doc.isGoogleAttachment
                            ? const Color(0xFFF0FDF4)
                            : AppColors.warningLight.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                        border: doc.isGoogleAttachment
                            ? Border.all(color: const Color(0xFF86EFAC), width: 1)
                            : null,
                      ),
                      child: doc.isGoogleAttachment
                          ? const GoogleDriveLogo(size: 18)
                          : const Icon(
                              Icons.shield_outlined,
                              color: AppColors.warning,
                              size: 18,
                            ),
                    ),
                    const SizedBox(width: 12),
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
                              Expanded(
                                child: Text(
                                  doc.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (doc.isGoogleAttachment) ...[
                                const SizedBox(width: 6),
                                const GoogleDriveBadge(compact: true),
                              ],
                            ],
                          ),
                          Text(
                            'Brand: ${w?.brand ?? "N/A"} • Valid: ${AppFormatters.formatDate(w?.warrantyValidUpto)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: '$days Days Left',
                      type: StatusBadgeType.warning,
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPendingUtilitiesCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: AppColors.utilityAmber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Pending Utility Bills',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.UTILITY_BILLS),
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 20),
          if (controller.pendingUtilityBills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'All utility bills are up to date! ✅',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.pendingUtilityBills.take(4).length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final doc = controller.pendingUtilityBills[index];
                final u = doc.utilityMetadata;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      decoration: BoxDecoration(
                        color: doc.isGoogleAttachment
                            ? const Color(0xFFF0FDF4)
                            : AppColors.primarySurface,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                        border: doc.isGoogleAttachment
                            ? Border.all(color: const Color(0xFF86EFAC), width: 1)
                            : null,
                      ),
                      child: doc.isGoogleAttachment
                          ? const GoogleDriveLogo(size: 18)
                          : const Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                    ),
                    const SizedBox(width: 12),
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
                              Expanded(
                                child: Text(
                                  doc.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (doc.isGoogleAttachment) ...[
                                const SizedBox(width: 6),
                                const GoogleDriveBadge(compact: true),
                              ],
                            ],
                          ),
                          Text(
                            'Due: ${AppFormatters.formatDate(u?.dueDate)} • ${doc.city}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppFormatters.formatCurrency(u?.billAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrashSummaryStrip(DashboardMetricsModel m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;
          final trashCountText =
              m.trashCount == 1 ? '1 file' : '${m.trashCount} files';
          final trashSizeText = AppFormatters.formatFileSize(m.trashSizeBytes);

          final infoContent = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Trash Bin',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'Low Priority',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.trashCount > 0
                          ? '$trashCountText in trash ($trashSizeText total) • Soft-deleted documents pending permanent purge'
                          : 'Trash bin is empty • 0 B recoverable storage',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButton = OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.TRASH),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.arrow_forward, size: 14),
            label: const Text('View Trash', style: TextStyle(fontSize: 12)),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoContent,
                const SizedBox(height: AppConstants.paddingSmall + 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: actionButton,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: infoContent),
              const SizedBox(width: AppConstants.paddingMedium),
              actionButton,
            ],
          );
        },
      ),
    );
  }
}
