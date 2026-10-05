import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/bindings/initial_binding.dart';
import 'package:kt_prod_kt_docs/app/routes/app_pages.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
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

  // Check if session exists
  final initialRoute = Supabase.instance.client.auth.currentUser != null
      ? AppRoutes.DASHBOARD
      : AppRoutes.LOGIN;

  runApp(KTVaultApp(initialRoute: initialRoute));
}

class KTVaultApp extends StatelessWidget {
  final String initialRoute;

  const KTVaultApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: AppScrollBehavior(),
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      unknownRoute: AppPages.unknownRoute,
      defaultTransition: Transition.fadeIn,
      popGesture: false,
    );
  }
}
