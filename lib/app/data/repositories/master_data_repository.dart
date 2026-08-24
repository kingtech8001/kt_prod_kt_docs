import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';

class MasterDataRepository {
  final SupabaseProvider _provider;

  MasterDataRepository(this._provider);

  // ================= CITIES =================
  Future<List<MasterCityModel>> getCities({bool activeOnly = false}) async {
    AppLogger.debug('MASTER_DATA_REPO', 'Fetching cities (activeOnly: $activeOnly)');
    try {
      var query = _provider.client.from('master_cities').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('display_order', ascending: true).order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterCityModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error fetching cities: $e', error: e, stackTrace: st);
      return [];
    }
  }

  Future<MasterCityModel> addCity({required String name, String state = 'Gujarat'}) async {
    AppLogger.debug('MASTER_DATA_REPO', 'Adding city: $name, $state');
    try {
      final response = await _provider.client
          .from('master_cities')
          .insert({'name': name, 'state': state, 'is_active': true})
          .select()
          .single();
      return MasterCityModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error adding city: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateCity({required String id, required String name, required String state, required bool isActive}) async {
    try {
      await _provider.client.from('master_cities').update({
        'name': name,
        'state': state,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error updating city: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteCity(String id) async {
    try {
      await _provider.client.from('master_cities').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error deleting city: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= BRANDS =================
  Future<List<MasterBrandModel>> getBrands({bool activeOnly = false}) async {
    AppLogger.debug('MASTER_DATA_REPO', 'Fetching brands (activeOnly: $activeOnly)');
    try {
      var query = _provider.client.from('master_brands').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('display_order', ascending: true).order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterBrandModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error fetching brands: $e', error: e, stackTrace: st);
      return [];
    }
  }

  Future<MasterBrandModel> addBrand({required String name, String categoryType = 'appliance'}) async {
    AppLogger.debug('MASTER_DATA_REPO', 'Adding brand: $name ($categoryType)');
    try {
      final response = await _provider.client
          .from('master_brands')
          .insert({'name': name, 'category_type': categoryType, 'is_active': true})
          .select()
          .single();
      return MasterBrandModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error adding brand: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateBrand({required String id, required String name, required String categoryType, required bool isActive}) async {
    try {
      await _provider.client.from('master_brands').update({
        'name': name,
        'category_type': categoryType,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error updating brand: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteBrand(String id) async {
    try {
      await _provider.client.from('master_brands').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error deleting brand: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= APPLIANCE SUBCATEGORIES =================
  Future<List<MasterApplianceSubcategoryModel>> getApplianceSubcategories({bool activeOnly = false}) async {
    AppLogger.debug('MASTER_DATA_REPO', 'Fetching appliance subcategories...');
    try {
      var query = _provider.client.from('master_appliance_subcategories').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('display_order', ascending: true).order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterApplianceSubcategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error fetching appliance subcategories: $e', error: e, stackTrace: st);
      return [];
    }
  }

  Future<MasterApplianceSubcategoryModel> addApplianceSubcategory({
    required String name,
    int defaultWarrantyMonths = 12,
    String iconName = 'kitchen',
  }) async {
    try {
      final response = await _provider.client
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
      AppLogger.error('MASTER_DATA_REPO', 'Error adding appliance subcategory: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateApplianceSubcategory({
    required String id,
    required String name,
    required int defaultWarrantyMonths,
    required String iconName,
    required bool isActive,
  }) async {
    try {
      await _provider.client.from('master_appliance_subcategories').update({
        'name': name,
        'default_warranty_months': defaultWarrantyMonths,
        'icon_name': iconName,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error updating appliance subcategory: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteApplianceSubcategory(String id) async {
    try {
      await _provider.client.from('master_appliance_subcategories').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error deleting appliance subcategory: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= UTILITY PROVIDERS =================
  Future<List<MasterUtilityProviderModel>> getUtilityProviders({bool activeOnly = false}) async {
    AppLogger.debug('MASTER_DATA_REPO', 'Fetching utility providers...');
    try {
      var query = _provider.client.from('master_utility_providers').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('display_order', ascending: true).order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterUtilityProviderModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error fetching utility providers: $e', error: e, stackTrace: st);
      return [];
    }
  }

  Future<MasterUtilityProviderModel> addUtilityProvider({
    required String name,
    required String utilityType,
  }) async {
    try {
      final response = await _provider.client
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
      AppLogger.error('MASTER_DATA_REPO', 'Error adding utility provider: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateUtilityProvider({
    required String id,
    required String name,
    required String utilityType,
    required bool isActive,
  }) async {
    try {
      await _provider.client.from('master_utility_providers').update({
        'name': name,
        'utility_type': utilityType,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error updating utility provider: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteUtilityProvider(String id) async {
    try {
      await _provider.client.from('master_utility_providers').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error deleting utility provider: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= PERSONS & BENEFICIARIES =================
  Future<List<MasterPersonModel>> getPersons({bool activeOnly = false}) async {
    AppLogger.debug('MASTER_DATA_REPO', 'Fetching persons (activeOnly: $activeOnly)');
    try {
      var query = _provider.client.from('master_persons').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('display_order', ascending: true).order('full_name', ascending: true);
      final list = (response as List)
          .map((json) => MasterPersonModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error fetching persons: $e', error: e, stackTrace: st);
      return [];
    }
  }

  Future<MasterPersonModel> addPerson({
    required String fullName,
    String relationship = 'Self',
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? email,
  }) async {
    AppLogger.debug('MASTER_DATA_REPO', 'Adding person: $fullName ($relationship)');
    try {
      final response = await _provider.client
          .from('master_persons')
          .insert({
            'full_name': fullName,
            'relationship': relationship,
            if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
            'phone_number': phoneNumber,
            'email': email,
            'is_active': true,
          })
          .select()
          .single();
      return MasterPersonModel.fromJson(response);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error adding person: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updatePerson({
    required String id,
    required String fullName,
    required String relationship,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? email,
    required bool isActive,
  }) async {
    try {
      await _provider.client.from('master_persons').update({
        'full_name': fullName,
        'relationship': relationship,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'phone_number': phoneNumber,
        'email': email,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error updating person: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deletePerson(String id) async {
    try {
      await _provider.client.from('master_persons').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error deleting person: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= PERSONAL DOCUMENT TYPES =================
  Future<List<MasterPersonalDocTypeModel>> getPersonalDocTypes({bool activeOnly = false}) async {
    AppLogger.debug('MASTER_DATA_REPO', 'Fetching personal document types...');
    try {
      var query = _provider.client.from('master_personal_doc_types').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('display_order', ascending: true).order('name', ascending: true);
      final list = (response as List)
          .map((json) => MasterPersonalDocTypeModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error fetching personal doc types: $e', error: e, stackTrace: st);
      return [];
    }
  }

  Future<MasterPersonalDocTypeModel> addPersonalDocType({
    required String name,
    required String code,
    String iconName = 'badge',
    bool hasExpiry = false,
  }) async {
    try {
      final response = await _provider.client
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
      AppLogger.error('MASTER_DATA_REPO', 'Error adding personal doc type: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updatePersonalDocType({
    required String id,
    required String name,
    required String code,
    required String iconName,
    required bool hasExpiry,
    required bool isActive,
  }) async {
    try {
      await _provider.client.from('master_personal_doc_types').update({
        'name': name,
        'code': code,
        'icon_name': iconName,
        'has_expiry': hasExpiry,
        'is_active': isActive,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error updating personal doc type: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deletePersonalDocType(String id) async {
    try {
      await _provider.client.from('master_personal_doc_types').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error deleting personal doc type: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ================= DOCUMENT CATEGORIES =================
  Future<List<CategoryModel>> getDocumentCategories() async {
    AppLogger.debug('MASTER_DATA_REPO', 'Fetching document categories...');
    try {
      final response = await _provider.client
          .from('document_categories')
          .select()
          .order('name', ascending: true);
      final list = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error fetching categories: $e', error: e, stackTrace: st);
      return [];
    }
  }

  Future<CategoryModel> addDocumentCategory({
    required String name,
    required String code,
    String? icon,
    String? colorHex,
    String? description,
    bool hasCityFilter = true,
    bool hasTitleField = true,
  }) async {
    try {
      final response = await _provider.client
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
      AppLogger.error('MASTER_DATA_REPO', 'Error adding document category: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

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
    try {
      await _provider.client.from('document_categories').update({
        'name': name,
        'code': code,
        'icon': icon ?? 'folder',
        'color_hex': colorHex ?? '#1E3A8A',
        'description': description,
        'has_city_filter': hasCityFilter,
        'has_title_field': hasTitleField,
      }).eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error updating document category: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteDocumentCategory(String id) async {
    try {
      await _provider.client.from('document_categories').delete().eq('id', id);
    } catch (e, st) {
      AppLogger.error('MASTER_DATA_REPO', 'Error deleting category: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}
