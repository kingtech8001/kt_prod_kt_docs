import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/documents/controllers/documents_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/city_filter_chips.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

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
            // Top Controls Bar (City Chips + Category Selector + View Mode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City Filter Chips
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 600;
                      if (isCompact) {
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

                  // Category Dropdown + Status Filter + View Mode Switcher
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
                          borderRadius: BorderRadius.circular(8),
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
                          borderRadius: BorderRadius.circular(8),
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
                          borderRadius: BorderRadius.circular(8),
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
                                  controller.toggleViewMode();
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
                                  controller.toggleViewMode();
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

            // Content Area
            Expanded(
              child: controller.isLoading.value
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
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
          ),
          const SizedBox(height: 16),
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
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxis = 4;
        if (width < 650) {
          crossAxis = 1;
        } else if (width < 950) {
          crossAxis = 2;
        } else if (width < 1300) {
          crossAxis = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.documents.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: controller.documents.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final doc = controller.documents[index];
        return RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: doc.isPdf
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
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
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doc.subCategory} • ${doc.city} • ${AppFormatters.formatFileSize(doc.fileSize)} • ${AppFormatters.formatDate(doc.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  onPressed: () => controller.toggleFavorite(doc),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  onPressed: () => controller.previewDocument(doc),
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined, size: 20),
                  onPressed: () => controller.downloadDocument(doc),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
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
                  onPressed: () => controller.confirmMoveToTrash(doc),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
