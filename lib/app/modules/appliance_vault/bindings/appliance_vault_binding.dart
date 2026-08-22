import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/controllers/appliance_vault_controller.dart';

class ApplianceVaultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApplianceVaultController>(
      () => ApplianceVaultController(
        Get.find<DocumentRepository>(),
        Get.find<MasterDataRepository>(),
      ),
    );
  }
}
