import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/category_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsController extends GetxController {
  final DocumentRepository _documentRepository;
  final CategoryRepository _categoryRepository;
  final MasterDataRepository _masterDataRepository;

  DocumentsController(
    this._documentRepository,
    this._categoryRepository,
    this._masterDataRepository,
  );

  final isLoading = true.obs;
  final documents = <DocumentModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final dynamicCities = <String>[].obs;

  // Filters
  final selectedCity = 'All Cities'.obs;
  final selectedCategoryId = ''.obs;
  final selectedStatus = 'all'.obs;
  final searchQuery = ''.obs;
  final isGridView = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategoriesAndDocuments();
    loadDynamicCities();
  }

  Future<void> loadDynamicCities() async {
    try {
      final cities = await _masterDataRepository.getCities(activeOnly: true);
      dynamicCities.assignAll(cities.map((c) => c.name));
    } catch (e, st) {
      AppLogger.error('DOCS_CTRL', 'Error loading dynamic cities: $e', error: e, stackTrace: st);
    }
  }

  Future<void> loadCategoriesAndDocuments() async {
    AppLogger.debug('DOCS_CTRL', 'Loading categories and initial documents...');
    isLoading.value = true;
    try {
      final cats = await _categoryRepository.getAllCategories();
      categories.assignAll(cats);

      await fetchFilteredDocuments();
    } catch (e, st) {
      AppLogger.error('DOCS_CTRL', 'Error in loadCategoriesAndDocuments: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFilteredDocuments() async {
    AppLogger.debug('DOCS_CTRL', 'Filtering documents: city=${selectedCity.value}, cat=${selectedCategoryId.value}, search=${searchQuery.value}');
    isLoading.value = true;
    try {
      final docs = await _documentRepository.getDocuments(
        categoryId: selectedCategoryId.value.isNotEmpty ? selectedCategoryId.value : null,
        city: selectedCity.value != 'All Cities' ? selectedCity.value : null,
        status: selectedStatus.value != 'all' ? selectedStatus.value : null,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );
      documents.assignAll(docs);
    } catch (e, st) {
      AppLogger.error('DOCS_CTRL', 'Error fetching filtered documents: $e', error: e, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  void onCitySelected(String city) {
    selectedCity.value = city;
    fetchFilteredDocuments();
  }

  void onCategorySelected(String? categoryId) {
    selectedCategoryId.value = categoryId ?? '';
    fetchFilteredDocuments();
  }

  void onStatusSelected(String status) {
    selectedStatus.value = status;
    fetchFilteredDocuments();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    fetchFilteredDocuments();
  }

  void toggleViewMode([bool? grid]) {
    if (grid != null) {
      isGridView.value = grid;
    } else {
      isGridView.value = !isGridView.value;
    }
  }

  void shareDocument(DocumentModel doc) {
    openShareDialog(doc);
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
      AppLogger.error('DOCS_CTRL', 'Error opening preview: $e', error: e, stackTrace: st);
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
      AppLogger.error('DOCS_CTRL', 'Error downloading: $e', error: e, stackTrace: st);
      Get.snackbar('Download Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  void openDocument(DocumentModel doc) {
    previewDocument(doc);
  }

  void openShareDialog(DocumentModel doc) async {
    try {
      final token = await _documentRepository.createShareLink(doc.id);
      final shareUrl = '${AppConstants.webBaseUrl}/share/$token';
      ShareDocumentDialog.show(documentTitle: doc.title, shareUrl: shareUrl);
    } catch (e, st) {
      AppLogger.error('DOCS_CTRL', 'Error creating share link: $e', error: e, stackTrace: st);
      Get.snackbar('Share Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    try {
      final updated = await _documentRepository.toggleFavorite(
        doc.id,
        doc.isFavorite,
      );
      final index = documents.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        documents[index] = doc.copyWith(isFavorite: updated);
      }
    } catch (e, st) {
      AppLogger.error('DOCS_CTRL', 'Error toggling favorite: $e', error: e, stackTrace: st);
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    try {
      await _documentRepository.softDeleteDocument(doc.id);
      documents.removeWhere((d) => d.id == doc.id);
      Get.snackbar(
        'Moved to Trash',
        '${doc.title} moved to trash bin.',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
    } catch (e, st) {
      AppLogger.error('DOCS_CTRL', 'Error moving to trash: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
