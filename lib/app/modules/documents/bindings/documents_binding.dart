import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/category_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/documents/controllers/documents_controller.dart';

class DocumentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentsController>(
      () => DocumentsController(
        Get.find<DocumentRepository>(),
        Get.find<CategoryRepository>(),
        Get.find<MasterDataRepository>(),
      ),
    );
  }
}
