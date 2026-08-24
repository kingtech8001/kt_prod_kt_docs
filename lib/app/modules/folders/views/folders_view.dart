import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/folders/controllers/folders_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class FoldersView extends GetView<FoldersController> {
  const FoldersView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Folder Explorer',
      subtitle: 'Organize documents into departmental and project folders',
      currentRoute: AppRoutes.FOLDERS,
      headerActions: [
        ElevatedButton.icon(
          onPressed: controller.openCreateFolderDialog,
          icon: const Icon(Icons.create_new_folder_outlined, size: 16),
          label: const Text('New Folder'),
        ),
        const SizedBox(width: 12),
      ],
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.folders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_open_outlined, size: 56, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text(
                  'No folders created yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Group documents into structured categories like Legal, Invoices, HR, or Branches.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.openCreateFolderDialog,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                  label: const Text('Create First Folder'),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxis = 4;
            if (width < 750) {
              crossAxis = 1;
            } else if (width < 1100) {
              crossAxis = 2;
            } else if (width < 1400) {
              crossAxis = 3;
            }

            return GridView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: controller.folders.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxis,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 140,
              ),
              itemBuilder: (context, index) {
                final folder = controller.folders[index];
                return RepaintBoundary(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${AppFormatters.formatDate(folder.createdAt)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () => Get.toNamed(
                                      '${AppRoutes.DOCUMENTS}?folderId=${folder.id}',
                                    ),
                                    child: const Text('Open Folder', style: TextStyle(fontSize: 12)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                    tooltip: 'Delete Folder',
                                    onPressed: () => controller.deleteFolder(folder),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}
