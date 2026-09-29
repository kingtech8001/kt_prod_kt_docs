import 'dart:async';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/documents_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsController extends GetxController {
  final DocumentsDataset _dataset;

  DocumentsController(this._dataset);

  final isLoading = true.obs;
  final documents = <DocumentModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final dynamicCities = <String>[].obs;

  // Filters
  final selectedCity = 'All Cities'.obs;
  final selectedCategoryId = ''.obs;
  final selectedFolderId = ''.obs;
  final selectedStatus = 'all'.obs;
  final searchQuery = ''.obs;
  final isGridView = true.obs;

  Timer? _searchDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    final paramFolderId = Get.parameters['folderId'];
    if (paramFolderId != null && paramFolderId.isNotEmpty) {
      selectedFolderId.value = paramFolderId;
    }
    loadInitialData();
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    AppLogger.debug('DOCS_CTRL', 'Loading categories, cities, and documents concurrently...');
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _dataset.getAllCategories(),
        _dataset.getCities(activeOnly: true),
        _dataset.getFilteredDocuments(
          categoryId: selectedCategoryId.value.isNotEmpty
              ? selectedCategoryId.value
              : null,
          folderId: selectedFolderId.value.isNotEmpty
              ? selectedFolderId.value
              : null,
          city: selectedCity.value != 'All Cities' ? selectedCity.value : null,
          status: selectedStatus.value != 'all' ? selectedStatus.value : null,
          searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        ),
      ]);

      categories.assignAll(results[0] as List<CategoryModel>);  
      final cities = results[1] as List<MasterCityModel>;
      dynamicCities.assignAll(cities.map((c) => c.name));
      documents.assignAll(results[2] as List<DocumentModel>);
    } catch (e, st) {
      AppLogger.error(
        'DOCS_CTRL',
        'Error in loadInitialData: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Documents', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFilteredDocuments() async {
    AppLogger.debug(
      'DOCS_CTRL',
      'Filtering documents: city=${selectedCity.value}, cat=${selectedCategoryId.value}, search=${searchQuery.value}',
    );
    isLoading.value = true;
    try {
      final docs = await _dataset.getFilteredDocuments(
        categoryId: selectedCategoryId.value.isNotEmpty
            ? selectedCategoryId.value
            : null,
        folderId: selectedFolderId.value.isNotEmpty
            ? selectedFolderId.value
            : null,
        city: selectedCity.value != 'All Cities' ? selectedCity.value : null,
        status: selectedStatus.value != 'all' ? selectedStatus.value : null,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );
      documents.assignAll(docs);
    } catch (e, st) {
      AppLogger.error(
        'DOCS_CTRL',
        'Error fetching filtered documents: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Fetching Documents', e.toString());
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
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      fetchFilteredDocuments();
    });
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

  Future<void> previewDocument(DocumentModel doc) async {
    try {
      final signedUrl = await _dataset.getSignedPreviewUrl(doc.filePath);
      if (doc.isPdf) {
        PdfViewerDialog.show(
          title: doc.title,
          signedPdfUrl: signedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
      } else if (doc.isImage) {
        ImageLightboxDialog.show(
          title: doc.title,
          imageUrl: signedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
      } else {
        final uri = Uri.parse(signedUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'DOCS_CTRL',
        'Error opening preview: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Preview Error', e.toString());
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    try {
      final signedUrl = await _dataset.getSignedPreviewUrl(doc.filePath, download: true);
      await FileApiHelper.downloadFileFromUrl(
        url: signedUrl,
        fileName: doc.fileName,
        mimeType: doc.mimeType,
      );
      AppSnackbar.showSuccess('Download Started', '${doc.fileName} is downloading.');
    } catch (e, st) {
      AppLogger.error(
        'DOCS_CTRL',
        'Error downloading: $e',
        error: e,
        stackTrace: st,
      );
      try {
        final fallbackUrl = await _dataset.getSignedPreviewUrl(doc.filePath, download: true);
        final uri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (_) {
        AppSnackbar.showError('Download Error', e.toString());
      }
    }
  }

  void openDocument(DocumentModel doc) {
    previewDocument(doc);
  }

  Future<void> openShareDialog(DocumentModel doc) async {
    try {
      final token = await _dataset.createShareLink(doc.id);
      final shareUrl = '${AppConstants.webBaseUrl}/share/$token';
      ShareDocumentDialog.show(documentTitle: doc.title, shareUrl: shareUrl);
    } catch (e, st) {
      AppLogger.error(
        'DOCS_CTRL',
        'Error creating share link: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Share Error', e.toString());
    }
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    try {
      final updated = await _dataset.toggleFavorite(doc.id, doc.isFavorite);
      final index = documents.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        documents[index] = doc.copyWith(isFavorite: updated);
      }
    } catch (e, st) {
      AppLogger.error(
        'DOCS_CTRL',
        'Error toggling favorite: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error', e.toString());
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    try {
      await _dataset.softDeleteDocument(doc.id);
      documents.removeWhere((d) => d.id == doc.id);
      AppSnackbar.showWarning(
        'Moved to Trash',
        '${doc.title} moved to trash bin.',
      );
    } catch (e, st) {
      AppLogger.error(
        'DOCS_CTRL',
        'Error moving to trash: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error', e.toString());
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
      onSave: ({
        required title,
        description,
        documentNumber,
        applianceWarranty,
        vehicleMetadata,
      }) async {
        try {
          await _dataset.updateDocumentDetails(
            documentId: doc.id,
            title: title,
            description: description,
            documentNumber: documentNumber,
            applianceWarranty: applianceWarranty,
            vehicleMetadata: vehicleMetadata,
          );
          await fetchFilteredDocuments();
        } catch (e, st) {
          AppLogger.error(
            'DOCS_CTRL',
            'Error editing document: $e',
            error: e,
            stackTrace: st,
          );
          // Inline modal error handling: rethrow so the dialog can display the error inside without closing
          rethrow;
        }
      },
    );
  }
}
