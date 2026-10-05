import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/personal_docs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonalDocsController extends GetxController {
  final PersonalDocsDataset _dataset;

  PersonalDocsController(this._dataset);

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
  final personalDocuments = <DocumentModel>[].obs;
  final dynamicPersons = <String>[].obs;
  final dynamicDocTypes = <String>[].obs;

  // Reactive Filters
  final selectedPerson = 'All Persons'.obs;
  final selectedDocType = 'All Document Types'.obs;
  final searchQuery = ''.obs;
  final isGridView = true.obs;

  // Aggregated Summary Metrics
  final totalDocumentsCount = 0.obs;
  final totalPersonsCoveredCount = 0.obs;
  final expiringSoonCount = 0.obs;
  final expiredCount = 0.obs;

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
    loadMasterData();
    loadPersonalDocuments(resetPage: true);
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
    if (!scrollController.hasClients) return;
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    if (maxScroll > 100 && currentScroll >= maxScroll - 200) {
      loadNextPage();
    }
  }

  Future<void> loadMasterData() async {
    try {
      final pList = await _dataset.getMasterPersons(activeOnly: true);
      dynamicPersons.assignAll(pList.map((p) => p.fullName));

      final dtList = await _dataset.getMasterPersonalDocTypes(activeOnly: true);
      dynamicDocTypes.assignAll(dtList.map((t) => t.name));
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_CTRL',
        'Error loading master data: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> loadPersonalDocuments({bool resetPage = false}) async {
    if (resetPage) {
      currentPage.value = 1;
      hasMore.value = true;
      isLoading.value = true;
    }

    AppLogger.debug(
      'PERSONAL_DOCS_CTRL',
      'Loading personal documents (page: ${currentPage.value}, person: ${selectedPerson.value}, docType: ${selectedDocType.value}, search: ${searchQuery.value})',
    );

    try {
      final response = await _dataset.getPersonalDocuments(
        page: currentPage.value,
        pageSize: pageSize,
        personName: selectedPerson.value != 'All Persons'
            ? selectedPerson.value
            : null,
        docType: selectedDocType.value != 'All Document Types'
            ? selectedDocType.value
            : null,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      personalDocuments.assignAll(response.documents);
      totalCount.value = response.totalCount;
      totalDocumentsCount.value = response.totalDocumentsCount;
      totalPersonsCoveredCount.value = response.totalPersonsCoveredCount;
      expiringSoonCount.value = response.expiringSoonCount;
      expiredCount.value = response.expiredCount;

      hasMore.value = personalDocuments.length < totalCount.value;
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_CTRL',
        'Error loading personal documents: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Documents', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    final nextPage = currentPage.value + 1;

    AppLogger.debug('PERSONAL_DOCS_CTRL', 'Loading next page: $nextPage...');

    try {
      final response = await _dataset.getPersonalDocuments(
        page: nextPage,
        pageSize: pageSize,
        personName: selectedPerson.value != 'All Persons'
            ? selectedPerson.value
            : null,
        docType: selectedDocType.value != 'All Document Types'
            ? selectedDocType.value
            : null,
        searchQuery: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      if (response.documents.isEmpty) {
        hasMore.value = false;
      } else {
        personalDocuments.addAll(response.documents);
        currentPage.value = nextPage;
        hasMore.value = personalDocuments.length < totalCount.value;
      }
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_CTRL',
        'Error loading more documents: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Failed to load more', e.toString());
    } finally {
      isLoadingMore.value = false;
    }
  }

  void onPersonSelected(String person) {
    if (selectedPerson.value == person) return;
    selectedPerson.value = person;
    loadPersonalDocuments(resetPage: true);
  }

  void onDocTypeSelected(String type) {
    if (selectedDocType.value == type) return;
    selectedDocType.value = type;
    loadPersonalDocuments(resetPage: true);
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadPersonalDocuments(resetPage: true);
    });
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    loadPersonalDocuments(resetPage: true);
  }

  void toggleViewMode([bool? grid]) {
    if (grid != null) {
      isGridView.value = grid;
    } else {
      isGridView.value = !isGridView.value;
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
          await launchUrl(uri);
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_CTRL',
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
        'PERSONAL_DOCS_CTRL',
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

  void shareDocument(DocumentModel doc) {
    openShareDialog(doc);
  }

  Future<void> openShareDialog(DocumentModel doc) async {
    try {
      final token = await _dataset.createShareLink(doc.id);
      final shareUrl = '${AppConstants.webBaseUrl}/share/$token';
      ShareDocumentDialog.show(documentTitle: doc.title, shareUrl: shareUrl);
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_CTRL',
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
      final index = personalDocuments.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        personalDocuments[index] = doc.copyWith(isFavorite: updated);
      }
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_CTRL',
        'Error toggling favorite: $e',
        error: e,
        stackTrace: st,
      );
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
      personalDocuments.removeWhere((d) => d.id == doc.id);
      totalCount.value = (totalCount.value - 1).clamp(0, 999999);
      AppSnackbar.showWarning(
        'Moved to Trash',
        '${doc.title} moved to trash bin.',
      );
    } catch (e, st) {
      AppLogger.error(
        'PERSONAL_DOCS_CTRL',
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
}
