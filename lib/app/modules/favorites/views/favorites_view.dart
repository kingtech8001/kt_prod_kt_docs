import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/favorites/controllers/favorites_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
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
          return const FavoritesSkeletonView();
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadFavorites(resetPage: true),
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Toolbar Section: Search Box, Category Chips, and Count
              SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Search Box
                          _buildSearchBox(),

                          // Category Filter Chips
                          _buildCategoryChips(),

                          // Results Count
                          Text(
                            '${controller.totalCount.value} starred ${controller.totalCount.value == 1 ? "document" : "documents"}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Favorite Documents Grid or Empty State
              if (controller.favoriteDocuments.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 240,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = controller.favoriteDocuments[index];
                        return DocumentCard(
                          document: doc,
                          onPreview: () =>
                              controller.previewDocument(doc),
                          onDownload: () =>
                              controller.downloadDocument(doc),
                          onShare: () => controller.shareDocument(doc),
                          onToggleFavorite: () =>
                              controller.toggleFavorite(doc),
                          onEdit: controller.canEdit
                              ? () =>
                                  controller.openEditDocumentDialog(doc)
                              : null,
                          onDelete: controller.canDelete
                              ? () =>
                                  controller.confirmMoveToTrash(doc)
                              : null,
                        );
                      },
                      childCount: controller.favoriteDocuments.length,
                    ),
                  ),
                ),

              // 3. Infinite Scroll Pagination Loader / End of list indicator
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.isLoadingMore.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: BottomShimmerLoader(),
                    );
                  }
                  if (!controller.hasMore.value &&
                      controller.favoriteDocuments.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Showing all ${controller.favoriteDocuments.length} of ${controller.totalCount.value} starred records',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 24);
                }),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      width: 240,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'Search starred documents...',
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          prefixIcon:
              const Icon(Icons.search, size: 16, color: AppColors.textMuted),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 24, minHeight: 24),
          suffixIcon: controller.searchQuery.value.isNotEmpty
              ? InkWell(
                  onTap: controller.clearSearch,
                  child: const Icon(Icons.close,
                      size: 14, color: AppColors.textMuted),
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 20, minHeight: 20),
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: controller.onSearchChanged,
      ),
    );
  }

  Widget _buildCategoryChips() {
    final isAllSelected = controller.selectedCategoryCode.value == 'all';

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildChip(
          label: 'All Categories',
          isSelected: isAllSelected,
          onTap: () => controller.onCategorySelected('all'),
        ),
        ...controller.categories.map((cat) {
          final isSelected = controller.selectedCategoryCode.value == cat.code;
          return _buildChip(
            label: cat.name,
            isSelected: isSelected,
            onTap: () => controller.onCategorySelected(cat.code),
          );
        }),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_border_outlined,
              size: 56,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            const Text(
              'No starred documents found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.searchQuery.value.isNotEmpty ||
                      controller.selectedCategoryCode.value != 'all'
                  ? 'No favorites match your active filters. Try clearing your search or filter.'
                  : 'Click the star icon on any document across your vault to pin it here.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (controller.searchQuery.value.isNotEmpty ||
                controller.selectedCategoryCode.value != 'all') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  controller.clearSearch();
                  controller.onCategorySelected('all');
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
