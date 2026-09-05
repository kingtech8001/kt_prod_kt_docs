import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/documents_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/folder_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/settings_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/modules/document_upload/controllers/document_upload_controller.dart';

class DocumentUploadBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupabaseProvider>()) {
      Get.lazyPut<SupabaseProvider>(() => SupabaseProvider());
    }
    if (!Get.isRegistered<DocumentsDataset>()) {
      Get.lazyPut<DocumentsDataset>(
        () => DocumentsDataset(Get.find<SupabaseProvider>()),
      );
    }
    if (!Get.isRegistered<FolderDataset>()) {
      Get.lazyPut<FolderDataset>(
        () => FolderDataset(Get.find<SupabaseProvider>()),
      );
    }
    if (!Get.isRegistered<SettingsDataset>()) {
      Get.lazyPut<SettingsDataset>(
        () => SettingsDataset(Get.find<SupabaseProvider>()),
      );
    }

    Get.lazyPut<DocumentUploadController>(
      () => DocumentUploadController(
        Get.find<DocumentsDataset>(),
        Get.find<FolderDataset>(),
        Get.find<SettingsDataset>(),
      ),
    );
  }
}

