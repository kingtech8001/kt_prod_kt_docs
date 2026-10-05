import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';

/// Route guard middleware that ensures unauthenticated users are redirected
/// to /login, authenticated users visiting / or /login are redirected to /dashboard,
/// and web refreshes on any screen retain proper access without blank screens.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // If AuthService is not yet registered (during very first bootstrap), allow through
    if (!Get.isRegistered<AuthService>()) {
      return null;
    }

    final authService = AuthService.to;
    final isAuthenticated = authService.isAuthenticated;

    final isLoginOrSplash = route == AppRoutes.LOGIN || route == AppRoutes.SPLASH;

    // 1. Unauthenticated user trying to access any protected screen -> send to Login
    if (!isAuthenticated && !isLoginOrSplash) {
      return const RouteSettings(name: AppRoutes.LOGIN);
    }

    // 2. Authenticated user visiting / or /login -> send to Dashboard
    if (isAuthenticated && isLoginOrSplash) {
      return const RouteSettings(name: AppRoutes.DASHBOARD);
    }

    // 3. User is allowed to access the route
    return null;
  }
}
