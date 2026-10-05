import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends GetxService {
  final AuthRepository _authRepository;

  AuthService(this._authRepository);

  static AuthService get to => Get.find<AuthService>();

  final currentProfile = Rxn<ProfileModel>();
  final isLoadingProfile = false.obs;
  final isDemoMode = false.obs;

  /// Flag to track whether the splash screen has finished resolving
  /// the initial session. Prevents the auth listener from firing
  /// premature redirects during startup.
  bool _initialSessionResolved = false;

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

  /// Called by SplashController once it has finished processing the
  /// initial session. After this, the auth listener is allowed to
  /// perform auto-redirects (e.g. redirect to login on sign-out).
  void markInitialSessionResolved() {
    _initialSessionResolved = true;
    AppLogger.debug(
      'AUTH_SERVICE',
      'Initial session resolution complete — auth redirects enabled.',
    );
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
      final event = data.event;
      final session = data.session;

      AppLogger.debug(
        'AUTH_SERVICE',
        'onAuthStateChange: event=$event, hasSession=${session != null}',
      );

      if (event == AuthChangeEvent.initialSession) {
        // Handled by SplashController — do not redirect here
        if (session != null) {
          loadProfile();
        }
        return;
      }

      if (session != null) {
        loadProfile();
      } else {
        currentProfile.value = null;
      }

      // Only redirect after the splash screen has finished its work
      if (!_initialSessionResolved) return;

      if (event == AuthChangeEvent.signedOut) {
        // Session expired or user signed out — redirect to login
        final currentRoute = Get.currentRoute;
        if (currentRoute != AppRoutes.LOGIN &&
            currentRoute != AppRoutes.SPLASH) {
          AppLogger.info(
            'AUTH_SERVICE',
            'Session lost — redirecting to login.',
          );
          Get.offAllNamed(AppRoutes.LOGIN);
        }
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
