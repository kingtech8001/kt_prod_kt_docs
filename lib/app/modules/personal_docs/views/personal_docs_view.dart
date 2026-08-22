import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/modules/personal_docs/controllers/personal_docs_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/metric_card.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class PersonalDocsView extends GetView<PersonalDocsController> {
  const PersonalDocsView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Personal & Identity Documents Vault',
      subtitle: 'Securely manage Aadhaar, PAN, Voter IDs, Passports, and credentials grouped by individual',
      currentRoute: AppRoutes.PERSONAL_DOCS,
      headerActions: [
        ElevatedButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: const Text('Upload Personal Doc'),
        ),
      ],
      body: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Filter & Metrics Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Person Filter Chips
                  LayoutBuilder(builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 600;
                    final personList = ['All Persons', ...controller.dynamicPersons];

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FILTER BY PERSON / BENEFICIARY:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: personList.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) => _buildPersonChip(personList[index]),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        const Text(
                          'FILTER BY PERSON:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: personList.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) => _buildPersonChip(personList[index]),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  // Metrics Row (Responsive 1/2/4 Columns)
                  LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxis = 4;
                    if (width < 600) {
                      crossAxis = 1;
                    } else if (width < 950) {
                      crossAxis = 2;
                    }

                    final items = [
                      MetricCard(
                        title: 'TOTAL PERSONAL DOCS',
                        value: '${controller.totalDocumentsCount.value}',
                        icon: Icons.badge_outlined,
                        accentColor: AppColors.primary,
                      ),
                      MetricCard(
                        title: 'PERSONS COVERED',
                        value: '${controller.totalPersonsCoveredCount.value}',
                        icon: Icons.people_outline,
                        accentColor: AppColors.financeBlue,
                      ),
                      MetricCard(
                        title: 'EXPIRING SOON (<60D)',
                        value: '${controller.expiringSoonCount.value}',
                        icon: Icons.timelapse_outlined,
                        accentColor: AppColors.warning,
                      ),
                      MetricCard(
                        title: 'EXPIRED RECORDS',
                        value: '${controller.expiredCount.value}',
                        icon: Icons.error_outline_rounded,
                        accentColor: AppColors.error,
                      ),
                    ];

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxis,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 110,
                      ),
                      itemBuilder: (context, index) => items[index],
                    );
                  }),
                ],
              ),
            ),

            // Secondary Filter Bar (Doc Type Dropdown + Search + View Mode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.background,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Document Type Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedDocType.value,
                        items: [
                          const DropdownMenuItem(
                            value: 'All Document Types',
                            child: Text('All Document Types', style: TextStyle(fontSize: 13)),
                          ),
                          ...controller.dynamicDocTypes.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type, style: const TextStyle(fontSize: 13)),
                              )),
                        ],
                        onChanged: (val) {
                          if (val != null) controller.onDocTypeSelected(val);
                        },
                      ),
                    ),
                  ),

                  // Search Box
                  Container(
                    width: 240,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search Aadhaar, PAN, Person...',
                        hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        icon: Icon(Icons.search, size: 16, color: AppColors.textMuted),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: controller.onSearchChanged,
                    ),
                  ),

                  // Grid / List Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
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
                            color: controller.isGridView.value ? AppColors.primary : AppColors.textMuted,
                          ),
                          onPressed: () => controller.toggleViewMode(true),
                          tooltip: 'Grid View',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.view_list_rounded,
                            size: 18,
                            color: !controller.isGridView.value ? AppColors.primary : AppColors.textMuted,
                          ),
                          onPressed: () => controller.toggleViewMode(false),
                          tooltip: 'List View',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : controller.personalDocuments.isEmpty
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

  Widget _buildPersonChip(String person) {
    final isSelected = controller.selectedPerson.value.toLowerCase() == person.toLowerCase();

    return InkWell(
      onTap: () => controller.onPersonSelected(person),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            person,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.badge_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No Personal Documents Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload Aadhaar Cards, PAN Cards, Passports, or Voter IDs for individuals in your organization.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.UPLOAD),
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Upload Document Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxis = 3;
        if (width < 650) {
          crossAxis = 1;
        } else if (width < 1050) {
          crossAxis = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: controller.personalDocuments.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) {
            final doc = controller.personalDocuments[index];
            return _buildPersonalDocCard(doc);
          },
        );
      },
    );
  }

  Widget _buildPersonalDocCard(DocumentModel doc) {
    final meta = doc.personalMetadata;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Person Badge + Star
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    doc.isPdf ? Icons.picture_as_pdf : Icons.badge_outlined,
                    color: doc.isPdf ? AppColors.error : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta?.personName ?? 'General',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        meta?.docTypeName ?? doc.subCategory,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    doc.isFavorite ? Icons.star : Icons.star_border,
                    color: doc.isFavorite ? AppColors.starFilled : AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => controller.toggleFavorite(doc),
                  tooltip: 'Favorite',
                ),
              ],
            ),
          ),

          // Body: ID Number & Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (meta?.idNumber != null && meta!.idNumber!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'ID: ${meta.idNumber!}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Dates & Status Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (meta?.expiryDate != null)
                        StatusBadge(
                          label: meta!.isExpired
                              ? 'EXPIRED (${AppFormatters.formatDate(meta.expiryDate!)})'
                              : 'Expires: ${AppFormatters.formatDate(meta.expiryDate!)}',
                          type: meta.isExpired
                              ? StatusBadgeType.error
                              : meta.isExpiringSoon
                                  ? StatusBadgeType.warning
                                  : StatusBadgeType.success,
                        )
                      else
                        Text(
                          'Size: ${AppFormatters.formatFileSize(doc.fileSize)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () => controller.previewDocument(doc),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View', style: TextStyle(fontSize: 11)),
                ),
                TextButton.icon(
                  onPressed: () => controller.downloadDocument(doc),
                  icon: const Icon(Icons.download_outlined, size: 14),
                  label: const Text('Download', style: TextStyle(fontSize: 11)),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 16),
                  onPressed: () => controller.shareDocument(doc),
                  tooltip: 'Share Link',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  onPressed: () => controller.moveToTrash(doc),
                  tooltip: 'Move to Trash',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: controller.personalDocuments.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final doc = controller.personalDocuments[index];
        final meta = doc.personalMetadata;

        return Container(
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
                  color: doc.isPdf ? AppColors.error.withValues(alpha: 0.1) : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  doc.isPdf ? Icons.picture_as_pdf : Icons.badge_outlined,
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${meta?.personName ?? "Unknown"} • ${meta?.docTypeName ?? doc.subCategory}${meta?.idNumber != null ? " • ID: ${meta!.idNumber}" : ""} • ${AppFormatters.formatFileSize(doc.fileSize)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (meta?.expiryDate != null)
                StatusBadge(
                  label: meta!.isExpired ? 'EXPIRED' : 'Exp: ${AppFormatters.formatDate(meta.expiryDate!)}',
                  type: meta.isExpired
                      ? StatusBadgeType.error
                      : meta.isExpiringSoon
                          ? StatusBadgeType.warning
                          : StatusBadgeType.success,
                )
              else
                StatusBadge(
                  label: meta?.docTypeName ?? doc.subCategory,
                  type: StatusBadgeType.info,
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  doc.isFavorite ? Icons.star : Icons.star_border,
                  color: doc.isFavorite ? AppColors.starFilled : AppColors.textMuted,
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
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: () => controller.moveToTrash(doc),
              ),
            ],
          ),
        );
      },
    );
  }
}
