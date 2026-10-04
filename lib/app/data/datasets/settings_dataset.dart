import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dataset responsible for Settings & Master Data operations.
/// Strictly conforms to the 3-tier architecture: View -> Controller -> Dataset -> Supabase.
class SettingsDataset {
  final SupabaseProvider _provider;

  SettingsDataset(this._provider);

  SupabaseClient get _client => _provider.client;

  // ================= PROFILE OPERATIONS =================

  /// Fetches profile for the currently authenticated session.
  Future<ProfileModel?> getCurrentProfile() async {
    if (DemoDataService.isDemoMode) {
      return ProfileModel(
        id: 'demo-user-id',
        fullName: 'Demo Administrator',
        email: 'demo@kt-docs.internal',
        role: 'admin',
        department: 'Operations & IT',
        phoneNumber: '+91 98765 43210',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      );
    }
    final user = _provider.currentUser;
    if (user == null) return null;

    AppLogger.debug('SETTINGS_DATASET', 'Fetching current profile for ${user.id}');
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return ProfileModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error(
        'SETTINGS_DATASET',
        'Error fetching current profile: $e',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Updates profile metadata for the currently authenticated session.
  Future<void> updateProfile({
    required String fullName,
    String? department,
    String? phoneNumber,
  }) async {
    if (DemoDataService.isDemoMode) {
      AppLogger.info('SETTINGS_DATASET', 'Demo Mode: Updated profile');
      return;
    }
    final user = _provider.currentUser;
    if (user == null) throw Exception('No authenticated user session found.');

    AppLogger.debug('SETTINGS_DATASET', 'Updating profile for ${user.id}');
    try {
      await _client.from('profiles').update({
        'full_name': fullName,
        if (department != null) 'department': department,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e, st) {
      AppLogger.error(
        'SETTINGS_DATASET',
        'Error updating profile: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ================= CITIES & LOCATIONS =================

  /// Fetches list of cities.
  Future<List<MasterCityModel>> getCities({bool activeOnly = false}) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getCities();
    }
    AppLogger.debug('SETTINGS_DATASET', 'Fetching cities (activeOnly: $activeOnly)');
    try {
      var query = _client.from('master_cities').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterCityModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error fetching cities: $e', error: e, stackTrace: st);
      return [];
    }
  }

  /// Adds a new city record.
  Future<MasterCityModel> addCity({required String name, String state = 'Gujarat'}) async {
    if (DemoDataService.isDemoMode) {
      return MasterCityModel(id: 'city-demo-${name.toLowerCase()}', name: name, state: state, isActive: true);
    }
    AppLogger.debug('SETTINGS_DATASET', 'Adding city: $name, $state');
    try {
      final response = await _client
          .from('master_cities')
          .insert({'name': name, 'state': state, 'is_active': true})
          .select()
          .single();
      return MasterCityModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error adding city: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates an existing city record.
  Future<void> updateCity({
    required String id,
    required String name,
    required String state,
    required bool isActive,
  }) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Updating city: $id');
    try {
      await _client.from('master_cities').update({
        'name': name,
        'state': state,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error updating city: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a city record.
  Future<void> deleteCity(String id) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Deleting city: $id');
    try {
      await _client.from('master_cities').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error deleting city: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= BRANDS =================

  /// Fetches list of appliance & equipment brands.
  Future<List<MasterBrandModel>> getBrands({bool activeOnly = false}) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getBrands();
    }
    AppLogger.debug('SETTINGS_DATASET', 'Fetching brands (activeOnly: $activeOnly)');
    try {
      var query = _client.from('master_brands').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterBrandModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error fetching brands: $e', error: e, stackTrace: st);
      return [];
    }
  }

  /// Adds a new brand record.
  Future<MasterBrandModel> addBrand({
    required String name,
    String categoryType = 'appliance',
  }) async {
    if (DemoDataService.isDemoMode) {
      return MasterBrandModel(id: 'brand-demo-${name.toLowerCase()}', name: name, categoryType: categoryType, isActive: true);
    }
    AppLogger.debug('SETTINGS_DATASET', 'Adding brand: $name ($categoryType)');
    try {
      final response = await _client
          .from('master_brands')
          .insert({'name': name, 'category_type': categoryType, 'is_active': true})
          .select()
          .single();
      return MasterBrandModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error adding brand: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates an existing brand.
  Future<void> updateBrand({
    required String id,
    required String name,
    required String categoryType,
    required bool isActive,
  }) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Updating brand: $id');
    try {
      await _client.from('master_brands').update({
        'name': name,
        'category_type': categoryType,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error updating brand: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a brand.
  Future<void> deleteBrand(String id) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Deleting brand: $id');
    try {
      await _client.from('master_brands').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error deleting brand: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= APPLIANCE SUBCATEGORIES =================

  /// Fetches appliance subcategories.
  Future<List<MasterApplianceSubcategoryModel>> getApplianceSubcategories({
    bool activeOnly = false,
  }) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getApplianceSubcategories();
    }
    AppLogger.debug('SETTINGS_DATASET', 'Fetching appliance subcategories...');
    try {
      var query = _client.from('master_appliance_subcategories').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterApplianceSubcategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error(
        'SETTINGS_DATASET',
        'Error fetching appliance subcategories: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Adds an appliance subcategory.
  Future<MasterApplianceSubcategoryModel> addApplianceSubcategory({
    required String name,
    int defaultWarrantyMonths = 12,
    String iconName = 'kitchen',
  }) async {
    if (DemoDataService.isDemoMode) {
      return MasterApplianceSubcategoryModel(id: 'app-sub-${name.toLowerCase()}', name: name, defaultWarrantyMonths: defaultWarrantyMonths, iconName: iconName, isActive: true);
    }
    AppLogger.debug('SETTINGS_DATASET', 'Adding appliance subcategory: $name');
    try {
      final response = await _client
          .from('master_appliance_subcategories')
          .insert({
            'name': name,
            'default_warranty_months': defaultWarrantyMonths,
            'icon_name': iconName,
            'is_active': true,
          })
          .select()
          .single();
      return MasterApplianceSubcategoryModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error(
        'SETTINGS_DATASET',
        'Error adding appliance subcategory: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates an appliance subcategory.
  Future<void> updateApplianceSubcategory({
    required String id,
    required String name,
    required int defaultWarrantyMonths,
    required String iconName,
    required bool isActive,
  }) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Updating appliance subcategory: $id');
    try {
      await _client.from('master_appliance_subcategories').update({
        'name': name,
        'default_warranty_months': defaultWarrantyMonths,
        'icon_name': iconName,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error(
        'SETTINGS_DATASET',
        'Error updating appliance subcategory: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Deletes an appliance subcategory.
  Future<void> deleteApplianceSubcategory(String id) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Deleting appliance subcategory: $id');
    try {
      await _client.from('master_appliance_subcategories').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error(
        'SETTINGS_DATASET',
        'Error deleting appliance subcategory: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ================= UTILITY PROVIDERS =================

  /// Fetches utility providers.
  Future<List<MasterUtilityProviderModel>> getUtilityProviders({
    bool activeOnly = false,
  }) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getUtilityProviders();
    }
    AppLogger.debug('SETTINGS_DATASET', 'Fetching utility providers...');
    try {
      var query = _client.from('master_utility_providers').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterUtilityProviderModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error fetching utility providers: $e', error: e, stackTrace: st);
      return [];
    }
  }

  /// Adds a utility provider.
  Future<MasterUtilityProviderModel> addUtilityProvider({
    required String name,
    required String utilityType,
  }) async {
    if (DemoDataService.isDemoMode) {
      return MasterUtilityProviderModel(id: 'util-prov-${name.toLowerCase()}', name: name, utilityType: utilityType, isActive: true);
    }
    AppLogger.debug('SETTINGS_DATASET', 'Adding utility provider: $name');
    try {
      final response = await _client
          .from('master_utility_providers')
          .insert({
            'name': name,
            'utility_type': utilityType,
            'is_active': true,
          })
          .select()
          .single();
      return MasterUtilityProviderModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error adding utility provider: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates a utility provider.
  Future<void> updateUtilityProvider({
    required String id,
    required String name,
    required String utilityType,
    required bool isActive,
  }) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Updating utility provider: $id');
    try {
      await _client.from('master_utility_providers').update({
        'name': name,
        'utility_type': utilityType,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error updating utility provider: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a utility provider.
  Future<void> deleteUtilityProvider(String id) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Deleting utility provider: $id');
    try {
      await _client.from('master_utility_providers').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error deleting utility provider: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= PERSONS & BENEFICIARIES =================

  /// Fetches master persons.
  Future<List<MasterPersonModel>> getPersons({bool activeOnly = false}) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getPersons();
    }
    AppLogger.debug('SETTINGS_DATASET', 'Fetching persons (activeOnly: $activeOnly)');
    try {
      var query = _client.from('master_persons').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('full_name', ascending: true);
      final list = (response as List)
          .map((json) => MasterPersonModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error fetching persons: $e', error: e, stackTrace: st);
      return [];
    }
  }

  /// Adds a person.
  Future<MasterPersonModel> addPerson({
    required String fullName,
    String relationship = 'Self',
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? email,
  }) async {
    if (DemoDataService.isDemoMode) {
      return MasterPersonModel(
        id: 'person-demo-${fullName.toLowerCase()}',
        fullName: fullName,
        relationship: relationship,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
        email: email,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    AppLogger.debug('SETTINGS_DATASET', 'Adding person: $fullName ($relationship)');
    try {
      final response = await _client
          .from('master_persons')
          .insert({
            'full_name': fullName,
            'relationship': relationship,
            if (dateOfBirth != null)
              'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
            'phone_number': phoneNumber,
            'email': email,
            'is_active': true,
          })
          .select()
          .single();
      return MasterPersonModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error adding person: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates a person.
  Future<void> updatePerson({
    required String id,
    required String fullName,
    required String relationship,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? email,
    required bool isActive,
  }) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Updating person: $id');
    try {
      await _client.from('master_persons').update({
        'full_name': fullName,
        'relationship': relationship,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'phone_number': phoneNumber,
        'email': email,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error updating person: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a person.
  Future<void> deletePerson(String id) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Deleting person: $id');
    try {
      await _client.from('master_persons').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error deleting person: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= PERSONAL DOCUMENT TYPES =================

  /// Fetches personal document types.
  Future<List<MasterPersonalDocTypeModel>> getPersonalDocTypes({
    bool activeOnly = false,
  }) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getPersonalDocTypes();
    }
    AppLogger.debug('SETTINGS_DATASET', 'Fetching personal document types...');
    try {
      var query = _client.from('master_personal_doc_types').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterPersonalDocTypeModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error fetching personal doc types: $e', error: e, stackTrace: st);
      return [];
    }
  }

  /// Adds a personal document type.
  Future<MasterPersonalDocTypeModel> addPersonalDocType({
    required String name,
    required String code,
    String iconName = 'badge',
    bool hasExpiry = false,
  }) async {
    if (DemoDataService.isDemoMode) {
      return MasterPersonalDocTypeModel(
        id: 'doc-type-${code.toLowerCase()}',
        name: name,
        code: code,
        iconName: iconName,
        hasExpiry: hasExpiry,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }
    AppLogger.debug('SETTINGS_DATASET', 'Adding personal doc type: $name ($code)');
    try {
      final response = await _client
          .from('master_personal_doc_types')
          .insert({
            'name': name,
            'code': code,
            'icon_name': iconName,
            'has_expiry': hasExpiry,
            'is_active': true,
          })
          .select()
          .single();
      return MasterPersonalDocTypeModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error adding personal doc type: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates a personal document type.
  Future<void> updatePersonalDocType({
    required String id,
    required String name,
    required String code,
    required String iconName,
    required bool hasExpiry,
    required bool isActive,
  }) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Updating personal doc type: $id');
    try {
      await _client.from('master_personal_doc_types').update({
        'name': name,
        'code': code,
        'icon_name': iconName,
        'has_expiry': hasExpiry,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error updating personal doc type: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a personal document type.
  Future<void> deletePersonalDocType(String id) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Deleting personal doc type: $id');
    try {
      await _client.from('master_personal_doc_types').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error deleting personal doc type: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= DOCUMENT CATEGORIES =================

  /// Fetches corporate document categories.
  Future<List<CategoryModel>> getDocumentCategories() async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getCategories();
    }
    AppLogger.debug('SETTINGS_DATASET', 'Fetching document categories...');
    try {
      final response = await _client
          .from('document_categories')
          .select()
          .order('name', ascending: true);
      final list = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error fetching categories: $e', error: e, stackTrace: st);
      return [];
    }
  }

  /// Adds a corporate document category.
  Future<CategoryModel> addDocumentCategory({
    required String name,
    required String code,
    String? icon,
    String? colorHex,
    String? description,
    bool hasCityFilter = true,
    bool hasTitleField = true,
  }) async {
    if (DemoDataService.isDemoMode) {
      return CategoryModel(
        id: 'cat-demo-${code.toLowerCase()}',
        name: name,
        code: code,
        icon: icon ?? 'folder',
        colorHex: colorHex ?? '#1E3A8A',
        description: description,
        hasCityFilter: hasCityFilter,
        hasTitleField: hasTitleField,
      );
    }
    AppLogger.debug('SETTINGS_DATASET', 'Adding corporate category: $name ($code)');
    try {
      final response = await _client
          .from('document_categories')
          .insert({
            'name': name,
            'code': code,
            'icon': icon ?? 'folder',
            'color_hex': colorHex ?? '#1E3A8A',
            'description': description,
            'has_city_filter': hasCityFilter,
            'has_title_field': hasTitleField,
          })
          .select()
          .single();
      return CategoryModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error adding document category: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates a corporate document category.
  Future<void> updateDocumentCategory({
    required String id,
    required String name,
    required String code,
    String? icon,
    String? colorHex,
    String? description,
    required bool hasCityFilter,
    required bool hasTitleField,
  }) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Updating corporate category: $id');
    try {
      await _client.from('document_categories').update({
        'name': name,
        'code': code,
        'icon': icon ?? 'folder',
        'color_hex': colorHex ?? '#1E3A8A',
        'description': description,
        'has_city_filter': hasCityFilter,
        'has_title_field': hasTitleField,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error updating document category: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a corporate document category.
  Future<void> deleteDocumentCategory(String id) async {
    if (DemoDataService.isDemoMode) return;
    AppLogger.debug('SETTINGS_DATASET', 'Deleting corporate category: $id');
    try {
      await _client.from('document_categories').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error deleting category: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= VEHICLE OPERATIONS =================

  /// Fetches registered master vehicles.
  Future<List<MasterVehicleModel>> getVehicles({bool activeOnly = true}) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getVehicles();
    }
    try {
      var query = _client.from('master_vehicles').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('vehicle_number', ascending: true);
      return (response as List)
          .map((json) => MasterVehicleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error fetching vehicles: $e', error: e, stackTrace: st);
      return [];
    }
  }

  /// Fetches master vehicle document types.
  Future<List<MasterVehicleDocTypeModel>> getVehicleDocTypes({bool activeOnly = true}) async {
    if (DemoDataService.isDemoMode) {
      return DemoDataService.getVehicleDocTypes();
    }
    try {
      var query = _client.from('master_vehicle_doc_types').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query
          .order('display_order', ascending: true)
          .order('name', ascending: true);
      return (response as List)
          .map((json) => MasterVehicleDocTypeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('SETTINGS_DATASET', 'Error fetching vehicle doc types: $e', error: e, stackTrace: st);
      return [];
    }
  }
}
