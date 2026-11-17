import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/appliance_vault_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/controllers/appliance_detail_controller.dart';

class ApplianceDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<ApplianceVaultDataset>()) {
      Get.lazyPut<ApplianceVaultDataset>(
        () => ApplianceVaultDataset(Get.find<SupabaseProvider>()),
      );
    }
    Get.lazyPut<ApplianceDetailController>(
      () => ApplianceDetailController(Get.find<ApplianceVaultDataset>()),
    );
  }
}
