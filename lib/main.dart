import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/bindings/initial_binding.dart';
import 'package:kt_prod_kt_docs/app/routes/app_pages.dart';
import 'package:kt_prod_kt_docs/core/theme/app_theme.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean Web URL Paths (Removes '#' from URLs)
  usePathUrlStrategy();

  // Initialize Supabase Backend
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Asynchronously await Supabase session restoration from browser storage
  // so any direct web URL refresh (/dashboard, /vehicle-docs, etc.)
  // already has the authenticated user and token available BEFORE
  // controllers and views mount, eliminating the blank screen race condition.
  if (Supabase.instance.client.auth.currentUser == null) {
    try {
      final completer = Completer<void>();
      late final StreamSubscription<AuthState> sub;
      sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (!completer.isCompleted) {
          if (data.event == AuthChangeEvent.initialSession ||
              data.event == AuthChangeEvent.signedIn ||
              data.event == AuthChangeEvent.signedOut ||
              data.event == AuthChangeEvent.tokenRefreshed) {
            completer.complete();
            sub.cancel();
          }
        }
      });
      await completer.future.timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => sub.cancel(),
      );
    } catch (_) {}
  }

  runApp(const KTVaultApp());
}

class KTVaultApp extends StatelessWidget {
  const KTVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: AppScrollBehavior(),
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      unknownRoute: AppPages.unknownRoute,
      defaultTransition: Transition.fadeIn,
      popGesture: false,
    );
  }
}
