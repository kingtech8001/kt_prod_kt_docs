import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/appliance_vault_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/controllers/appliance_vault_controller.dart';

class ApplianceVaultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApplianceVaultDataset>(
      () => ApplianceVaultDataset(Get.find<SupabaseProvider>()),
    );
    Get.lazyPut<ApplianceVaultController>(
      () => ApplianceVaultController(
        Get.find<ApplianceVaultDataset>(),
      ),
    );
  }
}
