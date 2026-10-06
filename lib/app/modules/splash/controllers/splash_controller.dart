import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';

/// Controller for the Splash screen.
///
/// Decides the initial route immediately upon app bootstrap.
/// Supabase and SharedPreferences are already initialized before runApp() in main(),
/// eliminating race conditions and delays.
class SplashController extends GetxController {
  static const String _tag = 'SPLASH_CTRL';

  @override
  void onInit() {
    super.onInit();
    _resolveSessionAndNavigate();
  }

  void _resolveSessionAndNavigate() {
    AppLogger.debug(_tag, 'Resolving initial session on splash screen...');

    final isAuthenticated =
        Get.isRegistered<AuthService>() && AuthService.to.isAuthenticated;

    if (Get.isRegistered<AuthService>()) {
      AuthService.to.markInitialSessionResolved();
    }

    if (isAuthenticated) {
      AppLogger.info(_tag, 'Session available — navigating to Dashboard.');
      if (Get.isRegistered<AuthService>()) {
        AuthService.to.loadProfile();
      }
      Get.offAllNamed(AppRoutes.DASHBOARD);
    } else {
      AppLogger.info(_tag, 'No active session — navigating to Login.');
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}
