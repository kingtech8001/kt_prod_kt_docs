import 'dart:async';

import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller for the Splash screen.
///
/// Asynchronously waits for Supabase to finish restoring the persisted
/// auth session from browser storage before deciding the initial route.
/// This prevents the race condition where a synchronous `currentUser`
/// check returns `null` on page refresh because session recovery is async.
class SplashController extends GetxController {
  static const String _tag = 'SPLASH_CTRL';

  /// Maximum time to wait for Supabase session recovery before
  /// falling back to the login screen.
  static const Duration _sessionTimeout = Duration(seconds: 4);

  @override
  void onInit() {
    super.onInit();
    _resolveSessionAndNavigate();
  }

  Future<void> _resolveSessionAndNavigate() async {
    try {
      AppLogger.debug(_tag, 'Waiting for Supabase session restoration...');

      // Check if session or demo mode is already available synchronously (fast path)
      final immediateUser = Supabase.instance.client.auth.currentUser;
      final isDemo = Get.isRegistered<AuthService>() && AuthService.to.isDemoMode.value;
      if (immediateUser != null || isDemo) {
        AppLogger.info(
          _tag,
          'Session or Demo mode already available, navigating to dashboard.',
        );
        _navigateToApp(authenticated: true);
        return;
      }

      // Session not immediately available — wait for the auth state change
      // event that fires once Supabase finishes recovering the session
      // from browser local storage.
      final completer = Completer<bool>();
      late final StreamSubscription<AuthState> subscription;

      subscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (!completer.isCompleted) {
          final event = data.event;
          AppLogger.debug(_tag, 'Auth state event received: $event');

          if (event == AuthChangeEvent.initialSession) {
            // Supabase has finished checking stored session
            completer.complete(data.session != null);
            subscription.cancel();
          } else if (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed) {
            completer.complete(true);
            subscription.cancel();
          } else if (event == AuthChangeEvent.signedOut) {
            completer.complete(false);
            subscription.cancel();
          }
        }
      });

      // Safety timeout — never hang forever on the splash screen
      final isAuthenticated = await completer.future.timeout(
        _sessionTimeout,
        onTimeout: () {
          AppLogger.warning(
            _tag,
            'Session restoration timed out after ${_sessionTimeout.inSeconds}s, '
                'falling back to auth check.',
          );
          subscription.cancel();
          // Final synchronous check as a last resort
          return Supabase.instance.client.auth.currentUser != null;
        },
      );

      _navigateToApp(authenticated: isAuthenticated);
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Error during session resolution: $e',
        error: e,
        stackTrace: st,
      );
      // On any unexpected error, fall through to login
      _navigateToApp(authenticated: false);
    }
  }

  void _navigateToApp({required bool authenticated}) {
    // Tell AuthService that initial session resolution is complete —
    // any subsequent auth state changes (sign-out) can trigger redirects.
    if (Get.isRegistered<AuthService>()) {
      AuthService.to.markInitialSessionResolved();
    }

    if (authenticated) {
      AppLogger.info(_tag, 'Session restored — navigating to Dashboard.');

      // Hydrate user profile into AuthService if available
      if (Get.isRegistered<AuthService>()) {
        AuthService.to.loadProfile();
      }

      Get.offAllNamed(AppRoutes.DASHBOARD);
    } else {
      AppLogger.info(_tag, 'No session found — navigating to Login.');
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }
}
