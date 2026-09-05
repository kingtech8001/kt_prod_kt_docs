import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/activity_logs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/activity_logs/controllers/activity_logs_controller.dart';

class ActivityLogsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<ActivityLogsDataset>()) {
      Get.lazyPut<ActivityLogsDataset>(
        () => ActivityLogsDataset(Get.find<SupabaseProvider>()),
      );
    }
    Get.lazyPut<ActivityLogsController>(
      () => ActivityLogsController(Get.find<ActivityLogsDataset>()),
    );
  }
}

