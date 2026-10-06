import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/activity_logs/bindings/activity_logs_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/activity_logs/views/activity_logs_view.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/bindings/appliance_vault_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/views/appliance_vault_view.dart';
import 'package:kt_prod_kt_docs/app/modules/auth/bindings/auth_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/auth/views/auth_view.dart';
import 'package:kt_prod_kt_docs/app/modules/splash/bindings/splash_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/splash/views/splash_view.dart';
import 'package:kt_prod_kt_docs/app/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/dashboard/views/dashboard_view.dart';
import 'package:kt_prod_kt_docs/app/modules/document_upload/bindings/document_upload_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/document_upload/views/document_upload_view.dart';
import 'package:kt_prod_kt_docs/app/modules/documents/bindings/documents_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/documents/views/documents_view.dart';
import 'package:kt_prod_kt_docs/app/modules/favorites/bindings/favorites_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/favorites/views/favorites_view.dart';
import 'package:kt_prod_kt_docs/app/modules/folders/bindings/folders_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/folders/views/folders_view.dart';
import 'package:kt_prod_kt_docs/app/modules/personal_docs/bindings/personal_docs_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/personal_docs/views/personal_docs_view.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/bindings/vehicle_docs_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/views/vehicle_docs_view.dart';
import 'package:kt_prod_kt_docs/app/modules/profile/bindings/profile_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/profile/views/profile_view.dart';
import 'package:kt_prod_kt_docs/app/modules/settings/bindings/settings_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/settings/views/settings_view.dart';
import 'package:kt_prod_kt_docs/app/modules/trash/bindings/trash_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/trash/views/trash_view.dart';
import 'package:kt_prod_kt_docs/app/modules/users/bindings/users_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/users/views/users_view.dart';
import 'package:kt_prod_kt_docs/app/modules/utility_bills/bindings/utility_bills_binding.dart';
import 'package:kt_prod_kt_docs/app/modules/utility_bills/views/utility_bills_view.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/routes/auth_middleware.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.DASHBOARD;

  static final unknownRoute = GetPage(
    name: '/notfound',
    page: () => const DashboardView(),
    binding: DashboardBinding(),
    middlewares: [AuthMiddleware()],
  );

  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.DOCUMENTS,
      page: () => const DocumentsView(),
      binding: DocumentsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.UTILITY_BILLS,
      page: () => const UtilityBillsView(),
      binding: UtilityBillsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.APPLIANCES,
      page: () => const ApplianceVaultView(),
      binding: ApplianceVaultBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.PERSONAL_DOCS,
      page: () => const PersonalDocsView(),
      binding: PersonalDocsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.VEHICLE_DOCS,
      page: () => const VehicleDocsView(),
      binding: VehicleDocsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.UPLOAD,
      page: () => const DocumentUploadView(),
      binding: DocumentUploadBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.FOLDERS,
      page: () => const FoldersView(),
      binding: FoldersBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.FAVORITES,
      page: () => const FavoritesView(),
      binding: FavoritesBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.TRASH,
      page: () => const TrashView(),
      binding: TrashBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ACTIVITY_LOGS,
      page: () => const ActivityLogsView(),
      binding: ActivityLogsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.USERS,
      page: () => const UsersView(),
      binding: UsersBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}

