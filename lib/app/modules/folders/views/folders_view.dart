import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/folder_model.dart';
import 'package:kt_prod_kt_docs/app/modules/folders/controllers/folders_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class FoldersView extends GetView<FoldersController> {
  const FoldersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeFolder = controller.selectedFolder.value;

      return WebScaffold(
        title: activeFolder == null ? 'Folder Explorer' : activeFolder.name,
        subtitle: activeFolder == null
            ? 'Organize documents into departmental and project collections'
            : 'Viewing documents inside folder collection',
        currentRoute: AppRoutes.FOLDERS,
        headerActions: [
          if (activeFolder == null) ...[
            ElevatedButton.icon(
              onPressed: controller.openCreateFolderDialog,
              icon: const Icon(Icons.create_new_folder_outlined, size: 16),
              label: const Text('New Folder'),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
          ] else ...[
            OutlinedButton.icon(
              onPressed: controller.clearSelectedFolder,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Folders'),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            ElevatedButton.icon(
              onPressed: controller.openAddDocumentsDialog,
              icon: const Icon(Icons.note_add_outlined, size: 16),
              label: const Text('Add Files'),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
          ],
        ],
        body: Obx(() {
          // Strict Rule: Shimmer loader mirroring layout geometry during loading. Zero bare spinners.
          if (controller.isLoading.value) {
            return const FoldersSkeletonView();
          }

          if (activeFolder != null) {
            return _buildFolderDetailView(activeFolder);
          }

          return _buildFoldersGridView();
        }),
      );
    });
  }

  // ================= VIEW A: ALL FOLDERS GRID =================
  Widget _buildFoldersGridView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Metrics Strip (Responsive 2 cols or 1 col on mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;

              final card1 = MetricCard(
                title: 'TOTAL FOLDERS',
                value: '${controller.folders.length}',
                subtitle: 'Configured folder collections',
                icon: Icons.folder_outlined,
                accentColor: AppColors.primary,
              );
              final card2 = MetricCard(
                title: 'ORGANIZED DOCUMENTS',
                value: '${controller.totalOrganizedDocsCount}',
                subtitle: 'Documents categorized in folders',
                icon: Icons.inventory_2_outlined,
                accentColor: AppColors.financeBlue,
              );

              if (isMobile) {
                return Column(
                  children: [
                    card1,
                    const SizedBox(height: AppConstants.paddingSmall + 4),
                    card2,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(child: card2),
                ],
              );
            },
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // 2. Toolbar: Search Filter & Actions (Wrap ensures zero overflow on mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;

              return Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppConstants.paddingMedium,
                  runSpacing: AppConstants.paddingSmall + 4,
                  children: [
                    SizedBox(
                      width: isMobile ? constraints.maxWidth : 320,
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: (val) => controller.folderSearchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Search folders by name...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: Obx(() {
                            if (controller.folderSearchQuery.value.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                controller.searchController.clear();
                                controller.folderSearchQuery.value = '';
                              },
                            );
                          }),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.openCreateFolderDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Folder'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // 3. Folder Cards Grid or Empty State
          Obx(() {
            final list = controller.filteredFolders;

            if (list.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingHero * 1.5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_open_outlined, size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      controller.folderSearchQuery.value.isNotEmpty
                          ? 'No folders matching "${controller.folderSearchQuery.value}"'
                          : 'No folders created yet',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Group documents into structured collections like Legal, Invoices, HR, or Premises.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
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
                if (width < AppConstants.tabletBreakpoint) {
                  crossAxis = 1;
                } else if (width < 1100) {
                  crossAxis = 2;
                } else if (width < 1400) {
                  crossAxis = 3;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    crossAxisSpacing: AppConstants.paddingMedium,
                    mainAxisSpacing: AppConstants.paddingMedium,
                    mainAxisExtent: 160,
                  ),
                  itemBuilder: (context, index) {
                    final folder = list[index];
                    return _buildFolderCard(folder);
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }

  // Helper: Single Folder Card
  Widget _buildFolderCard(FolderModel folder) {
    Color folderColor;
    try {
      folderColor = Color(int.parse(folder.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      folderColor = AppColors.primary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.selectFolder(folder),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        hoverColor: AppColors.primarySurface.withValues(alpha: 0.5),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: folderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall + 2),
                    ),
                    child: Icon(Icons.folder, color: folderColor, size: 24),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${folder.documentCount} ${folder.documentCount == 1 ? "document" : "documents"}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    onSelected: (action) {
                      if (action == 'open') {
                        controller.selectFolder(folder);
                      } else if (action == 'edit') {
                        controller.openEditFolderDialog(folder);
                      } else if (action == 'delete') {
                        controller.confirmDeleteFolder(folder);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.folder_open, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Open Folder', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text('Edit / Color', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete Folder', style: TextStyle(fontSize: 13, color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${AppFormatters.formatDate(folder.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  TextButton.icon(
                    onPressed: () => controller.selectFolder(folder),
                    icon: const Icon(Icons.arrow_forward, size: 13),
                    label: const Text('Open', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= VIEW B: INSIDE FOLDER DRILL-DOWN =================
  Widget _buildFolderDetailView(FolderModel folder) {
    Color folderColor;
    try {
      folderColor = Color(int.parse(folder.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      folderColor = AppColors.primary;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Breadcrumb Bar
          Row(
            children: [
              InkWell(
                onTap: controller.clearSelectedFolder,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'All Folders',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  folder.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // 2. Folder Info Header Card
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < AppConstants.tabletBreakpoint;

                final folderIdentity = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: folderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall + 2),
                      ),
                      child: Icon(Icons.folder, color: folderColor, size: 30),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  folder.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Obx(() => Text(
                                      '${controller.folderDocuments.length} files',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    )),
                              ),
                            ],
                          ),
                          if (folder.description != null && folder.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              folder.description!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );

                final actionButtons = Wrap(
                  spacing: AppConstants.paddingSmall,
                  runSpacing: AppConstants.paddingSmall,
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.openAddDocumentsDialog,
                      icon: const Icon(Icons.note_add_outlined, size: 16),
                      label: const Text('Add Existing Files'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.navigateToUpload,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: const Text('Upload Here'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                      tooltip: 'Edit Folder',
                      onPressed: () => controller.openEditFolderDialog(folder),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      tooltip: 'Delete Folder',
                      onPressed: () => controller.confirmDeleteFolder(folder),
                    ),
                  ],
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      folderIdentity,
                      const SizedBox(height: AppConstants.paddingMedium),
                      actionButtons,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: folderIdentity),
                    const SizedBox(width: AppConstants.paddingLarge),
                    actionButtons,
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // 3. Search Bar for Folder Documents
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller.docSearchController,
              onChanged: (val) => controller.folderDocSearchQuery.value = val,
              decoration: InputDecoration(
                hintText: 'Search files inside "${folder.name}"...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: Obx(() {
                  if (controller.folderDocSearchQuery.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      controller.docSearchController.clear();
                      controller.folderDocSearchQuery.value = '';
                    },
                  );
                }),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall,
                ),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // 4. Documents Grid or Empty State
          Obx(() {
            if (controller.isFolderDocsLoading.value) {
              return const DashboardRecentDocumentsSkeleton();
            }

            final docs = controller.filteredFolderDocuments;

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingHero * 1.5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      controller.folderDocSearchQuery.value.isNotEmpty
                          ? 'No files matching "${controller.folderDocSearchQuery.value}"'
                          : 'This folder is currently empty',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Assign existing files from your vault or upload new documents directly into this folder.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    Wrap(
                      spacing: AppConstants.paddingSmall,
                      runSpacing: AppConstants.paddingSmall,
                      children: [
                        ElevatedButton.icon(
                          onPressed: controller.openAddDocumentsDialog,
                          icon: const Icon(Icons.note_add_outlined, size: 16),
                          label: const Text('Add Existing Files'),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.navigateToUpload,
                          icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: const Text('Upload New File'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
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
                  itemCount: docs.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    crossAxisSpacing: AppConstants.paddingMedium,
                    mainAxisSpacing: AppConstants.paddingMedium,
                    mainAxisExtent: 250,
                  ),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return Stack(
                      children: [
                        DocumentCard(
                          document: doc,
                          onPreview: () => controller.previewDocument(doc),
                          onDownload: () => controller.downloadDocument(doc),
                          onToggleFavorite: () => controller.toggleFavorite(doc),
                          onDelete: () => controller.confirmMoveToTrash(doc),
                        ),
                        // Quick "Remove from folder" action chip
                        Positioned(
                          top: 8,
                          left: 8,
                          child: InkWell(
                            onTap: () => controller.removeDocumentFromFolder(doc),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_off_outlined, size: 12, color: AppColors.textSecondary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Unlink',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
