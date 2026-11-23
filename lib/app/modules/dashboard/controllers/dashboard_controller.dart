import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/dashboard_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/dashboard_metrics_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
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
    AppLogger.debug(
      'DASHBOARD_CTRL',
      'Loading dashboard data via DashboardDataset...',
    );
    isLoading.value = true;
    try {
      final bundle = await _dataset.getDashboardBundle();

      metrics.value = bundle.metrics;
      recentDocuments.assignAll(bundle.recentDocuments);
      expiringWarranties.assignAll(bundle.expiringWarranties);
      pendingUtilityBills.assignAll(bundle.pendingUtilityBills);

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
      final resolvedUrl =
          (doc.isGoogleAttachment ||
              doc.filePath.startsWith('gdrive://') ||
              doc.filePath.startsWith('http://') ||
              doc.filePath.startsWith('https://'))
          ? (doc.googleAttachmentUrl ??
                (doc.filePath.startsWith('gdrive://')
                    ? 'https://drive.google.com/file/d/${doc.filePath.replaceFirst("gdrive://", "")}/preview'
                    : doc.filePath))
          : await _dataset.getSignedPreviewUrl(doc.filePath);

      if (doc.isImage) {
        ImageLightboxDialog.show(
          title: doc.title,
          imageUrl: resolvedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
      } else {
        PdfViewerDialog.show(
          title: doc.title,
          filePath: doc.filePath,
          signedPdfUrl: resolvedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
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

  /// Opens the appropriate full detail screen for an expiry alert.
  Future<void> openExpiringDocumentDetail(DocumentModel doc) async {
    try {
      if (doc.applianceWarranty != null) {
        await Get.toNamed(AppRoutes.APPLIANCE_DETAIL, arguments: doc);
      } else if (doc.personalMetadata != null) {
        await Get.toNamed(AppRoutes.PERSONAL_DOC_DETAIL, arguments: doc);
      } else if (doc.vehicleMetadata != null) {
        final vehicle = await _dataset.getVehicleByNumber(
          doc.vehicleMetadata!.vehicleNumber,
        );
        if (vehicle == null) {
          AppSnackbar.showError(
            'Vehicle Not Found',
            'The vehicle for this document is no longer available.',
          );
          return;
        }
        await Get.toNamed(AppRoutes.VEHICLE_DETAIL, arguments: vehicle);
      } else {
        AppSnackbar.showError(
          'Details Unavailable',
          'This alert does not have a supported detail screen.',
        );
        return;
      }

      await loadDashboardData();
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_CTRL',
        'Failed to open expiry alert details for ${doc.id}: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Unable to Open Details', e.toString());
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Downloading document: ${doc.title}');
    try {
      if (doc.isGoogleAttachment ||
          doc.filePath.startsWith('gdrive://') ||
          doc.filePath.startsWith('http://') ||
          doc.filePath.startsWith('https://')) {
        final gUrl =
            doc.googleAttachmentUrl ??
            (doc.filePath.startsWith('gdrive://')
                ? 'https://drive.google.com/file/d/${doc.filePath.replaceFirst("gdrive://", "")}/view?usp=sharing'
                : doc.filePath);
        final uri = Uri.tryParse(gUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      final signedUrl = await _dataset.getSignedPreviewUrl(
        doc.filePath,
        download: true,
      );
      await FileApiHelper.downloadFileFromUrl(
        url: signedUrl,
        fileName: doc.fileName,
        mimeType: doc.mimeType,
      );
      AppSnackbar.showSuccess(
        'Download Started',
        '${doc.fileName} is downloading.',
      );
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_CTRL',
        'Download failed: $e',
        error: e,
        stackTrace: st,
      );
      try {
        final fallbackUrl = await _dataset.getSignedPreviewUrl(
          doc.filePath,
          download: true,
        );
        final uri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (error, stackTrace) {
        AppLogger.error(
          'DASHBOARD_CONTROLLER',
          'Operation failed; applying fallback.',
          error: error,
          stackTrace: stackTrace,
        );
        AppSnackbar.showError('Download Failed', e.toString());
      }
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

  Future<void> dismissReminder(DocumentModel doc) async {
    AppLogger.info(
      'DASHBOARD_CTRL',
      'Dismissing reminder for document: "${doc.title}" (ID: ${doc.id})',
    );
    try {
      // 1. Immediately remove from reactive lists for instant feedback
      expiringWarranties.removeWhere((d) => d.id == doc.id);
      recentDocuments.removeWhere((d) => d.id == doc.id);

      // 2. Adjust observable metrics
      final currentM = metrics.value;
      final newExpCount = currentM.expiringWarrantiesCount > 0
          ? currentM.expiringWarrantiesCount - 1
          : 0;
      metrics.value = DashboardMetricsModel(
        totalDocuments: currentM.totalDocuments,
        totalStorageBytes: currentM.totalStorageBytes,
        totalFolders: currentM.totalFolders,
        expiringWarrantiesCount: newExpCount,
        activeWarrantiesCount: currentM.activeWarrantiesCount,
        pendingBillsCount: currentM.pendingBillsCount,
        pendingBillsAmount: currentM.pendingBillsAmount,
        trashCount: currentM.trashCount,
        trashSizeBytes: currentM.trashSizeBytes,
      );

      // 3. Persist asynchronously in database
      await _dataset.dismissReminder(doc.id);

      AppSnackbar.showSuccess(
        'Reminder Dismissed',
        '"${doc.title}" removed from alerts and recents.',
      );
    } catch (e, st) {
      AppLogger.error(
        'DASHBOARD_CTRL',
        'Error dismissing reminder: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Action Failed', 'Could not dismiss reminder.');
    }
  }

  void openEditDocumentDialog(DocumentModel doc) async {
    final updated = await DocumentEditDialog.show(
      document: doc,
      onSave:
          ({
            required title,
            description,
            documentNumber,
            applianceWarranty,
            vehicleMetadata,
            newFileName,
            newFileBytes,
            newMimeType,
            attachmentUrl,
          }) async {
            try {
              await _dataset.updateDocumentDetails(
                documentId: doc.id,
                title: title,
                description: description,
                documentNumber: documentNumber,
                applianceWarranty: applianceWarranty,
                vehicleMetadata: vehicleMetadata,
                newFileName: newFileName,
                newFileBytes: newFileBytes,
                newMimeType: newMimeType,
                categoryCode: doc.categoryCode,
                subCategory: doc.subCategory,
                attachmentUrl: attachmentUrl,
              );
              await loadDashboardData();
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

    if (updated == true) {
      await loadDashboardData();
    }
  }
}
