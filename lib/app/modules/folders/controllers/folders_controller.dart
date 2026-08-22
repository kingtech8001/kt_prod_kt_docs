import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/folder_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/folder_repository.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class FoldersController extends GetxController {
  final FolderRepository _folderRepository;

  FoldersController(this._folderRepository);

  final isLoading = true.obs;
  final folders = <FolderModel>[].obs;
  final folderNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadFolders();
  }

  Future<void> loadFolders() async {
    isLoading.value = true;
    try {
      final list = await _folderRepository.getFolders();
      folders.assignAll(list);
    } catch (e) {
      Get.snackbar('Error Loading Folders', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void openCreateFolderDialog() {
    folderNameController.clear();
    Get.dialog(
      AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: folderNameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Legal 2026, Branch Office Invoices',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = folderNameController.text.trim();
              if (name.isEmpty) return;
              Get.back();
              try {
                await _folderRepository.createFolder(name: name);
                Get.snackbar('Folder Created', 'Folder "$name" created successfully',
                    backgroundColor: AppColors.success, colorText: Colors.white);
                loadFolders();
              } catch (e) {
                Get.snackbar('Error', e.toString(),
                    backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Create Folder'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteFolder(FolderModel folder) async {
    try {
      await _folderRepository.deleteFolder(folder.id);
      folders.removeWhere((f) => f.id == folder.id);
      Get.snackbar('Folder Deleted', 'Folder "${folder.name}" deleted',
          backgroundColor: AppColors.warning, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  @override
  void onClose() {
    folderNameController.dispose();
    super.onClose();
  }
}
