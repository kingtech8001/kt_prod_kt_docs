import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends GetxService {
  final AuthRepository _authRepository;

  AuthService(this._authRepository);

  static AuthService get to => Get.find<AuthService>();

  final currentProfile = Rxn<ProfileModel>();
  final isLoadingProfile = false.obs;
  final isDemoMode = false.obs;

  bool get isAuthenticated =>
      isDemoMode.value || Supabase.instance.client.auth.currentUser != null;

  bool get isAdmin {
    if (isDemoMode.value) return true;
    final role = currentProfile.value?.role.toLowerCase();
    if (role == 'admin' || role == 'super_admin') return true;
    // Check fallback user metadata if database profile is still loading
    final user = Supabase.instance.client.auth.currentUser;
    final metaRole = user?.userMetadata?['role']?.toString().toLowerCase();
    return metaRole == 'admin' || metaRole == 'super_admin';
  }

  bool get isSuperAdmin {
    if (isDemoMode.value) return false;
    return currentProfile.value?.role.toLowerCase() == 'super_admin';
  }

  void enterDemoMode() {
    isDemoMode.value = true;
    currentProfile.value = ProfileModel(
      id: 'demo-admin-id',
      fullName: 'Demo Administrator (Mihir)',
      email: 'demo@kingtechnology.com',
      role: 'admin',
      department: 'Technology (Demo)',
      isActive: true,
      createdAt: DateTime.now(),
    );
    AppLogger.info('AUTH_SERVICE', 'Entered Demo Mode with in-memory Profile.');
  }

  void exitDemoMode() {
    isDemoMode.value = false;
    currentProfile.value = null;
    AppLogger.info('AUTH_SERVICE', 'Exited Demo Mode.');
  }

  String get userRoleDisplay {
    if (currentProfile.value != null) {
      return currentProfile.value!.role.toUpperCase();
    }
    final user = Supabase.instance.client.auth.currentUser;
    final metaRole = user?.userMetadata?['role']?.toString().toUpperCase();
    return metaRole ?? 'ADMIN';
  }

  String get userName {
    if (currentProfile.value != null && currentProfile.value!.fullName.isNotEmpty) {
      return currentProfile.value!.fullName;
    }
    final user = Supabase.instance.client.auth.currentUser;
    final metaName = user?.userMetadata?['full_name']?.toString();
    if (metaName != null && metaName.isNotEmpty) return metaName;
    return user?.email?.split('@').first ?? 'Admin';
  }

  @override
  void onInit() {
    super.onInit();
    _initAuthListener();
    if (isAuthenticated) {
      loadProfile();
    }
  }

  void _initAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        loadProfile();
      } else {
        currentProfile.value = null;
      }
    });
  }

  Future<void> loadProfile() async {
    if (isDemoMode.value) return;
    if (!isAuthenticated) return;
    isLoadingProfile.value = true;
    try {
      AppLogger.debug('AUTH_SERVICE', 'Hydrating current user profile from database...');
      final profile = await _authRepository.getCurrentProfile();
      if (profile != null) {
        currentProfile.value = profile;
        AppLogger.info(
          'AUTH_SERVICE',
          'User profile loaded: ${profile.fullName} (role: ${profile.role})',
        );
      }
    } catch (e, st) {
      AppLogger.error('AUTH_SERVICE', 'Error hydrating profile: $e', error: e, stackTrace: st);
    } finally {
      isLoadingProfile.value = false;
    }
  }

  void updateProfile(ProfileModel updated) {
    currentProfile.value = updated;
  }
}
