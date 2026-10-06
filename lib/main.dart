import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/bindings/initial_binding.dart';
import 'package:kt_prod_kt_docs/app/routes/app_pages.dart';
import 'package:kt_prod_kt_docs/core/theme/app_theme.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean Web URL Paths (Removes '#' from URLs)
  usePathUrlStrategy();

  // Initialize Supabase Backend
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Pre-load SharedPreferences so demo mode and preferences are available synchronously
  // before widget mounting and route middleware resolution, eliminating race conditions.
  final prefs = await SharedPreferences.getInstance();
  final isDemoMode = prefs.getBool('kt_demo_mode') ?? false;

  runApp(KTVaultApp(isDemoMode: isDemoMode));
}

class KTVaultApp extends StatelessWidget {
  final bool isDemoMode;
  final String? initialRoute;

  const KTVaultApp({
    super.key,
    this.isDemoMode = false,
    this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: AppScrollBehavior(),
      initialBinding: InitialBinding(isDemoInitial: isDemoMode),
      initialRoute: initialRoute ?? AppPages.initial,
      getPages: AppPages.routes,
      unknownRoute: AppPages.unknownRoute,
      defaultTransition: Transition.fadeIn,
      popGesture: false,
    );
  }
}
