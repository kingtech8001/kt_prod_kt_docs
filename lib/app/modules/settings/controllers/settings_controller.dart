import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/settings_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Controller for Settings & Master Data Management.
/// Strictly follows 3-tier architecture: View -> Controller -> Dataset -> Supabase.
class SettingsController extends GetxController {
  final SettingsDataset _dataset;

  SettingsController(this._dataset);

  // Global State
  final isLoading = false.obs;
  final profile = Rxn<ProfileModel>();
  final selectedTabIndex = 0.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  // In-Dialog Reactive State for In-Context Error Reporting
  final dialogErrorMessage = ''.obs;
  final isSubmitting = false.obs;

  // Personal Profile Controllers
  final fullNameController = TextEditingController();
  final departmentController = TextEditingController();
  final phoneController = TextEditingController();

  // Master Data Observables
  final cities = <MasterCityModel>[].obs;
  final isCitiesLoading = false.obs;

  final brands = <MasterBrandModel>[].obs;
  final isBrandsLoading = false.obs;

  final applianceSubcategories = <MasterApplianceSubcategoryModel>[].obs;
  final isApplianceSubcategoriesLoading = false.obs;

  final utilityProviders = <MasterUtilityProviderModel>[].obs;
  final isUtilityProvidersLoading = false.obs;

  final persons = <MasterPersonModel>[].obs;
  final isPersonsLoading = false.obs;

  final personalDocTypes = <MasterPersonalDocTypeModel>[].obs;
  final isPersonalDocTypesLoading = false.obs;

  final documentCategories = <CategoryModel>[].obs;
  final isCategoriesLoading = false.obs;

  // Dialog Form Input Controllers
  final cityNameController = TextEditingController();
  final cityStateController = TextEditingController();

  final brandNameController = TextEditingController();
  final brandCategoryType = 'appliance'.obs;

  final applianceCategoryNameController = TextEditingController();
  final applianceWarrantyMonthsController = TextEditingController(text: '12');
  final applianceIconName = 'kitchen'.obs;

  final utilityProviderNameController = TextEditingController();
  final utilityTypeSelection = 'Light / Electricity Bill'.obs;

  final personNameController = TextEditingController();
  final personRelationship = 'Self'.obs;
  final personPhoneController = TextEditingController();
  final personEmailController = TextEditingController();

  final docTypeNameController = TextEditingController();
  final docTypeCodeController = TextEditingController();
  final docTypeHasExpiry = false.obs;
  final docTypeIconName = 'badge'.obs;

  final docCategoryNameController = TextEditingController();
  final docCategoryCodeController = TextEditingController();
  final docCategoryColorController = TextEditingController(text: '#1E3A8A');
  final docCategoryDescController = TextEditingController();
  final docCategoryHasCityFilter = true.obs;
  final docCategoryHasTitleField = true.obs;

  bool get isAdmin =>
      profile.value?.role == 'admin' || profile.value?.role == 'super_admin';

  // ================= FILTERED LISTS (SEARCH) =================

