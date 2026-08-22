import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/category_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/folder_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/document_upload/controllers/document_upload_controller.dart';

class DocumentUploadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentUploadController>(
      () => DocumentUploadController(
        Get.find<DocumentRepository>(),
        Get.find<CategoryRepository>(),
        Get.find<FolderRepository>(),
        Get.find<MasterDataRepository>(),
      ),
    );
  }
}
