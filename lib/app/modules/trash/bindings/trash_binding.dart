import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/trash/controllers/trash_controller.dart';

class TrashBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<DocumentRepository>()) {
      Get.lazyPut<DocumentRepository>(() => DocumentRepository(Get.find<SupabaseProvider>()));
    }
    Get.lazyPut<TrashController>(() => TrashController(Get.find<DocumentRepository>()));
  }
}
