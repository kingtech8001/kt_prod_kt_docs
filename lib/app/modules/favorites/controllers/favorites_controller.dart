import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/favorites_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoritesController extends GetxController {
  final FavoritesDataset _dataset;

  FavoritesController(this._dataset);

  // Loading & Pagination State
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final currentPage = 1.obs;
  final pageSize = 20;
  final totalCount = 0.obs;

  final scrollController = ScrollController();
  final searchController = TextEditingController();

  // Data Collections
  final favoriteDocuments = <DocumentModel>[].obs;
  final categories = <CategoryModel>[].obs;

  // Filters
  final selectedCategoryCode = 'all'.obs;
  final searchQuery = ''.obs;

  Timer? _searchDebounceTimer;

  // Role Permissions
  bool get canDelete {
    try {
      return AuthService.to.isAdmin;
    } catch (_) {
      return false;
    }
  }

  bool get canEdit {
    try {
      final role = AuthService.to.currentProfile.value?.role.toLowerCase();
      return role == 'admin' || role == 'super_admin' || role == 'editor';
    } catch (_) {
      return true;
    }
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadCategories();
    loadFavorites(resetPage: true);
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
      loadNextPage();
    }
  }

  Future<void> loadCategories() async {
    try {
      final list = await _dataset.getCategories();
      categories.assignAll(list);
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_CTRL',
        'Error loading categories: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> loadFavorites({bool resetPage = false}) async {
    if (resetPage) {
      currentPage.value = 1;
      hasMore.value = true;
      isLoading.value = true;
    }

    AppLogger.debug(
      'FAVORITES_CTRL',
      'Loading favorites (page: ${currentPage.value}, cat: ${selectedCategoryCode.value}, search: ${searchQuery.value})',
    );

    try {
      final response = await _dataset.getFavorites(
        page: currentPage.value,
        pageSize: pageSize,
        categoryCode: selectedCategoryCode.value != 'all'
            ? selectedCategoryCode.value
            : null,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      favoriteDocuments.assignAll(response.documents);
      totalCount.value = response.totalCount;
      hasMore.value = favoriteDocuments.length < totalCount.value;
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_CTRL',
        'Error loading favorites: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Favorites', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    final nextPage = currentPage.value + 1;

    AppLogger.debug('FAVORITES_CTRL', 'Loading next page: $nextPage...');

    try {
      final response = await _dataset.getFavorites(
        page: nextPage,
        pageSize: pageSize,
        categoryCode: selectedCategoryCode.value != 'all'
            ? selectedCategoryCode.value
            : null,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      if (response.documents.isEmpty) {
        hasMore.value = false;
      } else {
        favoriteDocuments.addAll(response.documents);
        currentPage.value = nextPage;
        hasMore.value = favoriteDocuments.length < totalCount.value;
      }
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_CTRL',
        'Error loading more favorites: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Failed to load more', e.toString());
    } finally {
      isLoadingMore.value = false;
    }
  }

  void onCategorySelected(String code) {
    if (selectedCategoryCode.value == code) return;
    selectedCategoryCode.value = code;
    loadFavorites(resetPage: true);
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadFavorites(resetPage: true);
    });
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    loadFavorites(resetPage: true);
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    try {
      await _dataset.toggleFavorite(doc.id, true);
      favoriteDocuments.removeWhere((d) => d.id == doc.id);
      totalCount.value = (totalCount.value - 1).clamp(0, 999999);
      AppSnackbar.showInfo(
        'Removed from Starred',
        '${doc.title} removed from favorites.',
      );
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_CTRL',
        'Error toggling favorite: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error', e.toString());
    }
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
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_CTRL',
        'Preview error: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Preview Failed', e.toString());
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
        'FAVORITES_CTRL',
        'Download error: $e',
        error: e,
        stackTrace: st,
      );
      try {
        final fallbackUrl = await _dataset.getSignedPreviewUrl(doc.filePath, download: true);
        final uri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        AppSnackbar.showError('Download Failed', e.toString());
      }
    }
  }

  void openDocument(DocumentModel doc) {
    previewDocument(doc);
  }

  Future<void> shareDocument(DocumentModel doc) async {
    try {
      final token = await _dataset.createShareLink(doc.id);
      final shareUrl = '${doc.filePath}/share/$token';
      ShareDocumentDialog.show(documentTitle: doc.title, shareUrl: shareUrl);
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_CTRL',
        'Share error: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Share Failed', e.toString());
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    if (!canDelete) {
      AppSnackbar.showWarning(
        'Permission Denied',
        'Your role does not have permission to delete documents.',
      );
      return;
    }

    try {
      await _dataset.softDeleteDocument(doc.id);
      favoriteDocuments.removeWhere((d) => d.id == doc.id);
      totalCount.value = (totalCount.value - 1).clamp(0, 999999);
      AppSnackbar.showWarning(
        'Moved to Trash',
        '${doc.title} moved to trash bin.',
      );
    } catch (e, st) {
      AppLogger.error(
        'FAVORITES_CTRL',
        'Error moving to trash: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error', e.toString());
    }
  }

  void confirmMoveToTrash(DocumentModel doc) {
    if (!canDelete) {
      AppSnackbar.showWarning(
        'Permission Denied',
        'Your role does not have permission to delete documents.',
      );
      return;
    }
    DocumentDeleteDialog.show(
      documentTitle: doc.title,
      onConfirm: () => moveToTrash(doc),
    );
  }

  void openEditDocumentDialog(DocumentModel doc) {
    if (!canEdit) {
      AppSnackbar.showWarning(
        'Permission Denied',
        'Your role does not have permission to edit documents.',
      );
      return;
    }

    DocumentEditDialog.show(
      document: doc,
      onSave: ({
        required title,
        description,
        documentNumber,
        applianceWarranty,
      }) async {
        try {
          await _dataset.updateDocumentDetails(
            documentId: doc.id,
            title: title,
            description: description,
            documentNumber: documentNumber,
            applianceWarranty: applianceWarranty,
          );
          await loadFavorites(resetPage: true);
          AppSnackbar.showSuccess(
            'Document Updated',
            'Document details were saved.',
          );
        } catch (e, st) {
          AppLogger.error(
            'FAVORITES_CTRL',
            'Update error: $e',
            error: e,
            stackTrace: st,
          );
          AppSnackbar.showError('Update Error', e.toString());
          rethrow;
        }
      },
    );
  }
}
