import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/personal_docs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/personal_docs/controllers/personal_docs_controller.dart';

class PersonalDocsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PersonalDocsDataset>(
      () => PersonalDocsDataset(Get.find<SupabaseProvider>()),
    );
    Get.lazyPut<PersonalDocsController>(
      () => PersonalDocsController(
        Get.find<PersonalDocsDataset>(),
      ),
    );
  }
}
