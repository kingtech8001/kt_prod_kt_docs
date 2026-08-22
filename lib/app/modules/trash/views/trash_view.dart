import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/trash/controllers/trash_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class TrashView extends GetView<TrashController> {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Trash Bin',
      subtitle: 'Soft-deleted documents. Restore them back or permanently delete.',
      currentRoute: AppRoutes.TRASH,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.trashDocuments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline, size: 56, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text(
                  'Trash bin is empty',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Deleted documents will appear here with the option to restore.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxis = 3;
            if (width < 750) {
              crossAxis = 1;
            } else if (width < 1150) {
              crossAxis = 2;
            }

            return GridView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: controller.trashDocuments.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxis,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 240,
              ),
              itemBuilder: (context, index) {
                final doc = controller.trashDocuments[index];
                return DocumentCard(
                  document: doc,
                  isTrash: true,
                  onRestore: () => controller.restoreDocument(doc),
                  onDelete: () => controller.confirmPermanentDelete(doc),
                );
              },
            );
          },
        );
      }),
    );
  }
}
