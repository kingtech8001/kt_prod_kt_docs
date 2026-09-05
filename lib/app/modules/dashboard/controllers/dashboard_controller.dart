import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/dashboard_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/dashboard_metrics_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardController extends GetxController {
  final DashboardDataset _dataset;

  DashboardController(this._dataset);

  final isLoading = true.obs;
  final metrics = DashboardMetricsModel().obs;
  final recentDocuments = <DocumentModel>[].obs;
  final expiringWarranties = <DocumentModel>[].obs;
  final pendingUtilityBills = <DocumentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    AppLogger.debug('DASHBOARD_CTRL', 'Loading dashboard data via DashboardDataset...');
    isLoading.value = true;
    try {
      final metricsData = await _dataset.getDashboardMetrics();
      metrics.value = metricsData;

      // Fetch Recent Documents
      final docs = await _dataset.getRecentDocuments(limit: 8);
      recentDocuments.assignAll(docs);

      // Fetch Expiring Warranties (due in <= 30 days)
      final expiring = await _dataset.getExpiringWarranties(limit: 50);
      expiringWarranties.assignAll(expiring);

      // Fetch Pending Utility Bills
      final pending = await _dataset.getPendingUtilityBills(limit: 50);
      pendingUtilityBills.assignAll(pending);

      AppLogger.info('DASHBOARD_CTRL', 'Dashboard data loaded successfully.');
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_CTRL',
        'Error loading dashboard data: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error Loading Dashboard', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> previewDocument(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Previewing document: ${doc.title}');
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
        'DASHBOARD_CTRL',
        'Preview failed: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Preview Failed', e.toString());
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Downloading document: ${doc.title}');
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
        'DASHBOARD_CTRL',
        'Download failed: $e',
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

  Future<void> shareDocument(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Sharing document: ${doc.title}');
    try {
      final signedUrl = await _dataset.getSignedPreviewUrl(doc.filePath);
      ShareDocumentDialog.show(documentTitle: doc.title, shareUrl: signedUrl);
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_CTRL',
        'Share failed: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Share Failed', e.toString());
    }
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Toggling favorite for: ${doc.title}');
    try {
      final isFav = await _dataset.toggleFavorite(doc.id, doc.isFavorite);
      final index = recentDocuments.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        recentDocuments[index] = recentDocuments[index].copyWith(
          isFavorite: isFav,
        );
      }
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_CTRL',
        'Favorite toggle failed: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error', e.toString());
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Moving to trash: ${doc.title}');
    try {
      await _dataset.softDeleteDocument(doc.id);
      recentDocuments.removeWhere((d) => d.id == doc.id);
      expiringWarranties.removeWhere((d) => d.id == doc.id);
      pendingUtilityBills.removeWhere((d) => d.id == doc.id);

      AppSnackbar.showWarning(
        'Moved to Trash',
        '${doc.title} moved to trash bin',
      );
      loadDashboardData();
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_CTRL',
        'Move to trash failed: $e',
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
      }) async {
        try {
          await _dataset.updateDocumentDetails(
            documentId: doc.id,
            title: title,
            description: description,
            documentNumber: documentNumber,
            applianceWarranty: applianceWarranty,
          );
          await loadDashboardData();
          AppSnackbar.showSuccess(
            'Document Updated',
            'Document details were saved.',
          );
        } catch (e, st) {
          AppLogger.error(
            'DASHBOARD_CTRL',
            'Document update failed: $e',
            error: e,
            stackTrace: st,
          );
          // Inline error is displayed inside DocumentEditDialog; rethrow so dialog can handle it
          rethrow;
        }
      },
    );
  }
}
