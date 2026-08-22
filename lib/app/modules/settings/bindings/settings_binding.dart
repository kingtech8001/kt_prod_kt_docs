import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/settings/controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find<SupabaseProvider>()));
    }
    if (!Get.isRegistered<MasterDataRepository>()) {
      Get.lazyPut<MasterDataRepository>(() => MasterDataRepository(Get.find<SupabaseProvider>()));
    }
    Get.lazyPut<SettingsController>(() => SettingsController(
          Get.find<AuthRepository>(),
          Get.find<MasterDataRepository>(),
        ));
  }
}
