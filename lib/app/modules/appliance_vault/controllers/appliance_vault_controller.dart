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

class ApplianceVaultController extends GetxController {
  final DocumentRepository _documentRepository;
  final MasterDataRepository _masterDataRepository;

  ApplianceVaultController(this._documentRepository, this._masterDataRepository);

  final isLoading = true.obs;
  final applianceDocuments = <DocumentModel>[].obs;
  final dynamicBrands = <String>[].obs;
  final dynamicSubcategories = <String>[].obs;

  // Filters
  final selectedBrand = 'All Brands'.obs;
  final selectedSubcategory = 'All Appliances'.obs;
  final selectedWarrantyStatus = 'all'.obs; // 'all', 'active', 'expiring_soon', 'expired'

  // Summary Metrics
  final totalAppliancesCount = 0.obs;
  final activeWarrantiesCount = 0.obs;
  final expiringSoonCount = 0.obs;
  final expiredCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadMasterData();
    loadApplianceVault();
  }

  Future<void> loadMasterData() async {
    try {
      final brandsList = await _masterDataRepository.getBrands(activeOnly: true);
      dynamicBrands.assignAll(brandsList.map((b) => b.name));

      final subsList = await _masterDataRepository.getApplianceSubcategories(activeOnly: true);
      dynamicSubcategories.assignAll(subsList.map((s) => s.name));
    } catch (e, st) {
      AppLogger.error('APPLIANCE_CTRL', 'Error loading master data: $e', error: e, stackTrace: st);
    }
  }

  Future<void> loadApplianceVault() async {
    AppLogger.debug('APPLIANCE_CTRL', 'Loading appliance vault for brand: ${selectedBrand.value}, sub: ${selectedSubcategory.value}');
    isLoading.value = true;
    try {
      final docs = await _documentRepository.getDocuments(
        categoryCode: 'appliance_warranty',
        brand: selectedBrand.value != 'All Brands' ? selectedBrand.value : null,
        subCategory: selectedSubcategory.value != 'All Appliances'
            ? selectedSubcategory.value
            : null,
      );

      var filtered = docs.where((d) => d.applianceWarranty != null).toList();

      if (selectedWarrantyStatus.value == 'active') {
        filtered = filtered.where((d) => !d.applianceWarranty!.isExpired).toList();
      } else if (selectedWarrantyStatus.value == 'expiring_soon') {
        filtered = filtered.where((d) => d.applianceWarranty!.isExpiringSoon).toList();
      } else if (selectedWarrantyStatus.value == 'expired') {
        filtered = filtered.where((d) => d.applianceWarranty!.isExpired).toList();
      }

      applianceDocuments.assignAll(filtered);
      _computeSummaryMetrics(filtered);
    } catch (e, st) {
      AppLogger.error('APPLIANCE_CTRL', 'Error loading appliance vault: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error Loading Appliance Vault',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _computeSummaryMetrics(List<DocumentModel> docs) {
    int total = docs.length;
    int active = 0;
    int expiring = 0;
    int expired = 0;

    for (var doc in docs) {
      final w = doc.applianceWarranty;
      if (w != null) {
        if (w.isExpired) {
          expired++;
        } else if (w.isExpiringSoon) {
          expiring++;
          active++;
        } else {
          active++;
        }
      }
    }

    totalAppliancesCount.value = total;
    activeWarrantiesCount.value = active;
    expiringSoonCount.value = expiring;
    expiredCount.value = expired;
  }

  void onBrandSelected(String brand) {
    selectedBrand.value = brand;
    loadApplianceVault();
  }

  void onSubcategorySelected(String subcategory) {
    selectedSubcategory.value = subcategory;
    loadApplianceVault();
  }

  void onWarrantyStatusSelected(String status) {
    selectedWarrantyStatus.value = status;
    loadApplianceVault();
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
      AppLogger.error('APPLIANCE_CTRL', 'Error opening preview: $e', error: e, stackTrace: st);
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
      AppLogger.error('APPLIANCE_CTRL', 'Error downloading: $e', error: e, stackTrace: st);
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
      AppLogger.error('APPLIANCE_CTRL', 'Error creating share link: $e', error: e, stackTrace: st);
      Get.snackbar('Share Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    try {
      await _documentRepository.softDeleteDocument(doc.id);
      applianceDocuments.removeWhere((d) => d.id == doc.id);
      Get.snackbar(
        'Moved to Trash',
        '${doc.title} moved to trash bin.',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
    } catch (e, st) {
      AppLogger.error('APPLIANCE_CTRL', 'Error moving to trash: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
