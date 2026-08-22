import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/modules/utility_bills/controllers/utility_bills_controller.dart';

class UtilityBillsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UtilityBillsController>(
      () => UtilityBillsController(
        Get.find<DocumentRepository>(),
        Get.find<SupabaseProvider>(),
        Get.find<MasterDataRepository>(),
      ),
    );
  }
}
