import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/trash/controllers/trash_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class TrashView extends GetView<TrashController> {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Trash Bin',
      subtitle:
          'Soft-deleted documents. Restore them back or permanently purge.',
      currentRoute: AppRoutes.TRASH,
      body: Column(
        children: [
          // 1. Toolbar Filter / Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingLarge,
              AppConstants.paddingLarge,
              AppConstants.paddingLarge,
              AppConstants.paddingSmall,
            ),
            child: _buildToolbar(context),
          ),

          // 2. Main Content (Shimmer / Empty / Paginated Grid)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const TrashGridSkeleton();
              }

              if (controller.trashDocuments.isEmpty) {
                return _buildEmptyState();
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxis = 4;
                  if (width < AppConstants.tabletBreakpoint) {
                    crossAxis = 1;
                  } else if (width < AppConstants.desktopBreakpoint) {
                    crossAxis = 2;
                  } else if (width < 1400) {
                    crossAxis = 3;
                  }

                  return CustomScrollView(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxis,
                            crossAxisSpacing: AppConstants.paddingMedium,
                            mainAxisSpacing: AppConstants.paddingMedium,
                            mainAxisExtent: 240,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = controller.trashDocuments[index];
                              return DocumentCard(
                                document: doc,
                                isTrash: true,
                                onRestore: () =>
                                    controller.restoreDocument(doc),
                                onDelete: () =>
                                    controller.confirmPermanentDelete(doc),
                              );
                            },
                            childCount: controller.trashDocuments.length,
                          ),
                        ),
                      ),
                      // Infinite scroll bottom loader / end indicator
                      SliverToBoxAdapter(
                        child: Obx(() {
                          if (controller.isLoadingMore.value) {
                            return const BottomShimmerLoader();
                          }
                          if (!controller.hasMore.value &&
                              controller.trashDocuments.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppConstants.paddingLarge,
                              ),
                              child: Center(
                                child: Text(
                                  'All ${controller.totalCount.value} items in trash loaded',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;

          final searchField = TextField(
            controller: controller.searchController,
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search trash by title, document #, file name...',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink()),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: 12,
              ),
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          );

          final statusAndActions = Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment:
                isMobile ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
            children: [
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.delete_sweep_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Text(
                          '${controller.totalCount.value} ${controller.totalCount.value == 1 ? "document" : "documents"}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(width: AppConstants.paddingSmall),
              Tooltip(
                message: 'Refresh Trash',
                child: InkWell(
                  onTap: () => controller.loadTrashDocuments(isRefresh: true),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusSmall),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: AppConstants.paddingMedium),
                statusAndActions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: AppConstants.paddingMedium),
              statusAndActions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Obx(() {
              final query = controller.searchQuery.value;
              final hasQuery = query.isNotEmpty;
              return Column(
                children: [
                  Text(
                    hasQuery ? 'No matching documents' : 'Trash bin is empty',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    hasQuery
                        ? 'No deleted documents match "$query".'
                        : 'Soft-deleted documents will appear here with the option to restore.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (hasQuery) ...[
                    const SizedBox(height: AppConstants.paddingLarge),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSmall),
                        ),
                      ),
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      label: const Text('Clear Search Filter'),
                      onPressed: controller.clearSearch,
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

