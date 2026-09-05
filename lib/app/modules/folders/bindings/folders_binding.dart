import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/folder_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/folders/controllers/folders_controller.dart';

class FoldersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<FolderDataset>()) {
      Get.lazyPut<FolderDataset>(
        () => FolderDataset(Get.find<SupabaseProvider>()),
      );
    }
    Get.lazyPut<FoldersController>(
      () => FoldersController(Get.find<FolderDataset>()),
    );
  }
}
