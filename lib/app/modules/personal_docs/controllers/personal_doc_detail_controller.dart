import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/personal_docs_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/modules/personal_docs/views/widgets/renew_personal_doc_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonalDocDetailController extends GetxController {
  final PersonalDocsDataset _dataset;

  PersonalDocDetailController(this._dataset);

  final document = Rxn<DocumentModel>();
  final isLoading = true.obs;
  final isSaving = false.obs;

  // Editable Form Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final personNameController = TextEditingController();
  final relationshipController = TextEditingController();
  final docTypeNameController = TextEditingController();
  final idNumberController = TextEditingController();
  final issuingAuthorityController = TextEditingController();

  // Insurance Specific Controllers
  final insuranceCompanyController = TextEditingController();
  final policyTypeController = TextEditingController();
  final sumInsuredController = TextEditingController();
  final premiumAmountController = TextEditingController();
  final tpaNameController = TextEditingController();
  final notesController = TextEditingController();

  final issueDate = Rxn<DateTime>();
  final expiryDate = Rxn<DateTime>();

  // Lineage / History
  final renewalHistory = <DocumentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  void _loadInitialData() {
    isLoading.value = true;
    final args = Get.arguments;
    if (args is DocumentModel) {
      _populateFromDocument(args);
      _loadHistory(args);
    } else {
      final docId = Get.parameters['id'];
      if (docId != null && docId.isNotEmpty) {
        _fetchDocById(docId);
        return;
      }
      isLoading.value = false;
    }
  }

  void _populateFromDocument(DocumentModel doc) {
    document.value = doc;
    final meta = doc.personalMetadata;

    titleController.text = doc.title;
    descriptionController.text = doc.description ?? '';
    personNameController.text = meta?.personName ?? '';
    relationshipController.text = meta?.relationship ?? '';
    docTypeNameController.text = meta?.docTypeName ?? doc.subCategory;
    idNumberController.text = meta?.idNumber ?? meta?.policyNumber ?? '';
    issuingAuthorityController.text = meta?.issuingAuthority ?? '';

    insuranceCompanyController.text = meta?.insuranceCompany ?? '';
    policyTypeController.text = meta?.policyType ?? '';
    sumInsuredController.text =
        meta?.sumInsured != null ? meta!.sumInsured!.toStringAsFixed(0) : '';
    premiumAmountController.text = meta?.premiumAmount != null
        ? meta!.premiumAmount!.toStringAsFixed(0)
        : '';
    tpaNameController.text = meta?.tpaName ?? '';
    notesController.text = meta?.notes ?? '';

    issueDate.value = meta?.issueDate;
    expiryDate.value = meta?.expiryDate;
  }

  Future<void> _fetchDocById(String id) async {
    try {
      final response = await _dataset.getPersonalDocuments(page: 1, pageSize: 100);
      final match = response.documents.firstWhereOrNull((d) => d.id == id);
      if (match != null) {
        _populateFromDocument(match);
        await _loadHistory(match);
      }
    } catch (e, st) {
      AppLogger.error('PERSONAL_DETAIL_CTRL', 'Error fetching doc: $e',
          error: e, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadHistory(DocumentModel doc) async {
    try {
      isLoading.value = true;
      final personName = doc.personalMetadata?.personName;
      final docTypeName = doc.personalMetadata?.docTypeName ?? doc.subCategory;

      if (personName != null && docTypeName.isNotEmpty) {
        final history = await _dataset.getPersonalDocTypeHistory(
          personName: personName,
          docTypeName: docTypeName,
        );
        renewalHistory.assignAll(history);
      } else {
        renewalHistory.assignAll([doc]);
      }
    } catch (e, st) {
      AppLogger.error('PERSONAL_DETAIL_CTRL', 'Error loading history: $e',
          error: e, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reloadData() async {
    final current = document.value;
    if (current == null) return;
    await _loadHistory(current);
  }

  bool get isInsurance {
    final type = docTypeNameController.text.toLowerCase();
    final sub = document.value?.subCategory.toLowerCase() ?? '';
    return type.contains('insurance') ||
        type.contains('mediclaim') ||
        type.contains('policy') ||
        sub.contains('insurance');
  }

  Future<void> saveDocumentDetails() async {
    final current = document.value;
    if (current == null) return;

    final newTitle = titleController.text.trim();
    final personName = personNameController.text.trim();
    final docType = docTypeNameController.text.trim();

    if (newTitle.isEmpty) {
      AppSnackbar.showError('Validation Error', 'Document title is required.');
      return;
    }
    if (personName.isEmpty) {
      AppSnackbar.showError('Validation Error', 'Person name is required.');
      return;
    }
    if (docType.isEmpty) {
      AppSnackbar.showError('Validation Error', 'Document type is required.');
      return;
    }

    isSaving.value = true;
    try {
      final sumInsured = double.tryParse(sumInsuredController.text.trim());
      final premium = double.tryParse(premiumAmountController.text.trim());

      await _dataset.updatePersonalDocumentMetadata(
        documentId: current.id,
        title: newTitle,
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null,
        personName: personName,
        relationship: relationshipController.text.trim().isNotEmpty
            ? relationshipController.text.trim()
            : null,
        docTypeName: docType,
        idNumber: idNumberController.text.trim().isNotEmpty
            ? idNumberController.text.trim()
            : null,
        issuingAuthority: issuingAuthorityController.text.trim().isNotEmpty
            ? issuingAuthorityController.text.trim()
            : null,
        issueDate: issueDate.value,
        expiryDate: expiryDate.value,
        insuranceCompany: insuranceCompanyController.text.trim().isNotEmpty
            ? insuranceCompanyController.text.trim()
            : null,
        policyType: policyTypeController.text.trim().isNotEmpty
            ? policyTypeController.text.trim()
            : null,
        sumInsured: sumInsured,
        premiumAmount: premium,
        tpaName: tpaNameController.text.trim().isNotEmpty
            ? tpaNameController.text.trim()
            : null,
        notes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );

      // Refresh current document
      final updatedMeta = current.personalMetadata?.copyWith(
            personName: personName,
            relationship: relationshipController.text.trim().isNotEmpty
                ? relationshipController.text.trim()
                : null,
            docTypeName: docType,
            idNumber: idNumberController.text.trim().isNotEmpty
                ? idNumberController.text.trim()
                : null,
            issuingAuthority: issuingAuthorityController.text.trim().isNotEmpty
                ? issuingAuthorityController.text.trim()
                : null,
            issueDate: issueDate.value,
            expiryDate: expiryDate.value,
            insuranceCompany: insuranceCompanyController.text.trim().isNotEmpty
                ? insuranceCompanyController.text.trim()
                : null,
            policyType: policyTypeController.text.trim().isNotEmpty
                ? policyTypeController.text.trim()
                : null,
            sumInsured: sumInsured,
            premiumAmount: premium,
            tpaName: tpaNameController.text.trim().isNotEmpty
                ? tpaNameController.text.trim()
                : null,
            notes: notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
          ) ??
          PersonalDocumentMetadataModel(
            id: current.id,
            documentId: current.id,
            personName: personName,
            docTypeName: docType,
            relationship: relationshipController.text.trim().isNotEmpty
                ? relationshipController.text.trim()
                : null,
            idNumber: idNumberController.text.trim().isNotEmpty
                ? idNumberController.text.trim()
                : null,
            issuingAuthority: issuingAuthorityController.text.trim().isNotEmpty
                ? issuingAuthorityController.text.trim()
                : null,
            issueDate: issueDate.value,
            expiryDate: expiryDate.value,
            insuranceCompany: insuranceCompanyController.text.trim().isNotEmpty
                ? insuranceCompanyController.text.trim()
                : null,
            policyType: policyTypeController.text.trim().isNotEmpty
                ? policyTypeController.text.trim()
                : null,
            sumInsured: sumInsured,
            premiumAmount: premium,
            tpaName: tpaNameController.text.trim().isNotEmpty
                ? tpaNameController.text.trim()
                : null,
            notes: notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      document.value = current.copyWith(
        title: newTitle,
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null,
        personalMetadata: updatedMeta,
      );

      await _loadHistory(document.value!);

      AppSnackbar.showSuccess(
        'Document Saved',
        'Details for $newTitle have been updated successfully.',
      );
    } catch (e, st) {
      AppLogger.error('PERSONAL_DETAIL_CTRL', 'Error saving doc details: $e',
          error: e, stackTrace: st);
      AppSnackbar.showError('Save Failed', 'Could not save document details: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> previewDocument(DocumentModel doc) async {
    try {
      final resolvedUrl = (doc.isGoogleAttachment ||
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
    } catch (e) {
      AppSnackbar.showError('Preview Failed', 'Could not preview file: $e');
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    try {
      if (doc.isGoogleAttachment ||
          doc.filePath.startsWith('gdrive://') ||
          doc.filePath.startsWith('http://') ||
          doc.filePath.startsWith('https://')) {
        final gUrl = doc.googleAttachmentUrl ??
            (doc.filePath.startsWith('gdrive://')
                ? 'https://drive.google.com/file/d/${doc.filePath.replaceFirst("gdrive://", "")}/view?usp=sharing'
                : doc.filePath);
        final uri = Uri.tryParse(gUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      final signedUrl = await _dataset.getSignedPreviewUrl(doc.filePath, download: true);
      await FileApiHelper.downloadFileFromUrl(
        url: signedUrl,
        fileName: doc.fileName,
        mimeType: doc.mimeType,
      );
      AppSnackbar.showSuccess('Downloaded', 'File downloading: ${doc.fileName}');
    } catch (e) {
      AppSnackbar.showError('Download Failed', 'Could not download file: $e');
    }
  }

  Future<void> openRenewDialog(DocumentModel doc) async {
    final success = await RenewPersonalDocDialog.show(
      previousDocument: doc,
      onRenew: ({
        required previousDocument,
        required newMetadata,
        required newTitle,
        required fileBytes,
        required fileName,
        newDescription,
      }) async {
        await _dataset.renewPersonalDocument(
          previousDocument: previousDocument,
          newMetadata: newMetadata,
          newTitle: newTitle,
          fileBytes: fileBytes,
          fileName: fileName,
          newDescription: newDescription,
        );
      },
    );

    if (success == true) {
      await reloadData();
      AppSnackbar.showSuccess(
        'Renewal Activated',
        'Policy / document renewed successfully with active validity.',
      );
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    personNameController.dispose();
    relationshipController.dispose();
    docTypeNameController.dispose();
    idNumberController.dispose();
    issuingAuthorityController.dispose();
    insuranceCompanyController.dispose();
    policyTypeController.dispose();
    sumInsuredController.dispose();
    premiumAmountController.dispose();
    tpaNameController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
