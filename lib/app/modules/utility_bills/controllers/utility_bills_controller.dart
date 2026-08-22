import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/providers/supabase_provider.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/share_document_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class UtilityBillsController extends GetxController {
  final DocumentRepository _documentRepository;
  final SupabaseProvider _supabaseProvider;
  final MasterDataRepository _masterDataRepository;

  UtilityBillsController(
    this._documentRepository,
    this._supabaseProvider,
    this._masterDataRepository,
  );

  final isLoading = true.obs;
  final utilityBills = <DocumentModel>[].obs;
  final dynamicCities = <String>[].obs;
  final dynamicUtilityTypes = <String>[].obs;

  // Filters
  final selectedCity = 'All Cities'.obs;
  final selectedUtilityType = 'All Utilities'.obs;
  final selectedPaymentStatus = 'all'.obs; // 'all', 'paid', 'pending', 'overdue'

  // Summary Metrics
  final totalBillsAmount = 0.0.obs;
  final pendingBillsAmount = 0.0.obs;
  final paidCount = 0.obs;
  final pendingCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadMasterData();
    loadUtilityBills();
  }

  Future<void> loadMasterData() async {
    try {
      final cities = await _masterDataRepository.getCities(activeOnly: true);
      dynamicCities.assignAll(cities.map((c) => c.name));

      final providers = await _masterDataRepository.getUtilityProviders(activeOnly: true);
      final types = providers.map((p) => p.utilityType).toSet().toList();
      dynamicUtilityTypes.assignAll(types);
    } catch (e, st) {
      AppLogger.error('UTILITY_CTRL', 'Error loading master data: $e', error: e, stackTrace: st);
    }
  }

  Future<void> loadUtilityBills() async {
    AppLogger.debug('UTILITY_CTRL', 'Loading utility bills for city: ${selectedCity.value}, type: ${selectedUtilityType.value}');
    isLoading.value = true;
    try {
      final docs = await _documentRepository.getDocuments(
        categoryCode: 'utility_bills',
        city: selectedCity.value != 'All Cities' ? selectedCity.value : null,
        subCategory: selectedUtilityType.value != 'All Utilities'
            ? selectedUtilityType.value
            : null,
      );

      var filtered = docs.where((d) => d.utilityMetadata != null).toList();

      if (selectedPaymentStatus.value == 'paid') {
        filtered = filtered.where((d) => d.utilityMetadata!.isPaid).toList();
      } else if (selectedPaymentStatus.value == 'pending') {
        filtered = filtered.where((d) => !d.utilityMetadata!.isPaid).toList();
      } else if (selectedPaymentStatus.value == 'overdue') {
        filtered = filtered.where((d) => d.utilityMetadata!.isOverdue).toList();
      }

      utilityBills.assignAll(filtered);
      _computeSummaryMetrics(filtered);
    } catch (e, st) {
      AppLogger.error('UTILITY_CTRL', 'Error loading utility bills: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error Loading Utility Bills',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _computeSummaryMetrics(List<DocumentModel> docs) {
    double total = 0;
    double pending = 0;
    int paid = 0;
    int pend = 0;

    for (var doc in docs) {
      final u = doc.utilityMetadata;
      if (u != null) {
        total += u.billAmount;
        if (u.isPaid) {
          paid++;
        } else {
          pending += u.billAmount;
          pend++;
        }
      }
    }

    totalBillsAmount.value = total;
    pendingBillsAmount.value = pending;
    paidCount.value = paid;
    pendingCount.value = pend;
  }

  void onCitySelected(String city) {
    selectedCity.value = city;
    loadUtilityBills();
  }

  void onUtilityTypeSelected(String type) {
    selectedUtilityType.value = type;
    loadUtilityBills();
  }

  void onPaymentStatusSelected(String status) {
    selectedPaymentStatus.value = status;
    loadUtilityBills();
  }

  Future<void> togglePaymentStatus(DocumentModel doc) async {
    final meta = doc.utilityMetadata;
    if (meta == null || meta.id == null) return;

    final newStatus = !meta.isPaid;
    AppLogger.debug('UTILITY_CTRL', 'Toggling payment status for doc ${doc.id} -> $newStatus');

    try {
      await _supabaseProvider.client.from('utility_metadata').update({
        'is_paid': newStatus,
        'paid_at': newStatus ? DateTime.now().toIso8601String() : null,
      }).eq('id', meta.id!);

      Get.snackbar(
        'Payment Updated',
        newStatus ? 'Bill marked as Paid' : 'Bill marked as Pending Payment',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );

      loadUtilityBills();
    } catch (e, st) {
      AppLogger.error('UTILITY_CTRL', 'Error updating payment status: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
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
      AppLogger.error('UTILITY_CTRL', 'Error opening preview: $e', error: e, stackTrace: st);
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
      AppLogger.error('UTILITY_CTRL', 'Error downloading document: $e', error: e, stackTrace: st);
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
      AppLogger.error('UTILITY_CTRL', 'Error creating share link: $e', error: e, stackTrace: st);
      Get.snackbar('Share Error', e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    try {
      await _documentRepository.softDeleteDocument(doc.id);
      utilityBills.removeWhere((d) => d.id == doc.id);
      Get.snackbar(
        'Moved to Trash',
        '${doc.title} moved to trash bin.',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
    } catch (e, st) {
      AppLogger.error('UTILITY_CTRL', 'Error moving to trash: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
