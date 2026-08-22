import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/dashboard_metrics_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardController extends GetxController {
  final DocumentRepository _documentRepository;

  DashboardController(this._documentRepository);

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
    AppLogger.debug('DASHBOARD_CTRL', 'Loading dashboard data...');
    isLoading.value = true;
    try {
      final metricsData = await _documentRepository.getDashboardMetrics();
      metrics.value = metricsData;

      // Fetch Recent Documents
      final docs = await _documentRepository.getDocuments(limit: 8);
      recentDocuments.assignAll(docs);

      // Filter Expiring Warranties (<= 30 days remaining & not expired)
      final allWarranties = await _documentRepository.getDocuments(
        categoryCode: 'appliance_warranty',
        limit: 50,
      );
      final expiring = allWarranties.where((doc) {
        final w = doc.applianceWarranty;
        return w != null && w.isExpiringSoon;
      }).toList();
      expiringWarranties.assignAll(expiring);

      // Filter Pending Utility Bills
      final allUtilities = await _documentRepository.getDocuments(
        categoryCode: 'utility_bills',
        limit: 50,
      );
      final pending = allUtilities.where((doc) {
        final u = doc.utilityMetadata;
        return u != null && !u.isPaid;
      }).toList();
      pendingUtilityBills.assignAll(pending);

      AppLogger.info('DASHBOARD_CTRL', 'Dashboard data loaded successfully.');
    } catch (e, st) {
      AppLogger.error('DASHBOARD_CTRL', 'Error loading dashboard data: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error Loading Dashboard',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> previewDocument(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Previewing document: ${doc.title}');
    try {
      final signedUrl = await _documentRepository.getSignedPreviewUrl(doc.filePath);
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
    } catch (e, st) {
      AppLogger.error('DASHBOARD_CTRL', 'Preview failed: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Preview Failed',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Downloading document: ${doc.title}');
    try {
      final signedUrl = await _documentRepository.getSignedPreviewUrl(doc.filePath);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e, st) {
      AppLogger.error('DASHBOARD_CTRL', 'Download failed: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Download Failed',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> shareDocument(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Sharing document: ${doc.title}');
    try {
      final signedUrl = await _documentRepository.getSignedPreviewUrl(doc.filePath);
      ShareDocumentDialog.show(
        documentTitle: doc.title,
        shareUrl: signedUrl,
      );
    } catch (e, st) {
      AppLogger.error('DASHBOARD_CTRL', 'Share failed: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Share Failed',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Toggling favorite for: ${doc.title}');
    try {
      final isFav = await _documentRepository.toggleFavorite(doc.id, doc.isFavorite);
      final index = recentDocuments.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        recentDocuments[index] = recentDocuments[index].copyWith(isFavorite: isFav);
      }
    } catch (e, st) {
      AppLogger.error('DASHBOARD_CTRL', 'Favorite toggle failed: $e', error: e, stackTrace: st);
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    AppLogger.debug('DASHBOARD_CTRL', 'Moving to trash: ${doc.title}');
    try {
      await _documentRepository.softDeleteDocument(doc.id);
      recentDocuments.removeWhere((d) => d.id == doc.id);
      expiringWarranties.removeWhere((d) => d.id == doc.id);
      pendingUtilityBills.removeWhere((d) => d.id == doc.id);
      Get.snackbar('Moved to Trash', '${doc.title} moved to trash bin',
          backgroundColor: AppColors.warning, colorText: Colors.white);
      loadDashboardData();
    } catch (e, st) {
      AppLogger.error('DASHBOARD_CTRL', 'Move to trash failed: $e', error: e, stackTrace: st);
      Get.snackbar('Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }
}
