import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/settings/controllers/settings_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController tabScrollController = ScrollController();

    return WebScaffold(
      title: 'Settings & Master Configuration',
      subtitle: 'Manage dynamic cities, brands, appliance types, utility authorities, persons, doc types, and corporate categories',
      currentRoute: AppRoutes.SETTINGS,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final selectedTab = controller.selectedTabIndex.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scrollable Tab Navigation Bar with Arrows & Mouse Drag
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          tooltip: 'Scroll Left',
                          onPressed: () {
                            tabScrollController.animateTo(
                              tabScrollController.offset - 200,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: tabScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                                _buildTabButton(4, 'Persons & Beneficiaries', Icons.people_alt_outlined),
                                const SizedBox(width: 8),
                                _buildTabButton(5, 'Personal Doc Types', Icons.badge_outlined),
                                const SizedBox(width: 8),
                                _buildTabButton(6, 'Document Categories', Icons.folder_outlined),
                                if (controller.isAdmin) ...[
                                  const SizedBox(width: 8),
                                  _buildTabButton(7, 'Staff & Roles', Icons.admin_panel_settings_outlined),
                                ],
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          tooltip: 'Scroll Right',
                          onPressed: () {
                            tabScrollController.animateTo(
                              tabScrollController.offset + 200,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab Content
                  if (selectedTab == 0) _buildCitiesTab(),
                  if (selectedTab == 1) _buildBrandsTab(),
                  if (selectedTab == 2) _buildApplianceCategoriesTab(),
                  if (selectedTab == 3) _buildUtilityProvidersTab(),
                  if (selectedTab == 4) _buildPersonsTab(),
                  if (selectedTab == 5) _buildPersonalDocTypesTab(),
                  if (selectedTab == 6) _buildDocCategoriesTab(),
                  if (selectedTab == 7) _buildStaffTab(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = controller.selectedTabIndex.value == index;

    return InkWell(
      onTap: () => controller.selectedTabIndex.value = index,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
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
  }

  // ================= TAB 0: CITIES & LOCATIONS =================
  Widget _buildCitiesTab() {
    return _buildConfigSection(
      title: 'Master Cities & Premises Locations',
      subtitle: 'Define cities where King Technology operates. Used for document filtering & utility location tags.',
      onAdd: controller.openAddCityDialog,
      addButtonText: 'Add New City',
      isLoading: controller.isCitiesLoading.value,
      children: controller.cities.map((city) {
        return _buildItemTile(
          title: city.name,
          subtitle: 'State: ${city.state}',
          isActive: city.isActive,
          onToggle: () => controller.toggleCityActive(city),
          onDelete: () => controller.deleteCity(city),
        );
      }).toList(),
    );
  }

  // ================= TAB 1: APPLIANCE BRANDS =================
  Widget _buildBrandsTab() {
    return _buildConfigSection(
      title: 'Master Appliance & Electronics Brands',
      subtitle: 'Manage official brand list for warranty tracking, product classification, and invoice search.',
      onAdd: controller.openAddBrandDialog,
      addButtonText: 'Add New Brand',
      isLoading: controller.isBrandsLoading.value,
      children: controller.brands.map((brand) {
        return _buildItemTile(
          title: brand.name,
          subtitle: 'Category: ${brand.categoryType.toUpperCase()}',
          isActive: brand.isActive,
          onToggle: () => controller.toggleBrandActive(brand),
          onDelete: () => controller.deleteBrand(brand),
        );
      }).toList(),
    );
  }

  // ================= TAB 2: APPLIANCE CATEGORIES =================
  Widget _buildApplianceCategoriesTab() {
    return _buildConfigSection(
      title: 'Appliance Types & Subcategories',
      subtitle: 'Configure types of appliances with default standard warranty periods.',
      onAdd: controller.openAddApplianceSubcategoryDialog,
      addButtonText: 'Add Appliance Type',
      isLoading: controller.isApplianceSubcategoriesLoading.value,
      children: controller.applianceSubcategories.map((sub) {
        return _buildItemTile(
          title: sub.name,
          subtitle: 'Standard Warranty: ${sub.defaultWarrantyMonths} Months',
          isActive: sub.isActive,
          onToggle: () => controller.toggleApplianceSubcategoryActive(sub),
          onDelete: () => controller.deleteApplianceSubcategory(sub),
        );
      }).toList(),
    );
  }

  // ================= TAB 3: UTILITY PROVIDERS =================
  Widget _buildUtilityProvidersTab() {
    return _buildConfigSection(
      title: 'Master Utility Providers & Authorities',
      subtitle: 'Manage electricity boards, gas distributors, municipal water departments, and internet ISPs.',
      onAdd: controller.openAddUtilityProviderDialog,
      addButtonText: 'Add Utility Provider',
      isLoading: controller.isUtilityProvidersLoading.value,
      children: controller.utilityProviders.map((prov) {
        return _buildItemTile(
          title: prov.name,
          subtitle: 'Utility Type: ${prov.utilityType}',
          isActive: prov.isActive,
          onToggle: () => controller.toggleUtilityProviderActive(prov),
          onDelete: () => controller.deleteUtilityProvider(prov),
        );
      }).toList(),
    );
  }

  // ================= TAB 4: PERSONS & BENEFICIARIES =================
  Widget _buildPersonsTab() {
    return _buildConfigSection(
      title: 'Persons & Family Members',
      subtitle: 'Add people (e.g. Mihir Gandhi) for grouping and filtering personal identity documents (Aadhaar, PAN, Passport, etc.).',
      onAdd: controller.openAddPersonDialog,
      addButtonText: 'Add Person / Member',
      isLoading: controller.isPersonsLoading.value,
      children: controller.persons.map((person) {
        final details = [
          'Relationship: ${person.relationship}',
          if (person.phoneNumber != null && person.phoneNumber!.isNotEmpty) 'Phone: ${person.phoneNumber}',
          if (person.email != null && person.email!.isNotEmpty) 'Email: ${person.email}',
        ].join(' • ');

        return _buildItemTile(
          title: person.fullName,
          subtitle: details,
          isActive: person.isActive,
          onToggle: () => controller.togglePersonActive(person),
          onDelete: () => controller.deletePerson(person),
        );
      }).toList(),
    );
  }

  // ================= TAB 5: PERSONAL DOCUMENT TYPES =================
  Widget _buildPersonalDocTypesTab() {
    return _buildConfigSection(
      title: 'Personal & Identity Document Types',
      subtitle: 'Configure types of personal records (Aadhaar Card, PAN Card, Passport, Driving License, etc.).',
      onAdd: controller.openAddPersonalDocTypeDialog,
      addButtonText: 'Add Document Type',
      isLoading: controller.isPersonalDocTypesLoading.value,
      children: controller.personalDocTypes.map((type) {
        final subtitle = 'Code: ${type.code}${type.hasExpiry ? " • Expiry Tracking Enabled" : ""}';

        return _buildItemTile(
          title: type.name,
          subtitle: subtitle,
          isActive: type.isActive,
          onToggle: () => controller.togglePersonalDocTypeActive(type),
          onDelete: () => controller.deletePersonalDocType(type),
        );
      }).toList(),
    );
  }

  // ================= TAB 6: DOCUMENT CATEGORIES =================
  Widget _buildDocCategoriesTab() {
    return _buildConfigSection(
      title: 'Corporate Document Categories',
      subtitle: 'Primary organizational categories for organizing company records, contracts, and receipts. Configure City & Title requirements.',
      onAdd: controller.openAddDocumentCategoryDialog,
      addButtonText: 'Add Document Category',
      isLoading: controller.isCategoriesLoading.value,
      children: controller.documentCategories.map((cat) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.folder_outlined, color: AppColors.primary, size: 20),
          ),
          title: Row(
            children: [
              Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('Code: ${cat.code}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary)),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cat.description != null && cat.description!.isNotEmpty)
                  Text(cat.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cat.hasCityFilter ? AppColors.info.withValues(alpha: 0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cat.hasCityFilter ? AppColors.info : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.hasCityFilter ? Icons.location_on : Icons.location_off_outlined,
                              size: 12, color: cat.hasCityFilter ? AppColors.info : AppColors.textMuted),
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
                        color: cat.hasTitleField ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cat.hasTitleField ? AppColors.primary : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.hasTitleField ? Icons.title : Icons.text_fields_outlined,
                              size: 12, color: cat.hasTitleField ? AppColors.primary : AppColors.textMuted),
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
                onPressed: () => controller.deleteDocumentCategory(cat),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ================= TAB 7: STAFF & ROLES =================
  Widget _buildStaffTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Staff & User Access Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Only the master Administrator can provision staff profiles and assign roles.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: controller.openCreateStaffDialog,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                label: const Text('Provision Staff User'),
              ),
            ],
          ),
          const Divider(height: 28),
          if (controller.isStaffLoading.value)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (controller.staffList.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No staff members found.')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.staffList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final staff = controller.staffList[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('${staff.email} • Dept: ${staff.department ?? "General"}', style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(
                        label: staff.role.toUpperCase(),
                        type: staff.role == 'admin' ? StatusBadgeType.warning : StatusBadgeType.info,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          staff.isActive ? Icons.toggle_on : Icons.toggle_off,
                          color: staff.isActive ? AppColors.success : AppColors.textMuted,
                          size: 30,
                        ),
                        onPressed: () => controller.toggleStaffActive(staff),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Helper Configuration Card Section
  Widget _buildConfigSection({
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
    required String addButtonText,
    required bool isLoading,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: Text(addButtonText),
              ),
            ],
          ),
          const Divider(height: 28),
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (children.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No items found.')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: children.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => children[index],
            ),
        ],
      ),
    );
  }

  Widget _buildItemTile({
    required String title,
    required String subtitle,
    required bool isActive,
    VoidCallback? onToggle,
    VoidCallback? onDelete,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
