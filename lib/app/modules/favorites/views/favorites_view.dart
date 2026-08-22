import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/favorites/controllers/favorites_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Starred & Favorite Documents',
      subtitle: 'Quick access to your pinned receipts, bills, and contracts',
      currentRoute: AppRoutes.FAVORITES,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.favoriteDocuments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_border_outlined, size: 56, color: AppColors.warning),
                const SizedBox(height: 16),
                const Text(
                  'No starred documents yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Click the star icon on any document card to add it to your favorites list.',
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
              itemCount: controller.favoriteDocuments.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxis,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 240,
              ),
              itemBuilder: (context, index) {
                final doc = controller.favoriteDocuments[index];
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
        );
      }),
    );
  }
}
