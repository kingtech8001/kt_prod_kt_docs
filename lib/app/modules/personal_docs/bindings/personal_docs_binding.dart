import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/personal_docs/controllers/personal_docs_controller.dart';

class PersonalDocsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PersonalDocsController>(
      () => PersonalDocsController(
        Get.find<DocumentRepository>(),
        Get.find<MasterDataRepository>(),
      ),
    );
  }
}
