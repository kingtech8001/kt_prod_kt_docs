import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonalDocsController extends GetxController {
  final DocumentRepository _documentRepository;
  final MasterDataRepository _masterDataRepository;

  PersonalDocsController(this._documentRepository, this._masterDataRepository);

  final isLoading = true.obs;
  final personalDocuments = <DocumentModel>[].obs;
  final dynamicPersons = <String>[].obs;
  final dynamicDocTypes = <String>[].obs;

  // Filters
  final selectedPerson = 'All Persons'.obs;
  final selectedDocType = 'All Document Types'.obs;
  final searchQuery = ''.obs;
  final isGridView = true.obs;

  // Summary Metrics
  final totalDocumentsCount = 0.obs;
  final totalPersonsCoveredCount = 0.obs;
  final expiringSoonCount = 0.obs;
  final expiredCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadMasterData();
    loadPersonalDocuments();
  }

  Future<void> loadMasterData() async {
    try {
      final pList = await _masterDataRepository.getPersons(activeOnly: true);
      dynamicPersons.assignAll(pList.map((p) => p.fullName));

      final dtList = await _masterDataRepository.getPersonalDocTypes(activeOnly: true);
      dynamicDocTypes.assignAll(dtList.map((t) => t.name));
    } catch (e, st) {
      AppLogger.error('PERSONAL_DOCS_CTRL', 'Error loading master data: $e', error: e, stackTrace: st);
    }
  }

  Future<void> loadPersonalDocuments() async {
    AppLogger.debug('PERSONAL_DOCS_CTRL', 'Loading personal documents for person: ${selectedPerson.value}, docType: ${selectedDocType.value}');
    isLoading.value = true;
    try {
      final docs = await _documentRepository.getDocuments(
        categoryCode: 'identity_docs',
        personName: selectedPerson.value != 'All Persons' ? selectedPerson.value : null,
        personalDocType: selectedDocType.value != 'All Document Types' ? selectedDocType.value : null,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      final filtered = docs.where((d) => d.personalMetadata != null).toList();
      personalDocuments.assignAll(filtered);
      _computeSummaryMetrics(filtered);
    } catch (e, st) {
      AppLogger.error('PERSONAL_DOCS_CTRL', 'Error loading personal documents: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error Loading Documents',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _computeSummaryMetrics(List<DocumentModel> docs) {
    final personsSet = <String>{};
    int expiring = 0;
    int expired = 0;

    for (var doc in docs) {
      final meta = doc.personalMetadata;
      if (meta != null) {
        personsSet.add(meta.personName);
        if (meta.isExpired) {
          expired++;
        } else if (meta.isExpiringSoon) {
          expiring++;
        }
      }
    }

    totalDocumentsCount.value = docs.length;
    totalPersonsCoveredCount.value = personsSet.length;
    expiringSoonCount.value = expiring;
    expiredCount.value = expired;
  }

  void onPersonSelected(String person) {
    selectedPerson.value = person;
    loadPersonalDocuments();
  }

  void onDocTypeSelected(String type) {
    selectedDocType.value = type;
    loadPersonalDocuments();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    loadPersonalDocuments();
  }

  void toggleViewMode([bool? grid]) {
    if (grid != null) {
      isGridView.value = grid;
    } else {
      isGridView.value = !isGridView.value;
    }
  }

  void previewDocument(DocumentModel doc) async {
    try {
      final signedUrl = await _documentRepository.getSignedPreviewUrl(doc.filePath);
      if (doc.isPdf) {
        PdfViewerDialog.show(title: doc.title, signedPdfUrl: signedUrl);
      } else if (doc.isImage) {
        ImageLightboxDialog.show(title: doc.title, imageUrl: signedUrl);
      } else {
        final uri = Uri.parse(signedUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e, st) {
      AppLogger.error('PERSONAL_DOCS_CTRL', 'Error opening preview: $e', error: e, stackTrace: st);
      Get.snackbar('Preview Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  void downloadDocument(DocumentModel doc) async {
    try {
      final signedUrl = await _documentRepository.getSignedPreviewUrl(doc.filePath);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e, st) {
      AppLogger.error('PERSONAL_DOCS_CTRL', 'Error downloading: $e', error: e, stackTrace: st);
      Get.snackbar('Download Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  void openDocument(DocumentModel doc) {
    previewDocument(doc);
  }

  void shareDocument(DocumentModel doc) {
    openShareDialog(doc);
  }

  void openShareDialog(DocumentModel doc) async {
    try {
      final token = await _documentRepository.createShareLink(doc.id);
      final shareUrl = '${AppConstants.webBaseUrl}/share/$token';
      ShareDocumentDialog.show(documentTitle: doc.title, shareUrl: shareUrl);
    } catch (e, st) {
      AppLogger.error('PERSONAL_DOCS_CTRL', 'Error creating share link: $e', error: e, stackTrace: st);
      Get.snackbar('Share Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    try {
      final updated = await _documentRepository.toggleFavorite(
        doc.id,
        doc.isFavorite,
      );
      final index = personalDocuments.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        personalDocuments[index] = doc.copyWith(isFavorite: updated);
      }
    } catch (e, st) {
      AppLogger.error('PERSONAL_DOCS_CTRL', 'Error toggling favorite: $e', error: e, stackTrace: st);
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    try {
      await _documentRepository.softDeleteDocument(doc.id);
      personalDocuments.removeWhere((d) => d.id == doc.id);
      Get.snackbar(
        'Moved to Trash',
        '${doc.title} moved to trash bin.',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
    } catch (e, st) {
      AppLogger.error('PERSONAL_DOCS_CTRL', 'Error moving to trash: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
