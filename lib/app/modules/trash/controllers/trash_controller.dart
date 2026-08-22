import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class TrashController extends GetxController {
  final DocumentRepository _documentRepository;

  TrashController(this._documentRepository);

  final isLoading = true.obs;
  final trashDocuments = <DocumentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTrashDocuments();
  }

  Future<void> loadTrashDocuments() async {
    isLoading.value = true;
    try {
      final docs = await _documentRepository.getDocuments(isTrashOnly: true);
      trashDocuments.assignAll(docs);
    } catch (e) {
      Get.snackbar('Error Loading Trash', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreDocument(DocumentModel doc) async {
    try {
      await _documentRepository.restoreDocument(doc.id);
      trashDocuments.removeWhere((d) => d.id == doc.id);
      Get.snackbar('Restored', 'Restored "${doc.title}" to active documents',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> confirmPermanentDelete(DocumentModel doc) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Permanently Delete Document?'),
        content: Text(
          'Are you sure you want to permanently delete "${doc.title}"? This action cannot be undone and will purge the file from encrypted storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Get.back();
              try {
                await _documentRepository.permanentDeleteDocument(doc.id, doc.filePath);
                trashDocuments.removeWhere((d) => d.id == doc.id);
                Get.snackbar('Deleted', 'Document permanently purged from vault',
                    backgroundColor: AppColors.error, colorText: Colors.white);
              } catch (e) {
                Get.snackbar('Error', e.toString(),
                    backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}
