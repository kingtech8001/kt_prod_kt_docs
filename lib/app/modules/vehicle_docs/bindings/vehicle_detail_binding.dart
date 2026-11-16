import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/vehicle_docs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/controllers/vehicle_detail_controller.dart';

class VehicleDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<VehicleDocsDataset>()) {
      Get.lazyPut<VehicleDocsDataset>(
        () => VehicleDocsDataset(Get.find<SupabaseProvider>()),
      );
    }
    Get.lazyPut<VehicleDetailController>(
      () => VehicleDetailController(Get.find<VehicleDocsDataset>()),
    );
  }
}
