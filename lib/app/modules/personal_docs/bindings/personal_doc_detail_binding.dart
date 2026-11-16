import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/personal_docs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/personal_docs/controllers/personal_doc_detail_controller.dart';

class PersonalDocDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<PersonalDocsDataset>()) {
      Get.lazyPut<PersonalDocsDataset>(
        () => PersonalDocsDataset(Get.find<SupabaseProvider>()),
      );
    }
    Get.lazyPut<PersonalDocDetailController>(
      () => PersonalDocDetailController(Get.find<PersonalDocsDataset>()),
    );
  }
}
