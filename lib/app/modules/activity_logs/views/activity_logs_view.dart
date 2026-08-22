import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/activity_logs/controllers/activity_logs_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

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
        return AppColors.accent;
      case 'trashed':
        return AppColors.warning;
      case 'permanently_deleted':
        return AppColors.error;
      case 'restored':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Activity & Audit Logs',
      subtitle:
          'Complete chronological history of document access, uploads, and modifications',
      currentRoute: AppRoutes.ACTIVITY_LOGS,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.activities.isEmpty) {
          return const Center(
            child: Text(
              'No activity events recorded yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadActivityLogs,
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: controller.activities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final log = controller.activities[index];
              final iconColor = _getActionColor(log.action);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getActionIcon(log.action),
                          color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                log.userName ?? 'System User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                log.actionDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (log.documentTitle != null)
                            Text(
                              'Document: ${log.documentTitle}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            )
                          else if (log.details.isNotEmpty)
                            Text(
                              'Details: ${log.details}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.formatDateTime(log.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
