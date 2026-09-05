import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/settings_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/settings/controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<SettingsDataset>()) {
      Get.lazyPut<SettingsDataset>(() => SettingsDataset(Get.find<SupabaseProvider>()));
    }
    Get.lazyPut<SettingsController>(
      () => SettingsController(Get.find<SettingsDataset>()),
    );
  }
}

