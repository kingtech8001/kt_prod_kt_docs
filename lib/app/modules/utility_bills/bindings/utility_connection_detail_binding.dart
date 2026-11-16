import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/utility_bills_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/utility_bills/controllers/utility_connection_detail_controller.dart';

class UtilityConnectionDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<UtilityBillsDataset>()) {
      Get.lazyPut<UtilityBillsDataset>(
        () => UtilityBillsDataset(Get.find<SupabaseProvider>()),
      );
    }
    Get.lazyPut<UtilityConnectionDetailController>(
      () => UtilityConnectionDetailController(Get.find<UtilityBillsDataset>()),
    );
  }
}
