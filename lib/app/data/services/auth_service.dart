import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/profile_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends GetxService {
  final AuthRepository _authRepository;
  final bool _initialDemoMode;

  AuthService(this._authRepository, {bool initialDemoMode = false})
      : _initialDemoMode = initialDemoMode;

  static AuthService get to => Get.find<AuthService>();

  final currentProfile = Rxn<ProfileModel>();
  final isLoadingProfile = false.obs;
  late final isDemoMode = _initialDemoMode.obs;

  /// Flag to track whether initial session resolution is complete.
  /// Starts false to avoid hijacking route resolution during initial app mount.
  bool _initialSessionResolved = false;

  bool get isAuthenticated {
    if (isDemoMode.value) return true;
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  bool get isAdmin {
    if (isDemoMode.value) return true;
    final role = currentProfile.value?.role.toLowerCase();
    if (role == 'admin' || role == 'super_admin') return true;
    // Check fallback user metadata if database profile is still loading
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final metaRole = user?.userMetadata?['role']?.toString().toLowerCase();
      return metaRole == 'admin' || metaRole == 'super_admin';
    } catch (_) {
      return false;
    }
  }

  bool get isSuperAdmin {
    if (isDemoMode.value) return false;
    return currentProfile.value?.role.toLowerCase() == 'super_admin';
  }

  void enterDemoMode({bool persist = true}) {
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
    if (persist) {
      SharedPreferences.getInstance().then((p) => p.setBool('kt_demo_mode', true)).catchError((_) => false);
    }
    AppLogger.info('AUTH_SERVICE', 'Entered Demo Mode with in-memory Profile.');
  }

  void exitDemoMode() {
    isDemoMode.value = false;
    currentProfile.value = null;
    SharedPreferences.getInstance().then((p) => p.remove('kt_demo_mode')).catchError((_) => false);
    AppLogger.info('AUTH_SERVICE', 'Exited Demo Mode.');
  }

  String get userRoleDisplay {
    if (currentProfile.value != null) {
      return currentProfile.value!.role.toUpperCase();
    }
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final metaRole = user?.userMetadata?['role']?.toString().toUpperCase();
      return metaRole ?? 'ADMIN';
    } catch (_) {
      return 'ADMIN';
    }
  }

  String get userName {
    if (currentProfile.value != null && currentProfile.value!.fullName.isNotEmpty) {
      return currentProfile.value!.fullName;
    }
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final metaName = user?.userMetadata?['full_name']?.toString();
      if (metaName != null && metaName.isNotEmpty) return metaName;
      return user?.email?.split('@').first ?? 'Admin';
    } catch (_) {
      return 'Admin';
    }
  }

  /// Mark initial session resolution complete.
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
    if (_initialDemoMode) {
      enterDemoMode(persist: false);
    }
    _initAuthListener();
    if (isAuthenticated && !isDemoMode.value) {
      loadProfile();
    }
  }

  void _initAuthListener() {
    // Only allow sign-out redirects AFTER initial frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialSessionResolved = true;
    });

    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final session = data.session;

        AppLogger.debug(
          'AUTH_SERVICE',
          'onAuthStateChange: event=$event, hasSession=${session != null}',
        );

        if (event == AuthChangeEvent.initialSession) {
          if (session != null && !isDemoMode.value) {
            loadProfile();
          }
          return;
        }

        if (session != null) {
          if (!isDemoMode.value) {
            loadProfile();
          }
        } else {
          if (!isDemoMode.value) {
            currentProfile.value = null;
          }
        }

        if (!_initialSessionResolved) return;

        if (event == AuthChangeEvent.signedOut) {
          if (!isDemoMode.value) {
            final currentRoute = Get.currentRoute;
            if (currentRoute != AppRoutes.LOGIN) {
              AppLogger.info(
                'AUTH_SERVICE',
                'Session lost — redirecting to login.',
              );
              Get.offAllNamed(AppRoutes.LOGIN);
            }
          }
        }
      });
    } catch (_) {}
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
