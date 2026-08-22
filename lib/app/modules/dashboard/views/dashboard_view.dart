import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Dashboard Overview',
      subtitle: 'King Technology document analytics, pending utility bills & warranty alerts',
      currentRoute: AppRoutes.DASHBOARD,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final m = controller.metrics.value;

        return RefreshIndicator(
          onRefresh: controller.loadDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Metrics Cards Grid (Responsive 1/2/4 Columns)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount = 4;
                    if (width < 600) {
                      crossAxisCount = 1;
                    } else if (width < 1000) {
                      crossAxisCount = 2;
                    }

                    final items = [
                      MetricCard(
                        title: 'TOTAL DOCUMENTS',
                        value: '${m.totalDocuments}',
                        subtitle: 'Active documents in vault',
                        icon: Icons.description_outlined,
                        accentColor: AppColors.primary,
                        onTap: () => Get.toNamed(AppRoutes.DOCUMENTS),
                      ),
                      MetricCard(
                        title: 'STORAGE UTILIZED',
                        value: AppFormatters.formatFileSize(m.totalStorageBytes),
                        subtitle: 'Encrypted private storage',
                        icon: Icons.cloud_done_outlined,
                        accentColor: AppColors.financeBlue,
                      ),
                      MetricCard(
                        title: 'EXPIRING WARRANTIES',
                        value: '${controller.expiringWarranties.length}',
                        subtitle: 'Due within 30 days',
                        icon: Icons.shield_outlined,
                        accentColor: AppColors.warrantyEmerald,
                        onTap: () => Get.toNamed(AppRoutes.APPLIANCES),
                      ),
                      MetricCard(
                        title: 'PENDING UTILITIES',
                        value: '${controller.pendingUtilityBills.length}',
                        subtitle: 'Light, Gas, Water bills',
                        icon: Icons.bolt_outlined,
                        accentColor: AppColors.utilityAmber,
                        onTap: () => Get.toNamed(AppRoutes.UTILITY_BILLS),
                      ),
                    ];

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 110,
                      ),
                      itemBuilder: (context, index) => items[index],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // 2. Action Alerts: Expiring Warranties & Pending Utility Bills
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 960;

                    final warrantiesSection = _buildExpiringWarrantiesCard();
                    final utilitiesSection = _buildPendingUtilitiesCard();

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: warrantiesSection),
                          const SizedBox(width: 20),
                          Expanded(child: utilitiesSection),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          warrantiesSection,
                          const SizedBox(height: 20),
                          utilitiesSection,
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 32),

                // 3. Recent Documents Section Header
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 500;
                    if (isCompact) {
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
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.DOCUMENTS),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('View All'),
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
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
                            Text(
                              'Latest bills, invoices, and files uploaded across all departments',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.DOCUMENTS),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('View All'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                if (controller.recentDocuments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_open_outlined, size: 48, color: AppColors.textMuted),
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
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
                          icon: const Icon(Icons.cloud_upload_outlined, size: 16),
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
                      if (width < 650) {
                        crossAxis = 1;
                      } else if (width < 1050) {
                        crossAxis = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.recentDocuments.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxis,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 240,
                        ),
                        itemBuilder: (context, index) {
                          final doc = controller.recentDocuments[index];
                          return DocumentCard(
                            document: doc,
                            onPreview: () => controller.previewDocument(doc),
                            onDownload: () => controller.downloadDocument(doc),
                            onShare: () => controller.shareDocument(doc),
                            onToggleFavorite: () => controller.toggleFavorite(doc),
                            onDelete: () => controller.moveToTrash(doc),
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
      padding: const EdgeInsets.all(20),
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
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
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
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.warning, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Brand: ${w?.brand ?? "N/A"} • Valid: ${AppFormatters.formatDate(w?.warrantyValidUpto)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.all(20),
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
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Due: ${AppFormatters.formatDate(u?.dueDate)} • ${doc.city}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
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
}