  List<MasterCityModel> get filteredCities {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return cities;
    return cities.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.state.toLowerCase().contains(query);
    }).toList();
  }

  List<MasterBrandModel> get filteredBrands {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return brands;
    return brands.where((b) {
      return b.name.toLowerCase().contains(query) ||
          b.categoryType.toLowerCase().contains(query);
    }).toList();
  }

  List<MasterApplianceSubcategoryModel> get filteredApplianceSubcategories {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return applianceSubcategories;
    return applianceSubcategories.where((a) {
      return a.name.toLowerCase().contains(query);
    }).toList();
  }

  List<MasterUtilityProviderModel> get filteredUtilityProviders {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return utilityProviders;
    return utilityProviders.where((u) {
      return u.name.toLowerCase().contains(query) ||
          u.utilityType.toLowerCase().contains(query);
    }).toList();
  }

  List<MasterPersonModel> get filteredPersons {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return persons;
    return persons.where((p) {
      return p.fullName.toLowerCase().contains(query) ||
          p.relationship.toLowerCase().contains(query) ||
          (p.phoneNumber != null && p.phoneNumber!.toLowerCase().contains(query)) ||
          (p.email != null && p.email!.toLowerCase().contains(query));
    }).toList();
  }

  List<MasterPersonalDocTypeModel> get filteredPersonalDocTypes {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return personalDocTypes;
    return personalDocTypes.where((d) {
      return d.name.toLowerCase().contains(query) ||
          d.code.toLowerCase().contains(query);
    }).toList();
  }

  List<CategoryModel> get filteredDocumentCategories {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return documentCategories;
    return documentCategories.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.code.toLowerCase().contains(query) ||
          (c.description != null && c.description!.toLowerCase().contains(query));
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    loadAllMasterData();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final p = await _dataset.getCurrentProfile();
      profile.value = p;
      if (p != null) {
        fullNameController.text = p.fullName;
        departmentController.text = p.department ?? '';
        phoneController.text = p.phoneNumber ?? '';
      }
    } catch (e, st) {
      AppLogger.error('SETTINGS_CTRL', 'Error loading profile: $e', error: e, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllMasterData() async {
    await Future.wait([
      loadCities(),
      loadBrands(),
      loadApplianceSubcategories(),
      loadUtilityProviders(),
      loadPersons(),
      loadPersonalDocTypes(),
      loadDocumentCategories(),
    ]);
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  void switchTab(int index) {
    selectedTabIndex.value = index;
    clearSearch();
  }

  // ================= CITIES =================

  Future<void> loadCities() async {
    isCitiesLoading.value = true;
    try {
      final list = await _dataset.getCities(activeOnly: false);
      cities.assignAll(list);
    } catch (e, st) {
      AppLogger.error('SETTINGS_CTRL', 'Error loading cities: $e', error: e, stackTrace: st);
    } finally {
      isCitiesLoading.value = false;
    }
  }

  void openAddCityDialog() {
    cityNameController.clear();
    cityStateController.text = 'Gujarat';
    dialogErrorMessage.value = '';
    isSubmitting.value = false;

    AppDialog.show(
      _buildDialogContainer(
        title: 'Add New City',
        icon: Icons.location_city,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'City Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: cityNameController,
              decoration: const InputDecoration(hintText: 'e.g. Ahmedabad, Surat, Mumbai'),
            ),
            const SizedBox(height: 14),
            const Text(
              'State / Region',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: cityStateController,
              decoration: const InputDecoration(hintText: 'e.g. Gujarat, Maharashtra'),
            ),
          ],
        ),
        onConfirm: () async {
          final name = cityNameController.text.trim();
          final state = cityStateController.text.trim().isNotEmpty
              ? cityStateController.text.trim()
              : 'Gujarat';

          if (name.isEmpty) {
            dialogErrorMessage.value = 'City name is required.';
            return;
          }

          isSubmitting.value = true;
          dialogErrorMessage.value = '';
          try {
            await _dataset.addCity(name: name, state: state);
            Get.back();
            AppSnackbar.showSuccess('City Added', 'City "$name" added successfully.');
            loadCities();
          } catch (e) {
            dialogErrorMessage.value = 'Failed to add city: ${e.toString()}';
          } finally {
            isSubmitting.value = false;
          }
        },
        confirmButtonText: 'Add City',
      ),
      barrierDismissible: false,
    );
  }

  Future<void> toggleCityActive(MasterCityModel city) async {
    try {
      await _dataset.updateCity(
        id: city.id,
        name: city.name,
        state: city.state,
        isActive: !city.isActive,
      );
      AppSnackbar.showInfo(
        city.isActive ? 'City Deactivated' : 'City Activated',
        'City "${city.name}" status updated.',
      );
      loadCities();
    } catch (e) {
      AppSnackbar.showError('Update Failed', e.toString());
    }
  }

  void confirmDeleteCity(MasterCityModel city) {
    _showDeleteConfirmation(
      title: 'Delete City',
      message: 'Are you sure you want to delete "${city.name}"? Documents linked to this city may lose their location filter.',
      onDelete: () async {
        await _dataset.deleteCity(city.id);
        AppSnackbar.showSuccess('City Removed', 'City "${city.name}" deleted.');
        loadCities();
      },
    );
  }

  // ================= BRANDS =================

  Future<void> loadBrands() async {
    isBrandsLoading.value = true;
    try {
      final list = await _dataset.getBrands(activeOnly: false);
      brands.assignAll(list);
    } catch (e, st) {
      AppLogger.error('SETTINGS_CTRL', 'Error loading brands: $e', error: e, stackTrace: st);
    } finally {
      isBrandsLoading.value = false;
    }
  }

  void openAddBrandDialog() {
    brandNameController.clear();
    brandCategoryType.value = 'appliance';
    dialogErrorMessage.value = '';
    isSubmitting.value = false;

    AppDialog.show(
      _buildDialogContainer(
        title: 'Add New Brand',
        icon: Icons.branding_watermark_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brand Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: brandNameController,
              decoration: const InputDecoration(hintText: 'e.g. Havells, Crompton, Samsung'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Category Type',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Obx(() => DropdownButtonFormField<String>(
                  value: brandCategoryType.value,
                  items: const [
                    DropdownMenuItem(value: 'appliance', child: Text('Home Appliance')),
                    DropdownMenuItem(value: 'electronics', child: Text('Electronics & Gadgets')),
                    DropdownMenuItem(value: 'office', child: Text('Office Equipment')),
                    DropdownMenuItem(value: 'utility', child: Text('Utility / Infrastructure')),
                  ],
                  onChanged: (val) {
                    if (val != null) brandCategoryType.value = val;
                  },
                )),
          ],
        ),
        onConfirm: () async {
          final name = brandNameController.text.trim();
          if (name.isEmpty) {
            dialogErrorMessage.value = 'Brand name is required.';
            return;
          }

          isSubmitting.value = true;
          dialogErrorMessage.value = '';
          try {
            await _dataset.addBrand(name: name, categoryType: brandCategoryType.value);
            Get.back();
            AppSnackbar.showSuccess('Brand Added', 'Brand "$name" added successfully.');
            loadBrands();
          } catch (e) {
            dialogErrorMessage.value = 'Failed to add brand: ${e.toString()}';
          } finally {
            isSubmitting.value = false;
          }
        },
        confirmButtonText: 'Add Brand',
      ),
      barrierDismissible: false,
    );
  }

  Future<void> toggleBrandActive(MasterBrandModel brand) async {
    try {
      await _dataset.updateBrand(
        id: brand.id,
        name: brand.name,
        categoryType: brand.categoryType,
        isActive: !brand.isActive,
      );
      AppSnackbar.showInfo(
        brand.isActive ? 'Brand Deactivated' : 'Brand Activated',
        'Brand "${brand.name}" status updated.',
      );
      loadBrands();
    } catch (e) {
      AppSnackbar.showError('Update Failed', e.toString());
    }
  }

  void confirmDeleteBrand(MasterBrandModel brand) {
    _showDeleteConfirmation(
      title: 'Delete Brand',
      message: 'Are you sure you want to delete brand "${brand.name}"?',
      onDelete: () async {
        await _dataset.deleteBrand(brand.id);
        AppSnackbar.showSuccess('Brand Removed', 'Brand "${brand.name}" deleted.');
        loadBrands();
      },
    );
  }

  // ================= APPLIANCE SUBCATEGORIES =================

  Future<void> loadApplianceSubcategories() async {
    isApplianceSubcategoriesLoading.value = true;
    try {
      final list = await _dataset.getApplianceSubcategories(activeOnly: false);
      applianceSubcategories.assignAll(list);
    } catch (e, st) {
      AppLogger.error('SETTINGS_CTRL', 'Error loading appliance subcategories: $e', error: e, stackTrace: st);
    } finally {
      isApplianceSubcategoriesLoading.value = false;
    }
  }

  void openAddApplianceSubcategoryDialog() {
    applianceCategoryNameController.clear();
    applianceWarrantyMonthsController.text = '12';
    applianceIconName.value = 'kitchen';
    dialogErrorMessage.value = '';
    isSubmitting.value = false;

    AppDialog.show(
      _buildDialogContainer(
        title: 'Add Appliance Category',
        icon: Icons.kitchen_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category / Item Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: applianceCategoryNameController,
              decoration: const InputDecoration(hintText: 'e.g. Ceiling Fan, Geyser, AC'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Default Warranty Duration (Months) *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: applianceWarrantyMonthsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '12 (1 year), 24 (2 years)'),
            ),
          ],
        ),
        onConfirm: () async {
          final name = applianceCategoryNameController.text.trim();
          final months = int.tryParse(applianceWarrantyMonthsController.text.trim()) ?? 12;

          if (name.isEmpty) {
            dialogErrorMessage.value = 'Appliance category name is required.';
            return;
          }

          isSubmitting.value = true;
          dialogErrorMessage.value = '';
          try {
            await _dataset.addApplianceSubcategory(
              name: name,
              defaultWarrantyMonths: months,
              iconName: applianceIconName.value,
            );
            Get.back();
            AppSnackbar.showSuccess('Category Added', 'Appliance category "$name" added.');
            loadApplianceSubcategories();
          } catch (e) {
            dialogErrorMessage.value = 'Failed to add category: ${e.toString()}';
          } finally {
            isSubmitting.value = false;
          }
        },
        confirmButtonText: 'Add Category',
      ),
      barrierDismissible: false,
    );
  }

  Future<void> toggleApplianceSubcategoryActive(MasterApplianceSubcategoryModel sub) async {
    try {
      await _dataset.updateApplianceSubcategory(
        id: sub.id,
        name: sub.name,
        defaultWarrantyMonths: sub.defaultWarrantyMonths,
        iconName: sub.iconName,
        isActive: !sub.isActive,
      );
      AppSnackbar.showInfo(
        sub.isActive ? 'Category Deactivated' : 'Category Activated',
        'Category "${sub.name}" status updated.',
      );
      loadApplianceSubcategories();
    } catch (e) {
      AppSnackbar.showError('Update Failed', e.toString());
    }
  }

  void confirmDeleteApplianceSubcategory(MasterApplianceSubcategoryModel sub) {
    _showDeleteConfirmation(
      title: 'Delete Appliance Category',
      message: 'Are you sure you want to delete "${sub.name}"?',
      onDelete: () async {
        await _dataset.deleteApplianceSubcategory(sub.id);
        AppSnackbar.showSuccess('Category Removed', 'Category "${sub.name}" deleted.');
        loadApplianceSubcategories();
      },
    );
  }

  // ================= UTILITY PROVIDERS =================

  Future<void> loadUtilityProviders() async {
    isUtilityProvidersLoading.value = true;
    try {
      final list = await _dataset.getUtilityProviders(activeOnly: false);
      utilityProviders.assignAll(list);
    } catch (e, st) {
      AppLogger.error('SETTINGS_CTRL', 'Error loading utility providers: $e', error: e, stackTrace: st);
    } finally {
      isUtilityProvidersLoading.value = false;
    }
  }

  void openAddUtilityProviderDialog() {
    utilityProviderNameController.clear();
    utilityTypeSelection.value = 'Light / Electricity Bill';
    dialogErrorMessage.value = '';
    isSubmitting.value = false;

    AppDialog.show(
      _buildDialogContainer(
        title: 'Add Utility Provider',
        icon: Icons.bolt_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provider Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: utilityProviderNameController,
              decoration: const InputDecoration(hintText: 'e.g. Torrent Power, Adani Gas, DGVCL'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Utility Type *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Obx(() => DropdownButtonFormField<String>(
                  value: utilityTypeSelection.value,
                  items: const [
                    DropdownMenuItem(value: 'Light / Electricity Bill', child: Text('Light / Electricity')),
                    DropdownMenuItem(value: 'Gas Bill (PNG / Piped)', child: Text('Gas (PNG / Piped)')),
                    DropdownMenuItem(value: 'Gas Cylinder (LPG)', child: Text('Gas Cylinder (LPG)')),
                    DropdownMenuItem(value: 'Water & Drainage Bill', child: Text('Water & Drainage')),
                    DropdownMenuItem(value: 'Internet / Broadband Bill', child: Text('Internet / Broadband')),
                    DropdownMenuItem(value: 'Property Tax / House Tax', child: Text('Property Tax')),
                    DropdownMenuItem(value: 'Rent / Lease Receipt', child: Text('Rent / Lease')),
                  ],
                  onChanged: (val) {
                    if (val != null) utilityTypeSelection.value = val;
                  },
                )),
          ],
        ),
        onConfirm: () async {
          final name = utilityProviderNameController.text.trim();
          if (name.isEmpty) {
            dialogErrorMessage.value = 'Provider name is required.';
            return;
          }

          isSubmitting.value = true;
          dialogErrorMessage.value = '';
          try {
            await _dataset.addUtilityProvider(name: name, utilityType: utilityTypeSelection.value);
            Get.back();
            AppSnackbar.showSuccess('Provider Added', 'Utility provider "$name" added.');
            loadUtilityProviders();
          } catch (e) {
            dialogErrorMessage.value = 'Failed to add provider: ${e.toString()}';
          } finally {
            isSubmitting.value = false;
          }
        },
        confirmButtonText: 'Add Provider',
      ),
      barrierDismissible: false,
    );
  }

  Future<void> toggleUtilityProviderActive(MasterUtilityProviderModel provider) async {
    try {
      await _dataset.updateUtilityProvider(
        id: provider.id,
        name: provider.name,
        utilityType: provider.utilityType,
        isActive: !provider.isActive,
      );
      AppSnackbar.showInfo(
        provider.isActive ? 'Provider Deactivated' : 'Provider Activated',
        'Provider "${provider.name}" status updated.',
      );
      loadUtilityProviders();
    } catch (e) {
      AppSnackbar.showError('Update Failed', e.toString());
    }
  }

  void confirmDeleteUtilityProvider(MasterUtilityProviderModel provider) {
    _showDeleteConfirmation(
      title: 'Delete Utility Provider',
      message: 'Are you sure you want to delete "${provider.name}"?',
      onDelete: () async {
        await _dataset.deleteUtilityProvider(provider.id);
        AppSnackbar.showSuccess('Provider Removed', 'Provider "${provider.name}" deleted.');
        loadUtilityProviders();
      },
    );
  }

  // ================= PERSONS & BENEFICIARIES =================

  Future<void> loadPersons() async {
    isPersonsLoading.value = true;
    try {
      final list = await _dataset.getPersons(activeOnly: false);
      persons.assignAll(list);
    } catch (e, st) {
      AppLogger.error('SETTINGS_CTRL', 'Error loading persons: $e', error: e, stackTrace: st);
    } finally {
      isPersonsLoading.value = false;
    }
  }

  void openAddPersonDialog() {
    personNameController.clear();
    personRelationship.value = 'Self';
    personPhoneController.clear();
    personEmailController.clear();
    dialogErrorMessage.value = '';
    isSubmitting.value = false;

    AppDialog.show(
      _buildDialogContainer(
        title: 'Add Person / Member',
        icon: Icons.person_add_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Full Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: personNameController,
              decoration: const InputDecoration(hintText: 'e.g. Mihir Gandhi, Suresh Gandhi'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Relationship *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Obx(() => DropdownButtonFormField<String>(
                  value: personRelationship.value,
                  items: const [
                    DropdownMenuItem(value: 'Self', child: Text('Self')),
                    DropdownMenuItem(value: 'Spouse', child: Text('Spouse / Partner')),
                    DropdownMenuItem(value: 'Father', child: Text('Father')),
                    DropdownMenuItem(value: 'Mother', child: Text('Mother')),
                    DropdownMenuItem(value: 'Son', child: Text('Son')),
                    DropdownMenuItem(value: 'Daughter', child: Text('Daughter')),
                    DropdownMenuItem(value: 'Brother', child: Text('Brother')),
                    DropdownMenuItem(value: 'Sister', child: Text('Sister')),
                    DropdownMenuItem(value: 'Staff', child: Text('Staff Member')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) personRelationship.value = val;
                  },
                )),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phone Number',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: personPhoneController,
                        decoration: const InputDecoration(hintText: '+91 9876543210'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: personEmailController,
                        decoration: const InputDecoration(hintText: 'person@email.com'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onConfirm: () async {
          final name = personNameController.text.trim();
          if (name.isEmpty) {
            dialogErrorMessage.value = 'Person full name is required.';
            return;
          }

          isSubmitting.value = true;
          dialogErrorMessage.value = '';
          try {
            await _dataset.addPerson(
              fullName: name,
              relationship: personRelationship.value,
              phoneNumber: personPhoneController.text.trim().isNotEmpty
                  ? personPhoneController.text.trim()
                  : null,
              email: personEmailController.text.trim().isNotEmpty
                  ? personEmailController.text.trim()
                  : null,
            );
            Get.back();
            AppSnackbar.showSuccess('Person Added', 'Added "$name" to master persons list.');
            loadPersons();
          } catch (e) {
            dialogErrorMessage.value = 'Failed to add person: ${e.toString()}';
          } finally {
            isSubmitting.value = false;
          }
        },
        confirmButtonText: 'Add Person',
      ),
      barrierDismissible: false,
    );
  }

  Future<void> togglePersonActive(MasterPersonModel person) async {
    try {
      await _dataset.updatePerson(
        id: person.id,
        fullName: person.fullName,
        relationship: person.relationship,
        dateOfBirth: person.dateOfBirth,
        phoneNumber: person.phoneNumber,
        email: person.email,
        isActive: !person.isActive,
      );
      AppSnackbar.showInfo(
        person.isActive ? 'Person Deactivated' : 'Person Activated',
        'Person "${person.fullName}" status updated.',
      );
      loadPersons();
    } catch (e) {
      AppSnackbar.showError('Update Failed', e.toString());
    }
  }

  void confirmDeletePerson(MasterPersonModel person) {
    _showDeleteConfirmation(
      title: 'Delete Person',
      message: 'Are you sure you want to remove "${person.fullName}" from the persons directory?',
      onDelete: () async {
        await _dataset.deletePerson(person.id);
        AppSnackbar.showSuccess('Person Removed', 'Person "${person.fullName}" removed.');
        loadPersons();
      },
    );
  }

  // ================= PERSONAL DOC TYPES =================

  Future<void> loadPersonalDocTypes() async {
    isPersonalDocTypesLoading.value = true;
    try {
      final list = await _dataset.getPersonalDocTypes(activeOnly: false);
      personalDocTypes.assignAll(list);
    } catch (e, st) {
      AppLogger.error('SETTINGS_CTRL', 'Error loading personal doc types: $e', error: e, stackTrace: st);
    } finally {
      isPersonalDocTypesLoading.value = false;
    }
  }

  void openAddPersonalDocTypeDialog() {
    docTypeNameController.clear();
    docTypeCodeController.clear();
    docTypeHasExpiry.value = false;
    dialogErrorMessage.value = '';
    isSubmitting.value = false;

    AppDialog.show(
      _buildDialogContainer(
        title: 'Add Personal Document Type',
        icon: Icons.badge_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Document Type Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: docTypeNameController,
              decoration: const InputDecoration(hintText: 'e.g. Aadhaar Card, PAN Card, Passport'),
              onChanged: (val) {
                if (docTypeCodeController.text.isEmpty ||
                    docTypeCodeController.text.startsWith(RegExp(r'[a-z_]+'))) {
                  docTypeCodeController.text =
                      val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                }
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Internal System Code *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: docTypeCodeController,
              decoration: const InputDecoration(hintText: 'e.g. aadhaar, pan, passport'),
            ),
            const SizedBox(height: 14),
            Obx(() => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Requires Expiry Date Tracking (e.g. Passport, Driving License)',
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  value: docTypeHasExpiry.value,
                  onChanged: (val) {
                    if (val != null) docTypeHasExpiry.value = val;
                  },
                )),
          ],
        ),
        onConfirm: () async {
          final name = docTypeNameController.text.trim();
          final code = docTypeCodeController.text.trim().toLowerCase();

          if (name.isEmpty || code.isEmpty) {
            dialogErrorMessage.value = 'Document type name and code are required.';
            return;
          }

          isSubmitting.value = true;
          dialogErrorMessage.value = '';
          try {
            await _dataset.addPersonalDocType(
              name: name,
              code: code,
              hasExpiry: docTypeHasExpiry.value,
            );
            Get.back();
            AppSnackbar.showSuccess('Doc Type Added', 'Document type "$name" added.');
            loadPersonalDocTypes();
          } catch (e) {
            dialogErrorMessage.value = 'Failed to add doc type: ${e.toString()}';
          } finally {
            isSubmitting.value = false;
          }
        },
        confirmButtonText: 'Add Document Type',
      ),
      barrierDismissible: false,
    );
  }

  Future<void> togglePersonalDocTypeActive(MasterPersonalDocTypeModel type) async {
    try {
      await _dataset.updatePersonalDocType(
        id: type.id,
        name: type.name,
        code: type.code,
        iconName: type.iconName,
        hasExpiry: type.hasExpiry,
        isActive: !type.isActive,
      );
      AppSnackbar.showInfo(
        type.isActive ? 'Doc Type Deactivated' : 'Doc Type Activated',
        'Document type "${type.name}" status updated.',
      );
      loadPersonalDocTypes();
    } catch (e) {
      AppSnackbar.showError('Update Failed', e.toString());
    }
  }

  void confirmDeletePersonalDocType(MasterPersonalDocTypeModel type) {
    _showDeleteConfirmation(
      title: 'Delete Document Type',
      message: 'Are you sure you want to delete "${type.name}"?',
      onDelete: () async {
        await _dataset.deletePersonalDocType(type.id);
        AppSnackbar.showSuccess('Type Removed', 'Document type "${type.name}" deleted.');
        loadPersonalDocTypes();
      },
    );
  }

  // ================= CORPORATE DOCUMENT CATEGORIES =================

  Future<void> loadDocumentCategories() async {
    isCategoriesLoading.value = true;
    try {
      final list = await _dataset.getDocumentCategories();
      documentCategories.assignAll(list);
    } catch (e, st) {
      AppLogger.error('SETTINGS_CTRL', 'Error loading document categories: $e', error: e, stackTrace: st);
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  void openAddDocumentCategoryDialog() {
    docCategoryNameController.clear();
    docCategoryCodeController.clear();
    docCategoryColorController.text = '#1E3A8A';
    docCategoryDescController.clear();
    docCategoryHasCityFilter.value = true;
    docCategoryHasTitleField.value = true;
    dialogErrorMessage.value = '';
    isSubmitting.value = false;

    AppDialog.show(
      _buildDialogContainer(
        title: 'Add Corporate Document Category',
        icon: Icons.folder_special_outlined,
        maxWidth: 500,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: docCategoryNameController,
              decoration: const InputDecoration(hintText: 'e.g. Legal Agreements, HR Records'),
              onChanged: (val) {
                if (docCategoryCodeController.text.isEmpty ||
                    docCategoryCodeController.text.startsWith(RegExp(r'[a-z_]+'))) {
                  docCategoryCodeController.text =
                      val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                }
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Code Identifier *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: docCategoryCodeController,
              decoration: const InputDecoration(hintText: 'e.g. legal_agreements, hr_docs'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Description',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: docCategoryDescController,
              decoration: const InputDecoration(hintText: 'Brief description of category usage'),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            const Text(
              'Category Form Configuration',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            Obx(() => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Require City / Location Filter',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'If enabled, users can assign a city and premise location during upload.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  value: docCategoryHasCityFilter.value,
                  onChanged: (val) => docCategoryHasCityFilter.value = val ?? true,
                  controlAffinity: ListTileControlAffinity.leading,
                )),
            Obx(() => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Require Document Title Input',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'If disabled, the document title is auto-derived from the uploaded file name.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  value: docCategoryHasTitleField.value,
                  onChanged: (val) => docCategoryHasTitleField.value = val ?? true,
                  controlAffinity: ListTileControlAffinity.leading,
                )),
          ],
        ),
        onConfirm: () async {
          final name = docCategoryNameController.text.trim();
          final code = docCategoryCodeController.text.trim();

          if (name.isEmpty || code.isEmpty) {
            dialogErrorMessage.value = 'Category name and code identifier are required.';
            return;
          }

          isSubmitting.value = true;
          dialogErrorMessage.value = '';
          try {
            await _dataset.addDocumentCategory(
              name: name,
              code: code,
              colorHex: docCategoryColorController.text.trim(),
              description: docCategoryDescController.text.trim(),
              hasCityFilter: docCategoryHasCityFilter.value,
              hasTitleField: docCategoryHasTitleField.value,
            );
            Get.back();
            AppSnackbar.showSuccess('Category Added', 'Document category "$name" created.');
            loadDocumentCategories();
          } catch (e) {
            dialogErrorMessage.value = 'Failed to add category: ${e.toString()}';
          } finally {
            isSubmitting.value = false;
          }
        },
        confirmButtonText: 'Add Category',
      ),
      barrierDismissible: false,
    );
  }

  void openEditDocumentCategoryDialog(CategoryModel cat) {
    docCategoryNameController.text = cat.name;
    docCategoryCodeController.text = cat.code;
    docCategoryColorController.text = cat.colorHex;
    docCategoryDescController.text = cat.description ?? '';
    docCategoryHasCityFilter.value = cat.hasCityFilter;
    docCategoryHasTitleField.value = cat.hasTitleField;
    dialogErrorMessage.value = '';
    isSubmitting.value = false;

    AppDialog.show(
      _buildDialogContainer(
        title: 'Edit Document Category',
        icon: Icons.edit_note,
        maxWidth: 500,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: docCategoryNameController,
              decoration: const InputDecoration(hintText: 'e.g. Legal Agreements, HR Records'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Code Identifier *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: docCategoryCodeController,
              decoration: const InputDecoration(hintText: 'e.g. legal_agreements, hr_docs'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Description',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: docCategoryDescController,
              decoration: const InputDecoration(hintText: 'Brief description of category usage'),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            const Text(
              'Category Form Configuration',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            Obx(() => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Require City / Location Filter',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'If enabled, users can assign a city and premise location during upload.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  value: docCategoryHasCityFilter.value,
                  onChanged: (val) => docCategoryHasCityFilter.value = val ?? true,
                  controlAffinity: ListTileControlAffinity.leading,
                )),
            Obx(() => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Require Document Title Input',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'If disabled, the document title is auto-derived from the uploaded file name.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  value: docCategoryHasTitleField.value,
                  onChanged: (val) => docCategoryHasTitleField.value = val ?? true,
                  controlAffinity: ListTileControlAffinity.leading,
                )),
          ],
        ),
        onConfirm: () async {
          final name = docCategoryNameController.text.trim();
          final code = docCategoryCodeController.text.trim();

          if (name.isEmpty || code.isEmpty) {
            dialogErrorMessage.value = 'Category name and code identifier are required.';
            return;
          }

          isSubmitting.value = true;
          dialogErrorMessage.value = '';
          try {
            await _dataset.updateDocumentCategory(
              id: cat.id,
              name: name,
              code: code,
              colorHex: docCategoryColorController.text.trim(),
              description: docCategoryDescController.text.trim(),
              hasCityFilter: docCategoryHasCityFilter.value,
              hasTitleField: docCategoryHasTitleField.value,
            );
            Get.back();
            AppSnackbar.showSuccess('Category Updated', 'Document category "$name" updated.');
            loadDocumentCategories();
          } catch (e) {
            dialogErrorMessage.value = 'Failed to update category: ${e.toString()}';
          } finally {
            isSubmitting.value = false;
          }
        },
        confirmButtonText: 'Save Changes',
      ),
      barrierDismissible: false,
    );
  }

  void confirmDeleteDocumentCategory(CategoryModel cat) {
    _showDeleteConfirmation(
      title: 'Delete Category',
      message: 'Are you sure you want to delete category "${cat.name}"? Documents tagged with this category may need reassignment.',
      onDelete: () async {
        await _dataset.deleteDocumentCategory(cat.id);
        AppSnackbar.showSuccess('Category Deleted', 'Category "${cat.name}" removed.');
        loadDocumentCategories();
      },
    );
  }

  // ================= SAVE PERSONAL PROFILE =================

  Future<void> saveProfile() async {
    final name = fullNameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.showWarning('Name Required', 'Please provide a valid full name.');
      return;
    }

    isLoading.value = true;
    try {
      await _dataset.updateProfile(
        fullName: name,
        department: departmentController.text.trim(),
        phoneNumber: phoneController.text.trim(),
      );
      AppSnackbar.showSuccess('Profile Saved', 'Your profile details have been updated.');
      loadProfile();
    } catch (e) {
      AppSnackbar.showError('Update Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ================= REUSABLE DIALOG & MODAL HELPERS =================

  Widget _buildDialogContainer({
    required String title,
    required IconData icon,
    required Widget content,
    required Future<void> Function() onConfirm,
    required String confirmButtonText,
    double maxWidth = 460,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: Get.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                    onPressed: () => Get.back(),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Inline Error Banner (Section 3.B: NEVER trigger floating snackbar while modal open)
              Obx(() {
                if (dialogErrorMessage.value.isEmpty) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dialogErrorMessage.value,
                          style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Content Body (Scrollable if needed)
              Flexible(
                child: SingleChildScrollView(
                  child: content,
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(() {
                    return ElevatedButton(
                      onPressed: isSubmitting.value ? null : onConfirm,
                      child: isSubmitting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(confirmButtonText),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation({
    required String title,
    required String message,
    required Future<void> Function() onDelete,
  }) {
    dialogErrorMessage.value = '';
    isSubmitting.value = false;

    AppDialog.show(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
        backgroundColor: AppColors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Inline Error if deletion fails
                Obx(() {
                  if (dialogErrorMessage.value.isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      dialogErrorMessage.value,
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  );
                }),

                Text(
                  message,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Obx(() {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isSubmitting.value
                            ? null
                            : () async {
                                isSubmitting.value = true;
                                dialogErrorMessage.value = '';
                                try {
                                  Get.back();
                                  await onDelete();
                                } catch (e) {
                                  AppSnackbar.showError('Delete Failed', e.toString());
                                } finally {
                                  isSubmitting.value = false;
                                }
                              },
                        child: isSubmitting.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Delete'),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    fullNameController.dispose();
    departmentController.dispose();
    phoneController.dispose();
    cityNameController.dispose();
    cityStateController.dispose();
    brandNameController.dispose();
    applianceCategoryNameController.dispose();
    applianceWarrantyMonthsController.dispose();
    utilityProviderNameController.dispose();
    personNameController.dispose();
    personPhoneController.dispose();
    personEmailController.dispose();
    docTypeNameController.dispose();
    docTypeCodeController.dispose();
    docCategoryNameController.dispose();
    docCategoryCodeController.dispose();
    docCategoryColorController.dispose();
    docCategoryDescController.dispose();
    super.onClose();
  }
}
