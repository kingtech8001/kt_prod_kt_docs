import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/staff_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/users/controllers/users_controller.dart';

class UsersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<StaffDataset>()) {
      Get.lazyPut<StaffDataset>(
        () => StaffDataset(Get.find<SupabaseProvider>()),
      );
    }
    Get.lazyPut<UsersController>(
      () => UsersController(Get.find<StaffDataset>()),
    );
  }
}

