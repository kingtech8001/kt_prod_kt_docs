import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/documents_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/documents/controllers/documents_controller.dart';

class DocumentsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<DocumentsDataset>()) {
      Get.lazyPut<DocumentsDataset>(
        () => DocumentsDataset(Get.find<SupabaseProvider>()),
      );
    }
    Get.lazyPut<DocumentsController>(
      () => DocumentsController(Get.find<DocumentsDataset>()),
    );
  }
}

