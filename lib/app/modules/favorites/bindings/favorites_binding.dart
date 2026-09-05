import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/favorites_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/favorites/controllers/favorites_controller.dart';

class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesDataset>(
      () => FavoritesDataset(Get.find<SupabaseProvider>()),
    );
    Get.lazyPut<FavoritesController>(
      () => FavoritesController(
        Get.find<FavoritesDataset>(),
      ),
    );
  }
}
