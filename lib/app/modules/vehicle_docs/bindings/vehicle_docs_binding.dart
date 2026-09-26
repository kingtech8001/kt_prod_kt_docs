import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/vehicle_docs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/controllers/vehicle_docs_controller.dart';

class VehicleDocsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VehicleDocsDataset>(
      () => VehicleDocsDataset(Get.find<SupabaseProvider>()),
    );
    Get.lazyPut<VehicleDocsController>(
      () => VehicleDocsController(Get.find<VehicleDocsDataset>()),
    );
  }
}
