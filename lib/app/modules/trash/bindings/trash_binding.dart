import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/trash_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/trash/controllers/trash_controller.dart';

class TrashBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<TrashDataset>()) {
      Get.lazyPut<TrashDataset>(() => TrashDataset(Get.find<SupabaseProvider>()));
    }
    Get.lazyPut<TrashController>(() => TrashController(Get.find<TrashDataset>()));
  }
}

