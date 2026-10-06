import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/activity_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/auth_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/category_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/folder_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';

class InitialBinding extends Bindings {
  final bool isDemoInitial;

  InitialBinding({this.isDemoInitial = false});

  @override
  void dependencies() {
    Get.lazyPut<SupabaseProvider>(() => SupabaseProvider(), fenix: true);
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find<SupabaseProvider>()),
      fenix: true,
    );
    Get.put<AuthService>(
      AuthService(Get.find<AuthRepository>(), initialDemoMode: isDemoInitial),
      permanent: true,
    );
    Get.lazyPut<MasterDataRepository>(
      () => MasterDataRepository(Get.find<SupabaseProvider>()),
      fenix: true,
    );
    Get.lazyPut<DocumentRepository>(
      () => DocumentRepository(Get.find<SupabaseProvider>()),
      fenix: true,
    );
    Get.lazyPut<CategoryRepository>(
      () => CategoryRepository(Get.find<SupabaseProvider>()),
      fenix: true,
    );
    Get.lazyPut<FolderRepository>(
      () => FolderRepository(Get.find<SupabaseProvider>()),
      fenix: true,
    );
    Get.lazyPut<ActivityRepository>(
      () => ActivityRepository(Get.find<SupabaseProvider>()),
      fenix: true,
    );
  }
}
