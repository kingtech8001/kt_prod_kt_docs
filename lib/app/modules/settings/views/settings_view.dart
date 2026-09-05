import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/settings/controllers/settings_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Settings & Master Data Configuration View.
/// Strictly conforms to AI Master Context: 3-tier MVC, responsive, zero bare spinners, AppColors/AppConstants tokens.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController tabScrollController = ScrollController();

    return WebScaffold(
      title: 'Settings & Master Configuration',
      subtitle:
          'Manage dynamic cities, brands, appliance types, utility authorities, persons, doc types, and corporate categories',
      currentRoute: AppRoutes.SETTINGS,
      body: Obx(() {
        // Section 5: Strict Shimmer Skeleton Loader - Zero bare spinners
        if (controller.isLoading.value) {
          return const SettingsSkeletonView();
        }

        final selectedTab = controller.selectedTabIndex.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Scrollable Tab Navigation Bar
                  _buildTabNavigationBar(tabScrollController),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // 2. Tab Content Section
                  if (selectedTab == 0) _buildCitiesTab(context),
                  if (selectedTab == 1) _buildBrandsTab(context),
                  if (selectedTab == 2) _buildApplianceCategoriesTab(context),
                  if (selectedTab == 3) _buildUtilityProvidersTab(context),
                  if (selectedTab == 4) _buildPersonsTab(context),
                  if (selectedTab == 5) _buildPersonalDocTypesTab(context),
                  if (selectedTab == 6) _buildDocCategoriesTab(context),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ================= TAB NAVIGATION BAR =================
  Widget _buildTabNavigationBar(ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20, color: AppColors.textSecondary),
            tooltip: 'Scroll Left',
            splashRadius: 20,
            onPressed: () {
              scrollController.animateTo(
                scrollController.offset - 220,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  _buildTabButton(0, 'Cities & Locations', Icons.location_city),
                  const SizedBox(width: 8),
                  _buildTabButton(1, 'Appliance Brands', Icons.branding_watermark_outlined),
                  const SizedBox(width: 8),
                  _buildTabButton(2, 'Appliance Categories', Icons.kitchen_outlined),
                  const SizedBox(width: 8),
                  _buildTabButton(3, 'Utility Providers', Icons.bolt_outlined),
                  const SizedBox(width: 8),
                  _buildTabButton(4, 'Persons & Members', Icons.people_alt_outlined),
                  const SizedBox(width: 8),
                  _buildTabButton(5, 'Personal Doc Types', Icons.badge_outlined),
                  const SizedBox(width: 8),
                  _buildTabButton(6, 'Document Categories', Icons.folder_outlined),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
            tooltip: 'Scroll Right',
            splashRadius: 20,
            onPressed: () {
              scrollController.animateTo(
                scrollController.offset + 220,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    return Obx(() {
      final isSelected = controller.selectedTabIndex.value == index;

      return InkWell(
        onTap: () => controller.switchTab(index),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ================= TAB 0: CITIES & LOCATIONS =================
  Widget _buildCitiesTab(BuildContext context) {
    return Obx(() {
      final list = controller.filteredCities;
      return _buildConfigSection(
        context: context,
        title: 'Master Cities & Premises Locations',
        subtitle:
            'Define operational cities where King Technology operates. Used for document categorization and utility premises.',
        onAdd: controller.openAddCityDialog,
        addButtonText: 'Add New City',
        isLoading: controller.isCitiesLoading.value,
        itemCount: list.length,
        itemBuilder: (ctx, index) {
          final city = list[index];
          return _buildItemTile(
            leadingIcon: Icons.location_city,
            title: city.name,
            subtitle: 'State: ${city.state}',
            isActive: city.isActive,
            onToggle: () => controller.toggleCityActive(city),
            onDelete: () => controller.confirmDeleteCity(city),
          );
        },
      );
    });
  }

  // ================= TAB 1: APPLIANCE BRANDS =================
  Widget _buildBrandsTab(BuildContext context) {
    return Obx(() {
      final list = controller.filteredBrands;
      return _buildConfigSection(
        context: context,
        title: 'Master Appliance & Electronics Brands',
        subtitle:
            'Manage official brand list for warranty tracking, product classification, and invoice search.',
        onAdd: controller.openAddBrandDialog,
        addButtonText: 'Add New Brand',
        isLoading: controller.isBrandsLoading.value,
        itemCount: list.length,
        itemBuilder: (ctx, index) {
          final brand = list[index];
          return _buildItemTile(
            leadingIcon: Icons.branding_watermark_outlined,
            title: brand.name,
            subtitle: 'Category: ${brand.categoryType.toUpperCase()}',
            isActive: brand.isActive,
            onToggle: () => controller.toggleBrandActive(brand),
            onDelete: () => controller.confirmDeleteBrand(brand),
          );
        },
      );
    });
  }

  // ================= TAB 2: APPLIANCE CATEGORIES =================
  Widget _buildApplianceCategoriesTab(BuildContext context) {
    return Obx(() {
      final list = controller.filteredApplianceSubcategories;
      return _buildConfigSection(
        context: context,
        title: 'Appliance Types & Subcategories',
        subtitle:
            'Configure categories of appliances and electronics with default standard warranty periods.',
        onAdd: controller.openAddApplianceSubcategoryDialog,
        addButtonText: 'Add Appliance Type',
        isLoading: controller.isApplianceSubcategoriesLoading.value,
        itemCount: list.length,
        itemBuilder: (ctx, index) {
          final sub = list[index];
          return _buildItemTile(
            leadingIcon: Icons.kitchen_outlined,
            title: sub.name,
            subtitle: 'Standard Warranty: ${sub.defaultWarrantyMonths} Months',
            isActive: sub.isActive,
            onToggle: () => controller.toggleApplianceSubcategoryActive(sub),
            onDelete: () => controller.confirmDeleteApplianceSubcategory(sub),
          );
        },
      );
    });
  }

  // ================= TAB 3: UTILITY PROVIDERS =================
  Widget _buildUtilityProvidersTab(BuildContext context) {
    return Obx(() {
      final list = controller.filteredUtilityProviders;
      return _buildConfigSection(
        context: context,
        title: 'Master Utility Providers & Authorities',
        subtitle:
            'Manage electricity boards, piped gas distributors, municipal water corporations, and broadband ISPs.',
        onAdd: controller.openAddUtilityProviderDialog,
        addButtonText: 'Add Utility Provider',
        isLoading: controller.isUtilityProvidersLoading.value,
        itemCount: list.length,
        itemBuilder: (ctx, index) {
          final prov = list[index];
          return _buildItemTile(
            leadingIcon: Icons.bolt_outlined,
            title: prov.name,
            subtitle: 'Utility Type: ${prov.utilityType}',
            isActive: prov.isActive,
            onToggle: () => controller.toggleUtilityProviderActive(prov),
            onDelete: () => controller.confirmDeleteUtilityProvider(prov),
          );
        },
      );
    });
  }

  // ================= TAB 4: PERSONS & BENEFICIARIES =================
  Widget _buildPersonsTab(BuildContext context) {
    return Obx(() {
      final list = controller.filteredPersons;
      return _buildConfigSection(
        context: context,
        title: 'Persons & Family Members',
        subtitle:
            'Manage individuals for grouping and filtering personal identity documents (Aadhaar, PAN, Passport, etc.).',
        onAdd: controller.openAddPersonDialog,
        addButtonText: 'Add Person / Member',
        isLoading: controller.isPersonsLoading.value,
        itemCount: list.length,
        itemBuilder: (ctx, index) {
          final person = list[index];
          final details = [
            'Relationship: ${person.relationship}',
            if (person.phoneNumber != null && person.phoneNumber!.isNotEmpty)
              'Phone: ${person.phoneNumber}',
            if (person.email != null && person.email!.isNotEmpty)
              'Email: ${person.email}',
          ].join(' • ');

          return _buildItemTile(
            leadingIcon: Icons.person_outline,
            title: person.fullName,
            subtitle: details,
            isActive: person.isActive,
            onToggle: () => controller.togglePersonActive(person),
            onDelete: () => controller.confirmDeletePerson(person),
          );
        },
      );
    });
  }

  // ================= TAB 5: PERSONAL DOCUMENT TYPES =================
  Widget _buildPersonalDocTypesTab(BuildContext context) {
    return Obx(() {
      final list = controller.filteredPersonalDocTypes;
      return _buildConfigSection(
        context: context,
        title: 'Personal & Identity Document Types',
        subtitle:
            'Configure official identity records and specify whether expiry date tracking is required.',
        onAdd: controller.openAddPersonalDocTypeDialog,
        addButtonText: 'Add Document Type',
        isLoading: controller.isPersonalDocTypesLoading.value,
        itemCount: list.length,
        itemBuilder: (ctx, index) {
          final type = list[index];
          final subtitle =
              'Code: ${type.code}${type.hasExpiry ? " • Expiry Tracking Active" : ""}';

          return _buildItemTile(
            leadingIcon: Icons.badge_outlined,
            title: type.name,
            subtitle: subtitle,
            isActive: type.isActive,
            onToggle: () => controller.togglePersonalDocTypeActive(type),
            onDelete: () => controller.confirmDeletePersonalDocType(type),
          );
        },
      );
    });
  }

  // ================= TAB 6: CORPORATE DOCUMENT CATEGORIES =================
  Widget _buildDocCategoriesTab(BuildContext context) {
    return Obx(() {
      final list = controller.filteredDocumentCategories;
      return _buildConfigSection(
        context: context,
        title: 'Corporate Document Categories',
        subtitle:
            'Primary organizational categories for company records and contracts. Configure City & Title requirements.',
        onAdd: controller.openAddDocumentCategoryDialog,
        addButtonText: 'Add Document Category',
        isLoading: controller.isCategoriesLoading.value,
        itemCount: list.length,
        itemBuilder: (ctx, index) {
          final cat = list[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(Icons.folder_outlined, color: AppColors.primary, size: 20),
            ),
            title: Row(
              children: [
                Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Code: ${cat.code}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cat.description != null && cat.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        cat.description!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cat.hasCityFilter
                              ? AppColors.info.withValues(alpha: 0.1)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          border: Border.all(
                            color: cat.hasCityFilter ? AppColors.info : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.hasCityFilter ? Icons.location_on : Icons.location_off_outlined,
                              size: 12,
                              color: cat.hasCityFilter ? AppColors.info : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cat.hasCityFilter ? 'City Filter: Active' : 'City Filter: Disabled',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cat.hasCityFilter ? AppColors.info : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cat.hasTitleField
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          border: Border.all(
                            color: cat.hasTitleField ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.hasTitleField ? Icons.title : Icons.text_fields_outlined,
                              size: 12,
                              color: cat.hasTitleField ? AppColors.primary : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cat.hasTitleField ? 'Title: Required' : 'Title: Auto-derived',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cat.hasTitleField ? AppColors.primary : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                  tooltip: 'Edit Category Configuration',
                  onPressed: () => controller.openEditDocumentCategoryDialog(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  tooltip: 'Delete Category',
                  onPressed: () => controller.confirmDeleteDocumentCategory(cat),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // ================= REUSABLE CONFIG SECTION CONTAINER =================
  Widget _buildConfigSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
    required String addButtonText,
    required bool isLoading,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppConstants.desktopBreakpoint;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header (Responsive Desktop vs Tablet/Mobile)
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(addButtonText),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildSearchBar()),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(addButtonText),
                    ),
                  ],
                ),
              ],
            ),

          const Divider(height: 28, color: AppColors.border),

          // Section Body: Zero bare spinners! Uses Shimmer Skeletons
          if (isLoading)
            const AppShimmer(
              child: Column(
                children: [
                  SettingsItemSkeleton(),
                  Divider(height: 1),
                  SettingsItemSkeleton(),
                  Divider(height: 1),
                  SettingsItemSkeleton(),
                  Divider(height: 1),
                  SettingsItemSkeleton(),
                ],
              ),
            )
          else if (itemCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                      ),
                      child: const Icon(Icons.search_off, size: 36, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No matching records found',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Try adjusting your search keywords or add a new entry.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: itemBuilder,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 220,
      height: 38,
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
              onPressed: controller.clearSearch,
              splashRadius: 14,
            );
          }),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile({
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required bool isActive,
    VoidCallback? onToggle,
    VoidCallback? onDelete,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySurface : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        ),
        child: Icon(
          leadingIcon,
          color: isActive ? AppColors.primary : AppColors.textMuted,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.successLight : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.successDark : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onToggle != null)
            IconButton(
              icon: Icon(
                isActive ? Icons.toggle_on : Icons.toggle_off,
                color: isActive ? AppColors.success : AppColors.textMuted,
                size: 30,
              ),
              onPressed: onToggle,
              tooltip: isActive ? 'Deactivate' : 'Activate',
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
        ],
      ),
    );
  }
}
