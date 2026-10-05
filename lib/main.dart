import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/bindings/initial_binding.dart';
import 'package:kt_prod_kt_docs/app/routes/app_pages.dart';
import 'package:kt_prod_kt_docs/core/theme/app_theme.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Always start at SplashView — it asynchronously waits for Supabase
  // to finish restoring the persisted session from browser storage
  // before routing to Dashboard (authenticated) or Login (unauthenticated).
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
