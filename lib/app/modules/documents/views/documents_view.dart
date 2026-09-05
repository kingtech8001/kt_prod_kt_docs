import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/modules/documents/controllers/documents_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/city_filter_chips.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class DocumentsView extends GetView<DocumentsController> {
  const DocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Document Explorer',
      subtitle:
          'Browse, filter by city or category, preview, and download documents',
      currentRoute: AppRoutes.DOCUMENTS,
      onSearch: controller.onSearchChanged,
      searchHint: 'Search title, invoice, serial no, or file name...',
      body: Obx(() {
        return Column(
          children: [
            // 1. Top Filter Controls Bar (City Chips + Dropdowns + View Mode Switcher)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
                vertical: 14,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City Filter Chips (Responsive Layout)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile =
                          constraints.maxWidth < AppConstants.tabletBreakpoint;

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FILTER BY CITY:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CityFilterChips(
                              selectedCity: controller.selectedCity.value,
                              onCitySelected: controller.onCitySelected,
                              customCities: controller.dynamicCities.isNotEmpty
                                  ? controller.dynamicCities
                                  : null,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          const Text(
                            'FILTER BY CITY:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CityFilterChips(
                              selectedCity: controller.selectedCity.value,
                              onCitySelected: controller.onCitySelected,
                              customCities: controller.dynamicCities.isNotEmpty
                                  ? controller.dynamicCities
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Category Dropdown + Status Filter + Results Counter + View Mode
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Category Filter Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSmall),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: controller.selectedCategoryId.value.isEmpty
                                ? null
                                : controller.selectedCategoryId.value,
                            hint: const Text(
                              'All Categories',
                              style: TextStyle(fontSize: 13),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'All Categories',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              ...controller.categories.map(
                                (cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: controller.onCategorySelected,
                          ),
                        ),
                      ),

                      // Status Filter Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSmall),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: controller.selectedStatus.value,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(
                                  'All Statuses',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'active',
                                child: Text(
                                  'Active Only',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'archived',
                                child: Text(
                                  'Archived',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedStatus.value = val;
                                controller.fetchFilteredDocuments();
                              }
                            },
                          ),
                        ),
                      ),

                      // Active Folder Filter Chip
                      if (controller.selectedFolderId.value.isNotEmpty)
                        InputChip(
                          label: const Text(
                            'Folder Filter Active',
                            style: TextStyle(fontSize: 12),
                          ),
                          avatar: const Icon(
                            Icons.folder,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          onDeleted: () {
                            controller.selectedFolderId.value = '';
                            controller.fetchFilteredDocuments();
                          },
                          deleteIconColor: AppColors.textSecondary,
                        ),

                      // Results Count
                      Text(
                        '${controller.documents.length} documents',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      // View Mode Switcher
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSmall),
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
                                    : AppColors.textMuted,
                              ),
                              onPressed: () {
                                if (!controller.isGridView.value) {
                                  controller.toggleViewMode(true);
                                }
                              },
                              tooltip: 'Grid View',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.view_list_rounded,
                                size: 18,
                                color: !controller.isGridView.value
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                              onPressed: () {
                                if (controller.isGridView.value) {
                                  controller.toggleViewMode(false);
                                }
                              },
                              tooltip: 'List View',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Main Content Area (Shimmer Loading vs Content)
            Expanded(
              child: controller.isLoading.value
                  ? (controller.isGridView.value
                      ? const ExploreGridSkeleton()
                      : const ExploreListSkeleton())
                  : controller.documents.isEmpty
                      ? _buildEmptyState()
                      : controller.isGridView.value
                          ? _buildGridView()
                          : _buildListView(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No documents match your filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try clearing your search query or selecting a different city or category.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            ElevatedButton.icon(
              onPressed: () {
                controller.selectedCity.value = 'All Cities';
                controller.selectedCategoryId.value = '';
                controller.selectedStatus.value = 'all';
                controller.searchQuery.value = '';
                controller.fetchFilteredDocuments();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
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

        return GridView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          itemCount: controller.documents.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            crossAxisSpacing: AppConstants.paddingMedium,
            mainAxisSpacing: AppConstants.paddingMedium,
            mainAxisExtent: 240,
          ),
          itemBuilder: (context, index) {
            final doc = controller.documents[index];
            return DocumentCard(
              document: doc,
              onPreview: () => controller.previewDocument(doc),
              onDownload: () => controller.downloadDocument(doc),
              onShare: () => controller.shareDocument(doc),
              onToggleFavorite: () => controller.toggleFavorite(doc),
              onEdit: () => controller.openEditDocumentDialog(doc),
              onDelete: () => controller.confirmMoveToTrash(doc),
            );
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;

        return ListView.separated(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          itemCount: controller.documents.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = controller.documents[index];
            return isMobile
                ? _buildMobileListItem(doc)
                : _buildDesktopListItem(doc);
          },
        );
      },
    );
  }

  /// Mobile-optimized responsive card for list view with zero overflow hazards.
  Widget _buildMobileListItem(DocumentModel doc) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: doc.isPdf
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Icon(
                  doc.isPdf ? Icons.picture_as_pdf : Icons.image,
                  color: doc.isPdf ? AppColors.error : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.subCategory} • ${doc.city}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormatters.formatFileSize(doc.fileSize)} • ${AppFormatters.formatDate(doc.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: doc.categoryName ?? doc.subCategory,
                type: StatusBadgeType.info,
              ),
            ],
          ),
          const Divider(height: 20),
          // Mobile Action Buttons Bar (Wrap to prevent horizontal overflow)
          Wrap(
            spacing: AppConstants.paddingSmall,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  doc.isFavorite ? Icons.star : Icons.star_border,
                  color: doc.isFavorite
                      ? AppColors.starFilled
                      : AppColors.textMuted,
                  size: 20,
                ),
                tooltip: 'Favorite',
                onPressed: () => controller.toggleFavorite(doc),
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                tooltip: 'Preview',
                onPressed: () => controller.previewDocument(doc),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 20),
                tooltip: 'Download',
                onPressed: () => controller.downloadDocument(doc),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                tooltip: 'Share',
                onPressed: () => controller.shareDocument(doc),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit details',
                onPressed: () => controller.openEditDocumentDialog(doc),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.error,
                ),
                tooltip: 'Delete',
                onPressed: () => controller.confirmMoveToTrash(doc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Desktop/Tablet list row with full inline actions.
  Widget _buildDesktopListItem(DocumentModel doc) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: doc.isPdf
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Icon(
              doc.isPdf ? Icons.picture_as_pdf : Icons.image,
              color: doc.isPdf ? AppColors.error : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${doc.subCategory} • ${doc.city} • ${AppFormatters.formatFileSize(doc.fileSize)} • ${AppFormatters.formatDate(doc.createdAt)}',
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
          const SizedBox(width: 8),
          StatusBadge(
            label: doc.categoryName ?? doc.subCategory,
            type: StatusBadgeType.info,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              doc.isFavorite ? Icons.star : Icons.star_border,
              color: doc.isFavorite
                  ? AppColors.starFilled
                  : AppColors.textMuted,
              size: 20,
            ),
            tooltip: 'Favorite',
            onPressed: () => controller.toggleFavorite(doc),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20),
            tooltip: 'Preview',
            onPressed: () => controller.previewDocument(doc),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 20),
            tooltip: 'Download',
            onPressed: () => controller.downloadDocument(doc),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share',
            onPressed: () => controller.shareDocument(doc),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit details',
            onPressed: () => controller.openEditDocumentDialog(doc),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.error,
            ),
            tooltip: 'Delete',
            onPressed: () => controller.confirmMoveToTrash(doc),
          ),
        ],
      ),
    );
  }
}
