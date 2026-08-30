import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoritesController extends GetxController {
  final DocumentRepository _documentRepository;

  FavoritesController(this._documentRepository);

  final isLoading = true.obs;
  final favoriteDocuments = <DocumentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    isLoading.value = true;
    try {
      final docs = await _documentRepository.getDocuments(isFavoriteOnly: true);
      favoriteDocuments.assignAll(docs);
    } catch (e) {
      Get.snackbar(
        'Error Loading Favorites',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    try {
      await _documentRepository.toggleFavorite(doc.id, true);
      favoriteDocuments.removeWhere((d) => d.id == doc.id);
      Get.snackbar(
        'Removed',
        'Document removed from favorites',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> previewDocument(DocumentModel doc) async {
    try {
      final signedUrl = await _documentRepository.getSignedPreviewUrl(
        doc.filePath,
      );
      if (doc.isPdf) {
        PdfViewerDialog.show(
          title: doc.title,
          signedPdfUrl: signedUrl,
          onDownload: () => downloadDocument(doc),
        );
      } else if (doc.isImage) {
        ImageLightboxDialog.show(
          title: doc.title,
          imageUrl: signedUrl,
          onDownload: () => downloadDocument(doc),
        );
      } else {
        final uri = Uri.parse(signedUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Preview Failed',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    try {
      final signedUrl = await _documentRepository.getSignedPreviewUrl(
        doc.filePath,
      );
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar(
        'Download Failed',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> shareDocument(DocumentModel doc) async {
    try {
      final signedUrl = await _documentRepository.getSignedPreviewUrl(
        doc.filePath,
      );
      ShareDocumentDialog.show(documentTitle: doc.title, shareUrl: signedUrl);
    } catch (e) {
      Get.snackbar(
        'Share Failed',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    try {
      await _documentRepository.softDeleteDocument(doc.id);
      favoriteDocuments.removeWhere((d) => d.id == doc.id);
      Get.snackbar(
        'Moved to Trash',
        '${doc.title} moved to trash bin',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void confirmMoveToTrash(DocumentModel doc) {
    DocumentDeleteDialog.show(
      documentTitle: doc.title,
      onConfirm: () => moveToTrash(doc),
    );
  }

  void openEditDocumentDialog(DocumentModel doc) {
    DocumentEditDialog.show(
      document: doc,
      onSave: ({required title, description, documentNumber}) async {
        try {
          await _documentRepository.updateDocumentDetails(
            documentId: doc.id,
            title: title,
            description: description,
            documentNumber: documentNumber,
          );
          await loadFavorites();
          Get.snackbar(
            'Document Updated',
            'Document details were saved.',
            backgroundColor: AppColors.success,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            'Update Error',
            e.toString(),
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
          rethrow;
        }
      },
    );
  }
}
