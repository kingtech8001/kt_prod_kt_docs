import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/folder_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/folders/controllers/folders_controller.dart';

class FoldersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<FolderRepository>()) {
      Get.lazyPut<FolderRepository>(() => FolderRepository(Get.find<SupabaseProvider>()));
    }
    Get.lazyPut<FoldersController>(() => FoldersController(Get.find<FolderRepository>()));
  }
}
