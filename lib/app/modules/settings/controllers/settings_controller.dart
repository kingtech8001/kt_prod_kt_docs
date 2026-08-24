import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class SettingsController extends GetxController {
  final AuthRepository _authRepository;
  final MasterDataRepository _masterDataRepository;

  SettingsController(this._authRepository, this._masterDataRepository);

  final isLoading = false.obs;
  final profile = Rxn<ProfileModel>();
  final selectedTabIndex = 0.obs;

  // Personal Profile Controllers
  final fullNameController = TextEditingController();
  final departmentController = TextEditingController();
  final phoneController = TextEditingController();

  // Dynamic Master Data Observables
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

  // Staff Management
  final staffList = <ProfileModel>[].obs;
  final isStaffLoading = false.obs;

  // Modal Input Controllers
  final cityNameController = TextEditingController();
  final cityStateController = TextEditingController();

  final brandNameController = TextEditingController();
  final brandCategoryType = 'appliance'.obs;

  final applianceCategoryNameController = TextEditingController();
  final applianceWarrantyMonthsController = TextEditingController(text: '12');
  final applianceIconName = 'kitchen'.obs;

  final utilityProviderNameController = TextEditingController();
  final utilityTypeSelection = 'Electricity / Light'.obs;

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

  // New Staff Modal
  final newStaffEmailController = TextEditingController();
  final newStaffPasswordController = TextEditingController();
  final newStaffNameController = TextEditingController();
  final newStaffDeptController = TextEditingController();
  final newStaffPhoneController = TextEditingController();
  final newStaffRole = 'editor'.obs;

  bool get isAdmin => profile.value?.role == 'admin' || profile.value?.role == 'super_admin';

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    loadAllMasterData();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final p = await _authRepository.getCurrentProfile();
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
    loadCities();
    loadBrands();
    loadApplianceSubcategories();
    loadUtilityProviders();
    loadPersons();
    loadPersonalDocTypes();
    loadDocumentCategories();
    loadStaffList();
  }

  // ================= CITIES =================
  Future<void> loadCities() async {
    isCitiesLoading.value = true;
    try {
      final list = await _masterDataRepository.getCities(activeOnly: false);
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

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.location_city, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add New City', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('City Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: cityNameController,
                decoration: const InputDecoration(hintText: 'e.g. Ahmedabad, Surat, Mumbai'),
              ),
              const SizedBox(height: 12),
              const Text('State / Region', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: cityStateController,
                decoration: const InputDecoration(hintText: 'e.g. Gujarat, Maharashtra'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = cityNameController.text.trim();
              final state = cityStateController.text.trim().isNotEmpty ? cityStateController.text.trim() : 'Gujarat';
              if (name.isEmpty) return;

              Get.back();
              try {
                await _masterDataRepository.addCity(name: name, state: state);
                Get.snackbar('City Added', 'City "$name" added successfully.', backgroundColor: AppColors.success, colorText: Colors.white);
                loadCities();
              } catch (e) {
                Get.snackbar('Failed', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Add City'),
          ),
        ],
      ),
    );
  }

  Future<void> toggleCityActive(MasterCityModel city) async {
    try {
      await _masterDataRepository.updateCity(id: city.id, name: city.name, state: city.state, isActive: !city.isActive);
      loadCities();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> deleteCity(MasterCityModel city) async {
    try {
      await _masterDataRepository.deleteCity(city.id);
      Get.snackbar('City Removed', 'City "${city.name}" deleted.', backgroundColor: AppColors.success, colorText: Colors.white);
      loadCities();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ================= BRANDS =================
  Future<void> loadBrands() async {
    isBrandsLoading.value = true;
    try {
      final list = await _masterDataRepository.getBrands(activeOnly: false);
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

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.branding_watermark_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add New Brand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Brand Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: brandNameController,
                decoration: const InputDecoration(hintText: 'e.g. Havells, Crompton, Samsung'),
              ),
              const SizedBox(height: 12),
              const Text('Category Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
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
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = brandNameController.text.trim();
              if (name.isEmpty) return;

              Get.back();
              try {
                await _masterDataRepository.addBrand(name: name, categoryType: brandCategoryType.value);
                Get.snackbar('Brand Added', 'Brand "$name" added successfully.', backgroundColor: AppColors.success, colorText: Colors.white);
                loadBrands();
              } catch (e) {
                Get.snackbar('Failed', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Add Brand'),
          ),
        ],
      ),
    );
  }

  Future<void> toggleBrandActive(MasterBrandModel brand) async {
    try {
      await _masterDataRepository.updateBrand(id: brand.id, name: brand.name, categoryType: brand.categoryType, isActive: !brand.isActive);
      loadBrands();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> deleteBrand(MasterBrandModel brand) async {
    try {
      await _masterDataRepository.deleteBrand(brand.id);
      Get.snackbar('Brand Removed', 'Brand "${brand.name}" deleted.', backgroundColor: AppColors.success, colorText: Colors.white);
      loadBrands();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ================= APPLIANCE SUBCATEGORIES =================
  Future<void> loadApplianceSubcategories() async {
    isApplianceSubcategoriesLoading.value = true;
    try {
      final list = await _masterDataRepository.getApplianceSubcategories(activeOnly: false);
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

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.kitchen_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Appliance Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category / Item Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: applianceCategoryNameController,
                decoration: const InputDecoration(hintText: 'e.g. Ceiling Fan, Geyser, AC'),
              ),
              const SizedBox(height: 12),
              const Text('Default Warranty Duration (Months) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: applianceWarrantyMonthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '12 (1 year), 24 (2 years)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = applianceCategoryNameController.text.trim();
              final months = int.tryParse(applianceWarrantyMonthsController.text.trim()) ?? 12;
              if (name.isEmpty) return;

              Get.back();
              try {
                await _masterDataRepository.addApplianceSubcategory(name: name, defaultWarrantyMonths: months, iconName: applianceIconName.value);
                Get.snackbar('Category Added', 'Appliance category "$name" added.', backgroundColor: AppColors.success, colorText: Colors.white);
                loadApplianceSubcategories();
              } catch (e) {
                Get.snackbar('Failed', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Future<void> toggleApplianceSubcategoryActive(MasterApplianceSubcategoryModel sub) async {
    try {
      await _masterDataRepository.updateApplianceSubcategory(
        id: sub.id,
        name: sub.name,
        defaultWarrantyMonths: sub.defaultWarrantyMonths,
        iconName: sub.iconName,
        isActive: !sub.isActive,
      );
      loadApplianceSubcategories();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> deleteApplianceSubcategory(MasterApplianceSubcategoryModel sub) async {
    try {
      await _masterDataRepository.deleteApplianceSubcategory(sub.id);
      Get.snackbar('Category Removed', 'Category "${sub.name}" deleted.', backgroundColor: AppColors.success, colorText: Colors.white);
      loadApplianceSubcategories();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ================= UTILITY PROVIDERS =================
  Future<void> loadUtilityProviders() async {
    isUtilityProvidersLoading.value = true;
    try {
      final list = await _masterDataRepository.getUtilityProviders(activeOnly: false);
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

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.bolt_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Utility Provider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provider Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: utilityProviderNameController,
                decoration: const InputDecoration(hintText: 'e.g. Torrent Power, Adani Gas, DGVCL'),
              ),
              const SizedBox(height: 12),
              const Text('Utility Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
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
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = utilityProviderNameController.text.trim();
              if (name.isEmpty) return;

              Get.back();
              try {
                await _masterDataRepository.addUtilityProvider(name: name, utilityType: utilityTypeSelection.value);
                Get.snackbar('Provider Added', 'Utility provider "$name" added.', backgroundColor: AppColors.success, colorText: Colors.white);
                loadUtilityProviders();
              } catch (e) {
                Get.snackbar('Failed', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Add Provider'),
          ),
        ],
      ),
    );
  }

  Future<void> toggleUtilityProviderActive(MasterUtilityProviderModel provider) async {
    try {
      await _masterDataRepository.updateUtilityProvider(
        id: provider.id,
        name: provider.name,
        utilityType: provider.utilityType,
        isActive: !provider.isActive,
      );
      loadUtilityProviders();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> deleteUtilityProvider(MasterUtilityProviderModel provider) async {
    try {
      await _masterDataRepository.deleteUtilityProvider(provider.id);
      Get.snackbar('Provider Removed', 'Provider "${provider.name}" deleted.', backgroundColor: AppColors.success, colorText: Colors.white);
      loadUtilityProviders();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ================= PERSONS & BENEFICIARIES =================
  Future<void> loadPersons() async {
    isPersonsLoading.value = true;
    try {
      final list = await _masterDataRepository.getPersons(activeOnly: false);
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

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.person_add_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Person / Family Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: personNameController,
                decoration: const InputDecoration(hintText: 'e.g. Mihir Gandhi, Suresh Gandhi'),
              ),
              const SizedBox(height: 12),
              const Text('Relationship *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
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
                        const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
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
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = personNameController.text.trim();
              if (name.isEmpty) return;

              Get.back();
              try {
                await _masterDataRepository.addPerson(
                  fullName: name,
                  relationship: personRelationship.value,
                  phoneNumber: personPhoneController.text.trim().isNotEmpty ? personPhoneController.text.trim() : null,
                  email: personEmailController.text.trim().isNotEmpty ? personEmailController.text.trim() : null,
                );
                Get.snackbar('Person Added', 'Added "$name" to master persons list.', backgroundColor: AppColors.success, colorText: Colors.white);
                loadPersons();
              } catch (e) {
                Get.snackbar('Failed', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Add Person'),
          ),
        ],
      ),
    );
  }

  Future<void> togglePersonActive(MasterPersonModel person) async {
    try {
      await _masterDataRepository.updatePerson(
        id: person.id,
        fullName: person.fullName,
        relationship: person.relationship,
        dateOfBirth: person.dateOfBirth,
        phoneNumber: person.phoneNumber,
        email: person.email,
        isActive: !person.isActive,
      );
      loadPersons();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> deletePerson(MasterPersonModel person) async {
    try {
      await _masterDataRepository.deletePerson(person.id);
      Get.snackbar('Person Removed', 'Person "${person.fullName}" removed.', backgroundColor: AppColors.success, colorText: Colors.white);
      loadPersons();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ================= PERSONAL DOC TYPES =================
  Future<void> loadPersonalDocTypes() async {
    isPersonalDocTypesLoading.value = true;
    try {
      final list = await _masterDataRepository.getPersonalDocTypes(activeOnly: false);
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

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.badge_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Personal Document Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Document Type Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: docTypeNameController,
                decoration: const InputDecoration(hintText: 'e.g. Aadhaar Card, PAN Card, Passport'),
                onChanged: (val) {
                  if (docTypeCodeController.text.isEmpty || docTypeCodeController.text.startsWith(RegExp(r'[a-z_]+'))) {
                    docTypeCodeController.text = val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text('Internal System Code *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(
                controller: docTypeCodeController,
                decoration: const InputDecoration(hintText: 'e.g. aadhar, pan, voter_id, passport'),
              ),
              const SizedBox(height: 12),
              Obx(() => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Requires Expiry Date Tracking (e.g. Passport, Driving License)', style: TextStyle(fontSize: 13)),
                    value: docTypeHasExpiry.value,
                    onChanged: (val) {
                      if (val != null) docTypeHasExpiry.value = val;
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = docTypeNameController.text.trim();
              final code = docTypeCodeController.text.trim().toLowerCase();
              if (name.isEmpty || code.isEmpty) return;

              Get.back();
              try {
                await _masterDataRepository.addPersonalDocType(
                  name: name,
                  code: code,
                  hasExpiry: docTypeHasExpiry.value,
                );
                Get.snackbar('Doc Type Added', 'Document type "$name" added.', backgroundColor: AppColors.success, colorText: Colors.white);
                loadPersonalDocTypes();
              } catch (e) {
                Get.snackbar('Failed', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Add Document Type'),
          ),
        ],
      ),
    );
  }

  Future<void> togglePersonalDocTypeActive(MasterPersonalDocTypeModel type) async {
    try {
      await _masterDataRepository.updatePersonalDocType(
        id: type.id,
        name: type.name,
        code: type.code,
        iconName: type.iconName,
        hasExpiry: type.hasExpiry,
        isActive: !type.isActive,
      );
      loadPersonalDocTypes();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> deletePersonalDocType(MasterPersonalDocTypeModel type) async {
    try {
      await _masterDataRepository.deletePersonalDocType(type.id);
      Get.snackbar('Type Removed', 'Document type "${type.name}" deleted.', backgroundColor: AppColors.success, colorText: Colors.white);
      loadPersonalDocTypes();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ================= DOCUMENT CATEGORIES =================
  Future<void> loadDocumentCategories() async {
    isCategoriesLoading.value = true;
    try {
      final list = await _masterDataRepository.getDocumentCategories();
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

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.folder_special_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Corporate Document Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(controller: docCategoryNameController, decoration: const InputDecoration(hintText: 'e.g. Legal Agreements, HR Records')),
                const SizedBox(height: 12),
                const Text('Code Identifier *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(controller: docCategoryCodeController, decoration: const InputDecoration(hintText: 'e.g. legal_agreements, hr_docs')),
                const SizedBox(height: 12),
                const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(controller: docCategoryDescController, decoration: const InputDecoration(hintText: 'Brief description of category usage')),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Category Form Configuration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                const SizedBox(height: 8),
                Obx(() => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require City / Location Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('If enabled, users can assign a city and premise location during upload.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: docCategoryHasCityFilter.value,
                      onChanged: (val) => docCategoryHasCityFilter.value = val ?? true,
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
                Obx(() => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require Document Title Input', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('If disabled, the document title field is hidden and auto-derived from the uploaded file name.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: docCategoryHasTitleField.value,
                      onChanged: (val) => docCategoryHasTitleField.value = val ?? true,
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = docCategoryNameController.text.trim();
              final code = docCategoryCodeController.text.trim();
              if (name.isEmpty || code.isEmpty) return;

              Get.back();
              try {
                await _masterDataRepository.addDocumentCategory(
                  name: name,
                  code: code,
                  colorHex: docCategoryColorController.text.trim(),
                  description: docCategoryDescController.text.trim(),
                  hasCityFilter: docCategoryHasCityFilter.value,
                  hasTitleField: docCategoryHasTitleField.value,
                );
                Get.snackbar('Category Added', 'Document category "$name" created.', backgroundColor: AppColors.success, colorText: Colors.white);
                loadDocumentCategories();
              } catch (e) {
                Get.snackbar('Failed', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  void openEditDocumentCategoryDialog(CategoryModel cat) {
    docCategoryNameController.text = cat.name;
    docCategoryCodeController.text = cat.code;
    docCategoryColorController.text = cat.colorHex;
    docCategoryDescController.text = cat.description ?? '';
    docCategoryHasCityFilter.value = cat.hasCityFilter;
    docCategoryHasTitleField.value = cat.hasTitleField;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Edit Document Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(controller: docCategoryNameController, decoration: const InputDecoration(hintText: 'e.g. Legal Agreements, HR Records')),
                const SizedBox(height: 12),
                const Text('Code Identifier *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(controller: docCategoryCodeController, decoration: const InputDecoration(hintText: 'e.g. legal_agreements, hr_docs')),
                const SizedBox(height: 12),
                const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(controller: docCategoryDescController, decoration: const InputDecoration(hintText: 'Brief description of category usage')),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Category Form Configuration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                const SizedBox(height: 8),
                Obx(() => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require City / Location Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('If enabled, users can assign a city and premise location during upload.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: docCategoryHasCityFilter.value,
                      onChanged: (val) => docCategoryHasCityFilter.value = val ?? true,
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
                Obx(() => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require Document Title Input', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('If disabled, the document title field is hidden and auto-derived from the uploaded file name.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: docCategoryHasTitleField.value,
                      onChanged: (val) => docCategoryHasTitleField.value = val ?? true,
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = docCategoryNameController.text.trim();
              final code = docCategoryCodeController.text.trim();
              if (name.isEmpty || code.isEmpty) return;

              Get.back();
              try {
                await _masterDataRepository.updateDocumentCategory(
                  id: cat.id,
                  name: name,
                  code: code,
                  colorHex: docCategoryColorController.text.trim(),
                  description: docCategoryDescController.text.trim(),
                  hasCityFilter: docCategoryHasCityFilter.value,
                  hasTitleField: docCategoryHasTitleField.value,
                );
                Get.snackbar('Category Updated', 'Document category "$name" updated.', backgroundColor: AppColors.success, colorText: Colors.white);
                loadDocumentCategories();
              } catch (e) {
                Get.snackbar('Failed', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteDocumentCategory(CategoryModel cat) async {
    try {
      await _masterDataRepository.deleteDocumentCategory(cat.id);
      Get.snackbar('Category Deleted', 'Category "${cat.name}" removed.', backgroundColor: AppColors.success, colorText: Colors.white);
      loadDocumentCategories();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ================= STAFF MANAGEMENT =================
  Future<void> loadStaffList() async {
    isStaffLoading.value = true;
    try {
      final list = await _authRepository.adminGetAllStaffUsers();
      staffList.assignAll(list);
    } catch (e, st) {
      AppLogger.error('SETTINGS_CTRL', 'Error loading staff: $e', error: e, stackTrace: st);
    } finally {
      isStaffLoading.value = false;
    }
  }

  void openCreateStaffDialog() {
    newStaffEmailController.clear();
    newStaffPasswordController.clear();
    newStaffNameController.clear();
    newStaffDeptController.clear();
    newStaffPhoneController.clear();
    newStaffRole.value = 'editor';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Provision New Staff Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(controller: newStaffNameController, decoration: const InputDecoration(hintText: 'e.g. Rahul Sharma')),
                const SizedBox(height: 12),
                const Text('Work Email *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(controller: newStaffEmailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'user@kingtechnology.com')),
                const SizedBox(height: 12),
                const Text('Temporary Password *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(controller: newStaffPasswordController, decoration: const InputDecoration(hintText: 'Initial password for first login')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Department', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(controller: newStaffDeptController, decoration: const InputDecoration(hintText: 'Finance / IT / HR')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(controller: newStaffPhoneController, decoration: const InputDecoration(hintText: '+91 9876543210')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Assigned Role & Permissions *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Obx(() => DropdownButtonFormField<String>(
                      value: newStaffRole.value,
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin (Full management & deletions)')),
                        DropdownMenuItem(value: 'editor', child: Text('Editor (Upload, Edit, Download — No Delete)')),
                        DropdownMenuItem(value: 'viewer', child: Text('Viewer (Read-only Preview & Download)')),
                        DropdownMenuItem(value: 'user', child: Text('Standard Staff User')),
                      ],
                      onChanged: (val) {
                        if (val != null) newStaffRole.value = val;
                      },
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = newStaffEmailController.text.trim();
              final password = newStaffPasswordController.text.trim();
              final name = newStaffNameController.text.trim();

              if (email.isEmpty || password.isEmpty || name.isEmpty) {
                Get.snackbar('Missing Info', 'Please enter Name, Email, and Password.', backgroundColor: AppColors.warning, colorText: Colors.white);
                return;
              }

              Get.back();
              isLoading.value = true;
              try {
                await _authRepository.adminCreateStaffUser(
                  email: email,
                  password: password,
                  fullName: name,
                  role: newStaffRole.value,
                  department: newStaffDeptController.text.trim(),
                  phoneNumber: newStaffPhoneController.text.trim(),
                );

                Get.snackbar('Staff Created', 'Staff profile for $name successfully registered.', backgroundColor: AppColors.success, colorText: Colors.white);
                loadStaffList();
              } catch (e) {
                Get.snackbar('Failed', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
              } finally {
                isLoading.value = false;
              }
            },
            child: const Text('Provision Profile'),
          ),
        ],
      ),
    );
  }

  Future<void> toggleStaffActive(ProfileModel staff) async {
    try {
      await _authRepository.adminUpdateUserRole(
        targetUserId: staff.id,
        role: staff.role,
        isActive: !staff.isActive,
      );
      Get.snackbar('Updated', 'Staff status updated.', backgroundColor: AppColors.success, colorText: Colors.white);
      loadStaffList();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> updateStaffRole(ProfileModel staff, String newRole) async {
    try {
      await _authRepository.adminUpdateUserRole(
        targetUserId: staff.id,
        role: newRole,
        isActive: staff.isActive,
      );
      Get.snackbar('Role Updated', '${staff.fullName} assigned role: $newRole', backgroundColor: AppColors.success, colorText: Colors.white);
      loadStaffList();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  // ================= SAVE PERSONAL PROFILE =================
  Future<void> saveProfile() async {
    final name = fullNameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Name Required', 'Please provide a valid full name.', backgroundColor: AppColors.warning, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      await _authRepository.updateProfile(
        fullName: name,
        department: departmentController.text.trim(),
        phoneNumber: phoneController.text.trim(),
      );
      Get.snackbar('Profile Saved', 'Your profile details have been saved.', backgroundColor: AppColors.success, colorText: Colors.white);
      loadProfile();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
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
    newStaffEmailController.dispose();
    newStaffPasswordController.dispose();
    newStaffNameController.dispose();
    newStaffDeptController.dispose();
    newStaffPhoneController.dispose();
    super.onClose();
  }
}
