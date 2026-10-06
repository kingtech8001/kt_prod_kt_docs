import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';

/// Route guard middleware that ensures unauthenticated users are redirected
/// to /login for protected routes, and authenticated users can access them
/// directly on page refresh without redirect loops or blank screens.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // If AuthService is not yet registered (during very first bootstrap), allow through
    if (!Get.isRegistered<AuthService>()) {
      return null;
    }

    // Never redirect if already navigating to LOGIN or SPLASH (prevents redirect recursion)
    if (route == AppRoutes.LOGIN || route == AppRoutes.SPLASH || route == null) {
      return null;
    }

    final authService = AuthService.to;
    final isAuthenticated = authService.isAuthenticated;

    // Unauthenticated user trying to access any protected screen -> send to Login
    if (!isAuthenticated) {
      AppLogger.info('AUTH_MIDDLEWARE', 'Unauthenticated access to $route -> redirecting to LOGIN');
      return const RouteSettings(name: AppRoutes.LOGIN);
    }

    // User is authenticated -> allow access directly
    return null;
  }
}
