import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/dashboard/controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find<SupabaseProvider>()));
    }
    if (!Get.isRegistered<DocumentRepository>()) {
      Get.lazyPut<DocumentRepository>(() => DocumentRepository(Get.find<SupabaseProvider>()));
    }
    Get.lazyPut<DashboardController>(() => DashboardController(Get.find<DocumentRepository>()));
  }
}
