import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/appliance_vault_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/views/widgets/renew_appliance_warranty_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplianceDetailController extends GetxController {
  final ApplianceVaultDataset _dataset;

  ApplianceDetailController(this._dataset);

  final document = Rxn<DocumentModel>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final formError = ''.obs;

  // Editable Form Controllers
  final titleController = TextEditingController();
  final storeVendorController = TextEditingController();
  final invoiceNumberController = TextEditingController();
  final billingNameController = TextEditingController();
  final purchaseAmountController = TextEditingController();
  final customerCareController = TextEditingController();
  final policyNumberController = TextEditingController();
  final amcProviderController = TextEditingController();
  final notesController = TextEditingController();

  final purchaseDate = Rxn<DateTime>();
  final warrantyValidUpto = Rxn<DateTime>();
  final extendedWarrantyUpto = Rxn<DateTime>();
  final warrantyType = 'standard'.obs;

  // History & Lineage
  final historyDocs = <DocumentModel>[].obs;

  bool get canEdit {
    try {
      return AuthService.to.canEdit;
    } catch (error, stackTrace) {
      AppLogger.error(
        'APPLIANCE_DETAIL_CONTROLLER',
        'Operation failed; applying fallback.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  bool get canDelete {
    try {
      return AuthService.to.isAdmin;
    } catch (error, stackTrace) {
      AppLogger.error(
        'APPLIANCE_DETAIL_CONTROLLER',
        'Operation failed; applying fallback.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  @override
  void onClose() {
    titleController.dispose();
    storeVendorController.dispose();
    invoiceNumberController.dispose();
    billingNameController.dispose();
    purchaseAmountController.dispose();
    customerCareController.dispose();
    policyNumberController.dispose();
    amcProviderController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      final args = Get.arguments;
      if (args is DocumentModel) {
        _populateFromDocument(args);
        await loadHistory();
      } else {
        final docId = Get.parameters['id'];
        if (docId != null && docId.isNotEmpty) {
          final res = await _dataset.getApplianceVault(
            searchQuery: docId,
            pageSize: 1,
          );
          if (res.documents.isNotEmpty) {
            _populateFromDocument(res.documents.first);
            await loadHistory();
          }
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DETAIL_CTRL',
        'Error loading appliance details: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Error', 'Failed to load appliance details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _populateFromDocument(DocumentModel doc) {
    document.value = doc;
    final w = doc.applianceWarranty;

    titleController.text = doc.title;
    storeVendorController.text = w?.storeVendorName ?? '';
    invoiceNumberController.text = w?.invoiceNumber ?? doc.documentNumber ?? '';
    billingNameController.text = w?.billingName ?? '';
    purchaseAmountController.text =
        (w?.purchaseAmount != null && w!.purchaseAmount > 0)
        ? w.purchaseAmount.toStringAsFixed(0)
        : '';
    customerCareController.text = w?.customerCareNumber ?? '';
    policyNumberController.text = w?.policyNumber ?? '';
    amcProviderController.text = w?.amcProvider ?? '';
    notesController.text = w?.renewalNotes ?? doc.description ?? '';

    purchaseDate.value = w?.purchaseDate;
    warrantyValidUpto.value = w?.warrantyValidUpto;
    extendedWarrantyUpto.value = w?.extendedWarrantyUpto;
    warrantyType.value = w?.warrantyType ?? 'standard';
  }

  Future<void> loadHistory() async {
    final doc = document.value;
    if (doc == null) return;
    try {
      final list = await _dataset.getApplianceHistory(
        documentId: doc.id,
        serialNumber: doc.applianceWarranty?.serialNumber,
        invoiceNumber: doc.applianceWarranty?.invoiceNumber,
        productName: doc.applianceWarranty?.productName,
      );
      historyDocs.assignAll(list);
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DETAIL_CTRL',
        'Error loading history: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> saveApplianceDetails() async {
    if (isSaving.value) return;
    formError.value = '';
    final doc = document.value;
    if (doc == null) return;

    if (!canEdit) {
      formError.value = 'Your role cannot edit document details.';
      return;
    }

    isSaving.value = true;
    try {
      final amount =
          double.tryParse(purchaseAmountController.text.trim()) ??
          (doc.applianceWarranty?.purchaseAmount ?? 0.0);
      final updatedWarranty =
          (doc.applianceWarranty ??
                  ApplianceWarrantyModel(
                    billingName: billingNameController.text.trim(),
                    storeVendorName: storeVendorController.text.trim(),
                    invoiceNumber: invoiceNumberController.text.trim(),
                    purchaseDate: purchaseDate.value ?? DateTime.now(),
                    purchaseAmount: amount,
                  ))
              .copyWith(
                storeVendorName: storeVendorController.text.trim(),
                invoiceNumber: invoiceNumberController.text.trim(),
                billingName: billingNameController.text.trim(),
                purchaseAmount: amount,
                customerCareNumber: customerCareController.text.trim(),
                policyNumber: policyNumberController.text.trim().isNotEmpty
                    ? policyNumberController.text.trim()
                    : null,
                amcProvider: amcProviderController.text.trim().isNotEmpty
                    ? amcProviderController.text.trim()
                    : null,
                renewalNotes: notesController.text.trim().isNotEmpty
                    ? notesController.text.trim()
                    : null,
                purchaseDate: purchaseDate.value,
                warrantyValidUpto: warrantyValidUpto.value,
                extendedWarrantyUpto: extendedWarrantyUpto.value,
                warrantyType: warrantyType.value,
              );

      await _dataset.updateDocumentDetails(
        documentId: doc.id,
        title: titleController.text.trim(),
        description: notesController.text.trim(),
        documentNumber: invoiceNumberController.text.trim(),
        applianceWarranty: updatedWarranty,
      );

      document.value = doc.copyWith(
        title: titleController.text.trim(),
        description: notesController.text.trim(),
        documentNumber: invoiceNumberController.text.trim(),
        applianceWarranty: updatedWarranty,
      );

      AppSnackbar.showSuccess(
        'Changes Saved',
        'Appliance details updated successfully.',
      );
      await loadHistory();
    } catch (e, st) {
      AppLogger.error(
        'APPLIANCE_DETAIL_CTRL',
        'Error saving details: $e',
        error: e,
        stackTrace: st,
      );
      formError.value = 'Failed to save changes: $e';
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> openRenewWarrantyDialog() async {
    final doc = document.value;
    if (doc == null) return;

    final renewed = await RenewApplianceWarrantyDialog.show(
      previousDocument: doc,
      onRenew:
          ({
            required previousDocument,
            required newWarranty,
            required newTitle,
            required fileBytes,
            required fileName,
            newDescription,
          }) async {
            final created = await _dataset.renewApplianceWarranty(
              previousDocument: previousDocument,
              newWarranty: newWarranty,
              newTitle: newTitle,
              fileBytes: fileBytes,
              fileName: fileName,
              newDescription: newDescription,
            );
            _populateFromDocument(created);
          },
    );

    if (renewed == true) {
      AppSnackbar.showSuccess(
        'Warranty Renewed',
        'New warranty cycle logged successfully.',
      );
      await loadHistory();
    }
  }

  Future<void> previewDocument([DocumentModel? targetDoc]) async {
    final doc = targetDoc ?? document.value;
    if (doc == null) return;

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
        'APPLIANCE_DETAIL_CTRL',
        'Error opening preview: $e',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.showError('Preview Error', e.toString());
    }
  }

  Future<void> downloadDocument([DocumentModel? targetDoc]) async {
    final doc = targetDoc ?? document.value;
    if (doc == null) return;

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
        'APPLIANCE_DETAIL_CTRL',
        'Error downloading: $e',
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
          'APPLIANCE_DETAIL_CONTROLLER',
          'Operation failed; applying fallback.',
          error: error,
          stackTrace: stackTrace,
        );
        AppSnackbar.showError('Download Error', e.toString());
      }
    }
  }

  void confirmMoveToTrash() {
    final doc = document.value;
    if (doc == null) return;
    if (!canDelete) {
      AppSnackbar.showWarning(
        'Permission Denied',
        'Your role does not have permission to delete documents.',
      );
      return;
    }

    DocumentDeleteDialog.show(
      documentTitle: doc.title,
      onConfirm: () async {
        try {
          await _dataset.softDeleteDocument(doc.id);
          Get.back();
          AppSnackbar.showWarning(
            'Moved to Trash',
            '${doc.title} moved to trash bin.',
          );
        } catch (e, st) {
          AppLogger.error(
            'APPLIANCE_DETAIL_CTRL',
            'Error moving to trash: $e',
            error: e,
            stackTrace: st,
          );
          AppSnackbar.showError('Error', e.toString());
        }
      },
    );
  }
}
