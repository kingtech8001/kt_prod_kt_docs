import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/widgets/google_drive_logo.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_compressor.dart';
import 'package:kt_prod_kt_docs/core/utils/platform_file_compat.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Callback typedef for saving document changes with optional payload re-upload.
typedef DocumentEditSaveCallback = Future<void> Function({
  required String title,
  String? description,
  String? documentNumber,
  ApplianceWarrantyModel? applianceWarranty,
  VehicleDocumentMetadataModel? vehicleMetadata,
  String? newFileName,
  Uint8List? newFileBytes,
  String? newMimeType,
  String? attachmentUrl,
});

/// Reactive state container for an individual appliance item being edited.
/// 100% GetX reactive, zero setState.
class EditApplianceItemState {
  final String id;
  final TextEditingController nameController;
  final TextEditingController modelController;
  final TextEditingController serialController;
  final TextEditingController amountController;
  final TextEditingController customBrandController;
  final TextEditingController careNumberController;
  final RxString selectedBrand;
  final RxString selectedCategory;
  final RxInt warrantyMonths;
  final RxBool hasWarranty;
  final Rx<DateTime> warrantyValidUpto;

  EditApplianceItemState({
    required this.id,
    required String name,
    required String initialBrand,
    required String initialCategory,
    String? model,
    String? serial,
    double amount = 0.0,
    required int initialWarrantyMonths,
    required bool initialHasWarranty,
    required DateTime initialWarrantyValidUpto,
    String? careNumber,
  })  : nameController = TextEditingController(text: name),
        modelController = TextEditingController(text: model ?? ''),
        serialController = TextEditingController(text: serial ?? ''),
        amountController = TextEditingController(
          text: amount > 0 ? amount.toStringAsFixed(0) : '',
        ),
        customBrandController = TextEditingController(
          text: initialBrand != 'Other' &&
                  !AppConstants.popularBrands.contains(initialBrand)
              ? initialBrand
              : '',
        ),
        careNumberController = TextEditingController(text: careNumber ?? ''),
        selectedBrand = initialBrand.obs,
        selectedCategory = initialCategory.obs,
        warrantyMonths = initialWarrantyMonths.obs,
        hasWarranty = initialHasWarranty.obs,
        warrantyValidUpto = initialWarrantyValidUpto.obs;

  void updateWarranty(int months, DateTime purchaseDate) {
    warrantyMonths.value = months;
    if (months == 0) {
      hasWarranty.value = false;
      warrantyValidUpto.value = purchaseDate;
    } else {
      hasWarranty.value = true;
      warrantyValidUpto.value = purchaseDate.add(Duration(days: months * 30));
    }
  }

  void dispose() {
    nameController.dispose();
    modelController.dispose();
    serialController.dispose();
    amountController.dispose();
    customBrandController.dispose();
    careNumberController.dispose();
  }
}

/// 100% GetX-compliant Document Edit Dialog.
/// Zero setState, responsive fluid constraints, inline error banner, compact AppSnackbar on success.
class DocumentEditDialog extends StatelessWidget {
  final DocumentModel document;
  final DocumentEditSaveCallback onSave;

  final TextEditingController _titleController;
  final TextEditingController _descriptionController;
  final TextEditingController _documentNumberController;

  // Appliance Invoice Details (If applicable)
  final TextEditingController _storeVendorController;
  final TextEditingController _billingNameController;
  final TextEditingController _totalAmountController;
  final Rx<DateTime> _purchaseDate;
  final RxList<EditApplianceItemState> _applianceItems;

  // Vehicle Document Details (If applicable)
  final TextEditingController _insuranceCompanyController;
  final TextEditingController _premiumAmountController;
  final Rx<DateTime?> _issueDate;
  final Rx<DateTime?> _expiryDate;

  // Re-upload & Attachment Configuration
  final Rx<PlatformFile?> _selectedNewFile = Rx<PlatformFile?>(null);
  final TextEditingController _attachmentUrlController;
  final RxBool _showUrlField = false.obs;
  final RxBool _useCompressed = true.obs;
  final RxString _compressionPreset = 'recommended'.obs;
  final RxInt _pdfQuality = 72.obs;
  final RxInt _pdfDpi = 150.obs;
  final RxInt _imageQuality = 75.obs;
  final RxBool _isGrayscale = false.obs;
  final RxBool _stripMetadata = true.obs;
  final RxBool _isCompressing = false.obs;
  final RxDouble _compressionProgress = 0.0.obs;
  final RxString _compressionProgressText = ''.obs;
  final Rx<CompressionResult?> _compressionResult = Rx<CompressionResult?>(null);
  final RxString _compressionError = ''.obs;

  final RxBool _isSaving = false.obs;
  final RxString _errorMessage = ''.obs;

  DocumentEditDialog({
    super.key,
    required this.document,
    required this.onSave,
  })  : _titleController = TextEditingController(text: document.title),
        _descriptionController =
            TextEditingController(text: document.description ?? ''),
        _documentNumberController = TextEditingController(
          text: (document.documentNumber != null &&
                  document.documentNumber!.trim().isNotEmpty)
              ? document.documentNumber!.trim()
              : (document.applianceWarranty?.invoiceNumber ??
                  document.vehicleMetadata?.policyOrCertNumber ??
                  document.personalMetadata?.idNumber ??
                  document.utilityMetadata?.consumerNumber ??
                  ''),
        ),
        _storeVendorController = TextEditingController(
            text: document.applianceWarranty?.storeVendorName ?? ''),
        _billingNameController = TextEditingController(
            text: document.applianceWarranty?.billingName ?? ''),
        _totalAmountController = TextEditingController(
          text: (document.applianceWarranty?.purchaseAmount != null &&
                  document.applianceWarranty!.purchaseAmount > 0)
              ? document.applianceWarranty!.purchaseAmount.toStringAsFixed(0)
              : '',
        ),
        _purchaseDate = (document.applianceWarranty?.purchaseDate ??
                document.createdAt)
            .obs,
        _applianceItems = <EditApplianceItemState>[].obs,
        _insuranceCompanyController = TextEditingController(
          text: document.vehicleMetadata?.insuranceCompany ?? '',
        ),
        _premiumAmountController = TextEditingController(
          text: (document.vehicleMetadata?.premiumAmount != null &&
                  document.vehicleMetadata!.premiumAmount! > 0)
              ? document.vehicleMetadata!.premiumAmount!.toStringAsFixed(0)
              : '',
        ),
        _issueDate = Rx<DateTime?>(document.vehicleMetadata?.issueDate),
        _expiryDate = Rx<DateTime?>(document.vehicleMetadata?.expiryDate),
        _attachmentUrlController = TextEditingController(
          text: document.isGoogleAttachment
              ? (document.googleAttachmentUrl ?? document.filePath)
              : '',
        ) {
    if (document.isGoogleAttachment) {
      _showUrlField.value = true;
    }
    _initializeItems();
  }

  bool get _isAppliance =>
      document.applianceWarranty != null ||
      document.categoryCode == 'appliance_warranty';

  bool get _isVehicle =>
      document.vehicleMetadata != null ||
      document.categoryCode == 'vehicle_docs';

  bool get _isCompressible =>
      _selectedNewFile.value != null &&
      FileCompressor.isCompressible(_selectedNewFile.value!.name);

  bool get _isNewPdf =>
      _selectedNewFile.value != null &&
      FileCompressor.isPdf(_selectedNewFile.value!.name);

  void _initializeItems() {
    final w = document.applianceWarranty;
    if (w != null && w.items.isNotEmpty) {
      for (var item in w.items) {
        _applianceItems.add(
          EditApplianceItemState(
            id: item.id,
            name: item.productName,
            initialBrand: item.brand,
            initialCategory: item.productCategory,
            model: item.modelNumber,
            serial: item.serialNumber,
            amount: item.purchaseAmount,
            initialWarrantyMonths: item.warrantyPeriodMonths,
            initialHasWarranty: item.hasWarranty,
            initialWarrantyValidUpto: item.warrantyValidUpto,
            careNumber: item.customerCareNumber,
          ),
        );
      }
    } else if (_isAppliance) {
      _applianceItems.add(
        EditApplianceItemState(
          id: const Uuid().v4(),
          name: document.title,
          initialBrand: w?.brand ?? 'Havells',
          initialCategory: document.subCategory,
          initialWarrantyMonths: w?.warrantyPeriodMonths ?? 12,
          initialHasWarranty: w?.hasWarranty ?? true,
          initialWarrantyValidUpto: w?.warrantyValidUpto ??
              DateTime.now().add(const Duration(days: 365)),
        ),
      );
    }
  }

  static Future<bool?> show({
    required DocumentModel document,
    required DocumentEditSaveCallback onSave,
  }) {
    return AppDialog.show<bool>(
      DocumentEditDialog(document: document, onSave: onSave),
      barrierDismissible: false,
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'docx', 'xlsx'],
      );
      if (result.isNotEmpty) {
        final file = result.first;
        await file.loadBytes();
        _selectedNewFile.value = file;
        _attachmentUrlController.clear();
        _showUrlField.value = false;
        if (_titleController.text.contains('(Google Drive)')) {
          _titleController.text = _titleController.text
              .replaceAll('(Google Drive)', '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        }
        _compressionResult.value = null;
        _compressionError.value = '';
        _errorMessage.value = '';
        if (FileCompressor.isCompressible(file.name) && _useCompressed.value) {
          _compressSelectedFile();
        }
      }
    } catch (e) {
      _errorMessage.value = 'Failed to pick file: $e';
    }
  }

  Future<void> _compressSelectedFile() async {
    final file = _selectedNewFile.value;
    if (file == null) return;
    final bytes = file.bytes ?? await file.loadBytes();
    if (bytes.isEmpty) return;

    if (!FileCompressor.isCompressible(file.name)) {
      _compressionResult.value = null;
      _compressionError.value = '';
      return;
    }

    _isCompressing.value = true;
    _compressionError.value = '';
    _compressionProgress.value = 0.15;
    _compressionProgressText.value =
        'Connecting to King Technology Media Engine...';

    try {
      final isPdf = FileCompressor.isPdf(file.name);
      final result = await FileCompressor.compressFile(
        bytes: bytes,
        fileName: file.name,
        level: _compressionPreset.value,
        quality: isPdf ? _pdfQuality.value : _imageQuality.value,
        dpi: isPdf ? _pdfDpi.value : null,
        grayscale: _isGrayscale.value,
        stripMetadata: _stripMetadata.value,
        onProgress: (progress, message) {
          _compressionProgress.value = progress;
          _compressionProgressText.value = message;
        },
      );

      if (result != null) {
        _compressionResult.value = result;
        _compressionProgress.value = 1.0;
        _compressionProgressText.value = 'Compression complete!';
      } else {
        _compressionError.value =
            'Compression engine did not return a valid result.';
      }
    } catch (e) {
      _compressionError.value =
          e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isCompressing.value = false;
    }
  }

  void _setCompressionPreset(String preset) {
    if (_compressionPreset.value == preset && _compressionResult.value != null) {
      return;
    }
    _compressionPreset.value = preset;
    final isPdf = _isNewPdf;
    if (isPdf) {
      switch (preset) {
        case 'recommended':
          _pdfQuality.value = 72;
          _pdfDpi.value = 150;
          break;
        case 'extreme':
          _pdfQuality.value = 45;
          _pdfDpi.value = 96;
          break;
        case 'high':
          _pdfQuality.value = 85;
          _pdfDpi.value = 200;
          break;
      }
    } else {
      switch (preset) {
        case 'recommended':
          _imageQuality.value = 75;
          break;
        case 'extreme':
          _imageQuality.value = 40;
          break;
        case 'high':
          _imageQuality.value = 90;
          break;
      }
    }
    if (_useCompressed.value) {
      _compressSelectedFile();
    }
  }

  void _addApplianceItem() {
    _applianceItems.add(
      EditApplianceItemState(
        id: const Uuid().v4(),
        name: '',
        initialBrand: 'Havells',
        initialCategory: 'Ceiling / Table Fans',
        initialWarrantyMonths: 12,
        initialHasWarranty: true,
        initialWarrantyValidUpto:
            _purchaseDate.value.add(const Duration(days: 365)),
      ),
    );
  }

  void _removeApplianceItem(int index) {
    if (_applianceItems.length > 1) {
      final removed = _applianceItems.removeAt(index);
      removed.dispose();
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _errorMessage.value = 'Document title is required.';
      return;
    }

    _isSaving.value = true;
    _errorMessage.value = '';

    try {
      ApplianceWarrantyModel? updatedAppliance;
      if (_isAppliance && _applianceItems.isNotEmpty) {
        final List<ApplianceItemModel> items = [];
        double computedTotal = 0.0;

        for (var item in _applianceItems) {
          final brand = item.selectedBrand.value == 'Other' &&
                  item.customBrandController.text.isNotEmpty
              ? item.customBrandController.text.trim()
              : item.selectedBrand.value;
          final amount =
              double.tryParse(item.amountController.text.trim()) ?? 0.0;
          computedTotal += amount;
          final name = item.nameController.text.trim().isNotEmpty
              ? item.nameController.text.trim()
              : '$brand ${item.selectedCategory.value}';

          items.add(
            ApplianceItemModel(
              id: item.id,
              productName: name,
              productCategory: item.selectedCategory.value,
              brand: brand,
              modelNumber: item.modelController.text.trim().isNotEmpty
                  ? item.modelController.text.trim()
                  : null,
              serialNumber: item.serialController.text.trim().isNotEmpty
                  ? item.serialController.text.trim()
                  : null,
              purchaseAmount: amount,
              warrantyPeriodMonths:
                  item.hasWarranty.value ? item.warrantyMonths.value : 0,
              warrantyValidUpto: item.hasWarranty.value
                  ? item.warrantyValidUpto.value
                  : _purchaseDate.value,
              customerCareNumber:
                  item.careNumberController.text.trim().isNotEmpty
                      ? item.careNumberController.text.trim()
                      : null,
              warrantyStatus: item.hasWarranty.value ? 'active' : 'no_warranty',
            ),
          );
        }

        final explicitTotal =
            double.tryParse(_totalAmountController.text.trim());
        final totalAmount =
            (explicitTotal != null && explicitTotal > 0)
                ? explicitTotal
                : computedTotal;

        updatedAppliance = ApplianceWarrantyModel(
          id: document.applianceWarranty?.id,
          documentId: document.id,
          items: items,
          billingName: _billingNameController.text.trim().isNotEmpty
              ? _billingNameController.text.trim()
              : 'King Technology',
          storeVendorName: _storeVendorController.text.trim().isNotEmpty
              ? _storeVendorController.text.trim()
              : 'Authorized Vendor',
          invoiceNumber: _documentNumberController.text.trim().isNotEmpty
              ? _documentNumberController.text.trim()
              : 'INV-${DateTime.now().millisecondsSinceEpoch}',
          purchaseDate: _purchaseDate.value,
          purchaseAmount: totalAmount,
        );
      }

      VehicleDocumentMetadataModel? updatedVehicle;
      if (_isVehicle && document.vehicleMetadata != null) {
        final premium = double.tryParse(_premiumAmountController.text.trim());
        updatedVehicle = document.vehicleMetadata!.copyWith(
          policyOrCertNumber: _documentNumberController.text.trim().isNotEmpty
              ? _documentNumberController.text.trim()
              : null,
          insuranceCompany: _insuranceCompanyController.text.trim().isNotEmpty
              ? _insuranceCompanyController.text.trim()
              : null,
          premiumAmount: premium,
          issueDate: _issueDate.value,
          expiryDate: _expiryDate.value,
          notes: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );
      }

      Uint8List? fileBytesToUpload;
      String? fileNameToUpload;
      String? mimeTypeToUpload;
      String? attachmentUrlToUpload;

      if (_selectedNewFile.value != null) {
        final file = _selectedNewFile.value!;
        if (_useCompressed.value && _compressionResult.value != null) {
          fileBytesToUpload = _compressionResult.value!.compressedBytes;
          fileNameToUpload = _compressionResult.value!.compressedFileName;
          mimeTypeToUpload = _compressionResult.value!.mimeType;
        } else {
          fileBytesToUpload = file.bytes ?? await file.loadBytes();
          fileNameToUpload = file.name;
          mimeTypeToUpload = lookupMimeType(fileNameToUpload) ??
              (FileCompressor.isPdf(fileNameToUpload)
                  ? 'application/pdf'
                  : 'application/octet-stream');
        }
      }

      if (_selectedNewFile.value != null) {
        // Replacing existing document (or Google Drive link) with a new VPS storage file
        attachmentUrlToUpload = null;
      } else {
        final urlText = _attachmentUrlController.text.trim();
        if (urlText.isNotEmpty &&
            urlText != (document.googleAttachmentUrl ?? '')) {
          attachmentUrlToUpload = urlText;
        }
      }

      await onSave(
        title: title,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        documentNumber: _documentNumberController.text.trim().isNotEmpty
            ? _documentNumberController.text.trim()
            : null,
        applianceWarranty: updatedAppliance,
        vehicleMetadata: updatedVehicle,
        newFileName: fileNameToUpload,
        newFileBytes: fileBytesToUpload,
        newMimeType: mimeTypeToUpload,
        attachmentUrl: attachmentUrlToUpload,
      );

      _disposeControllers();
      // Rule 3.B: Close dialog first, then fire success snackbar
      Get.back(result: true);
      AppSnackbar.showSuccess(
        'Document Updated',
        'Document details have been updated successfully.',
      );
    } catch (e) {
      // Rule 3.B: Render submission error INSIDE the modal, keep dialog open
      _errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isSaving.value = false;
    }
  }

  void _disposeControllers() {
    _titleController.dispose();
    _descriptionController.dispose();
    _documentNumberController.dispose();
    _storeVendorController.dispose();
    _billingNameController.dispose();
    _totalAmountController.dispose();
    _insuranceCompanyController.dispose();
    _premiumAmountController.dispose();
    _attachmentUrlController.dispose();
    for (var item in _applianceItems) {
      item.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !_isSaving.value,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          backgroundColor: AppColors.surface,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (_isAppliance || _isVehicle) ? 720 : 580,
              maxHeight: MediaQuery.sizeOf(context).height * 0.90,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusSmall),
                            ),
                            child: Icon(
                              _isAppliance
                                  ? Icons.kitchen_outlined
                                  : _isVehicle
                                      ? Icons.directions_car_outlined
                                      : Icons.edit_document,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isAppliance
                                ? 'Edit Appliance Invoice'
                                : _isVehicle
                                    ? 'Edit Vehicle Document'
                                    : 'Edit Document Details',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.textSecondary,
                        splashRadius: 18,
                        onPressed: _isSaving.value
                            ? null
                            : () {
                                _disposeControllers();
                                Get.back(result: false);
                              },
                      ),
                    ],
                  ),
              const SizedBox(height: 12),

              // 2. Inline Error Banner (Rule 3.B)
              Obx(() {
                if (_errorMessage.value.isEmpty) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage.value,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // 3. Scrollable Content Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Document Title *',
                          hintText: 'e.g. Croma Electronics Invoice',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _documentNumberController,
                        decoration: InputDecoration(
                          labelText: _isVehicle
                              ? 'Policy / Certificate / Doc Number'
                              : (_isAppliance
                                  ? 'Invoice Number'
                                  : 'Invoice / Document Number'),
                          hintText: _isVehicle
                              ? 'e.g. POL-98123 or Certificate Number'
                              : 'e.g. INV-98123',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Document Description / Notes',
                          hintText: 'e.g. Contains multiple appliances, repair notes...',
                          alignLabelWithHint: true,
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 14),
                      _buildAttachmentAndReuploadSection(context),

                      // Vehicle Document Section
                      if (_isVehicle) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _insuranceCompanyController,
                                decoration: const InputDecoration(
                                  labelText: 'Insurance Co. / Issuer',
                                  hintText: 'e.g. HDFC ERGO, ICICI Lombard',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _premiumAmountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Premium Amount (₹)',
                                  hintText: 'e.g. 12500',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _issueDate.value ??
                                          DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      _issueDate.value = picked;
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusSmall,
                                  ),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Issue / Start Date',
                                      suffixIcon: _issueDate.value != null
                                          ? IconButton(
                                              icon: const Icon(Icons.clear,
                                                  size: 16),
                                              onPressed: () =>
                                                  _issueDate.value = null,
                                            )
                                          : const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                            ),
                                    ),
                                    child: Text(
                                      _issueDate.value != null
                                          ? AppFormatters.formatDate(
                                              _issueDate.value!,
                                            )
                                          : 'Select Issue Date',
                                      style: TextStyle(
                                        color: _issueDate.value != null
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Obx(
                                () => InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _expiryDate.value ??
                                          DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2050),
                                    );
                                    if (picked != null) {
                                      _expiryDate.value = picked;
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusSmall,
                                  ),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Expiry Date',
                                      suffixIcon: _expiryDate.value != null
                                          ? IconButton(
                                              icon: const Icon(Icons.clear,
                                                  size: 16),
                                              onPressed: () =>
                                                  _expiryDate.value = null,
                                            )
                                          : const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                            ),
                                    ),
                                    child: Text(
                                      _expiryDate.value != null
                                          ? AppFormatters.formatDate(
                                              _expiryDate.value!,
                                            )
                                          : 'Select Expiry Date',
                                      style: TextStyle(
                                        color: _expiryDate.value != null
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Multi-Product Appliance Section
                      if (_isAppliance) ...[
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 12),

                        // Invoice Level Fields
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _storeVendorController,
                                decoration: const InputDecoration(
                                  labelText: 'Store / Vendor',
                                  hintText: 'e.g. Vijay Sales, Amazon',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _billingNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Customer / Billing Name',
                                  hintText: 'e.g. King Technology',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _totalAmountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Total Bill Amount (₹)',
                                  hintText: 'e.g. 65000',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Obx(
                                () => InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _purchaseDate.value,
                                      firstDate: DateTime(2010),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      _purchaseDate.value = picked;
                                      for (var item in _applianceItems) {
                                        item.updateWarranty(
                                          item.warrantyMonths.value,
                                          picked,
                                        );
                                      }
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Purchase Date',
                                      suffixIcon:
                                          Icon(Icons.calendar_today, size: 18),
                                    ),
                                    child: Text(
                                      AppFormatters.formatDate(
                                          _purchaseDate.value),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Items Repeater Header
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.devices_other,
                                    color: AppColors.warrantyEmerald,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Products Covered (${_applianceItems.length})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _addApplianceItem,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Product'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // List of Products
                        Obx(
                          () => Column(
                            children:
                                List.generate(_applianceItems.length, (idx) {
                              final item = _applianceItems[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.radiusSmall),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Product #${idx + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.warrantyEmerald,
                                          ),
                                        ),
                                        if (_applianceItems.length > 1)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.error,
                                              size: 18,
                                            ),
                                            splashRadius: 16,
                                            onPressed: () =>
                                                _removeApplianceItem(idx),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: TextField(
                                            controller: item.nameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Product Name / Model',
                                              hintText:
                                                  'e.g. LG Smart Refrigerator',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: Obx(
                                            () =>
                                                DropdownButtonFormField<String>(
                                              initialValue: AppConstants.popularBrands
                                                      .contains(item
                                                          .selectedBrand.value)
                                                  ? item.selectedBrand.value
                                                  : 'Other',
                                              decoration: const InputDecoration(
                                                labelText: 'Brand',
                                              ),
                                              items: [
                                                ...AppConstants.popularBrands,
                                                'Other',
                                              ].map((b) {
                                                return DropdownMenuItem(
                                                  value: b,
                                                  child: Text(
                                                    b,
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  item.selectedBrand.value =
                                                      val;
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Obx(() {
                                      if (item.selectedBrand.value != 'Other') {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: TextField(
                                          controller:
                                              item.customBrandController,
                                          decoration: const InputDecoration(
                                            labelText: 'Custom Brand Name',
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: item.serialController,
                                            decoration: const InputDecoration(
                                              labelText: 'Serial Number',
                                              hintText: 'SN-XXXXX',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Obx(
                                            () => DropdownButtonFormField<int>(
                                              initialValue: item.warrantyMonths.value,
                                              decoration: const InputDecoration(
                                                labelText: 'Warranty Period',
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 0,
                                                  child: Text('No Warranty'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 6,
                                                  child: Text('6 Months'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 12,
                                                  child: Text('1 Year'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 24,
                                                  child: Text('2 Years'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 36,
                                                  child: Text('3 Years'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 60,
                                                  child: Text('5 Years'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 120,
                                                  child: Text('10 Years'),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  item.updateWarranty(
                                                    val,
                                                    _purchaseDate.value,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Uploading / Saving Progress Indicator (Rule: wait until upload finishes before dialog closes)
              if (_isSaving.value)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedNewFile.value != null
                                  ? 'Uploading document to VPS Storage...'
                                  : 'Saving document changes...',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Please wait, saving to server. Dialog will close upon completion.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // 4. Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving.value
                        ? null
                        : () {
                            _disposeControllers();
                            Get.back(result: false);
                          },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving.value ? null : _handleSave,
                    child: _isSaving.value
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Uploading & Saving...'),
                            ],
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildAttachmentAndReuploadSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Row(
            children: [
              Icon(Icons.attachment_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Attachment & Re-upload',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Current Document State Banner (or Selected New File Replacement Banner)
          Obx(() {
            if (_selectedNewFile.value != null) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        color: AppColors.success, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                document.isGoogleAttachment
                                    ? 'Replaces Google Drive with VPS Storage'
                                    : 'New File Replaces Current File',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VPS STORAGE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedNewFile.value!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            if (document.isGoogleAttachment) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const GoogleDriveLogo(size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Current: Google Drive Link',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 6),
                              GoogleDriveBadge(compact: true),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            document.googleAttachmentUrl ?? document.filePath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Open in Google Drive',
                      icon: const Icon(Icons.open_in_new,
                          size: 16, color: Color(0xFF4285F4)),
                      splashRadius: 16,
                      onPressed: () {
                        final url =
                            document.googleAttachmentUrl ?? document.filePath;
                        final uri = Uri.tryParse(url);
                        if (uri != null) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    document.fileType == 'pdf'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.description_outlined,
                    size: 22,
                    color: document.fileType == 'pdf'
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current: ${document.fileName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${document.fileType.toUpperCase()} • ${document.fileSizeFormatted}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Re-upload & Link Options Buttons
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickFile(context),
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: Text(
                      _selectedNewFile.value != null
                          ? 'Change File (${_selectedNewFile.value!.name.length > 12 ? "${_selectedNewFile.value!.name.substring(0, 10)}..." : _selectedNewFile.value!.name})'
                          : 'Re-upload / Replace File',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showUrlField.toggle(),
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: Text(
                    _showUrlField.value ? 'Hide Link' : 'Attach URL',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // Optional URL Input (Google Drive or Web URL)
          Obx(() {
            if (!_showUrlField.value) return const SizedBox.shrink();
            final text = _attachmentUrlController.text.toLowerCase();
            final isGoogle = text.contains('google');
            return Container(
              margin: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: _attachmentUrlController,
                decoration: InputDecoration(
                  labelText: 'Google Drive or Web Document URL',
                  hintText: 'https://drive.google.com/file/d/...',
                  prefixIcon: isGoogle
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: GoogleDriveLogo(size: 16),
                        )
                      : const Icon(Icons.link,
                          size: 18, color: AppColors.textSecondary),
                  suffixIcon: _attachmentUrlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _attachmentUrlController.clear();
                          },
                        )
                      : null,
                ),
              ),
            );
          }),

          // Selected New File Banner & Upload Configuration
          Obx(() {
            final file = _selectedNewFile.value;
            if (file == null) return const SizedBox.shrink();

            final isPdf = _isNewPdf;
            final isCompressible = _isCompressible;
            final isCompressing = _isCompressing.value;
            final result = _compressionResult.value;
            final error = _compressionError.value;
            final isCompressedMode = _useCompressed.value;

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Preview Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPdf
                              ? AppColors.errorLight
                              : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.insert_drive_file_outlined,
                          size: 18,
                          color: isPdf ? AppColors.error : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Original: ${CompressionResult.formatFileSize(file.size)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.close, size: 18),
                        splashRadius: 16,
                        onPressed: () {
                          _selectedNewFile.value = null;
                          _compressionResult.value = null;
                          _compressionError.value = '';
                        },
                      ),
                    ],
                  ),

                  if (isCompressible) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 10),

                    // Upload Version Choice (Original vs Compressed)
                    Row(
                      children: [
                        const Text(
                          'Upload Version:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Original Quality',
                              style: TextStyle(fontSize: 11)),
                          selected: !_useCompressed.value,
                          onSelected: (val) {
                            if (val) _useCompressed.value = false;
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt,
                                  size: 13, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Compressed (Optimized)',
                                  style: TextStyle(fontSize: 11)),
                            ],
                          ),
                          selected: _useCompressed.value,
                          onSelected: (val) {
                            if (val) {
                              _useCompressed.value = true;
                              if (_compressionResult.value == null &&
                                  !_isCompressing.value) {
                                _compressSelectedFile();
                              }
                            }
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),

                    if (isCompressedMode) ...[
                      const SizedBox(height: 12),

                      // Presets row
                      Row(
                        children: [
                          const Text(
                            'Preset: ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              _buildPresetChip('Recommended', 'recommended'),
                              _buildPresetChip('Extreme', 'extreme'),
                              _buildPresetChip('High Quality', 'high'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quality slider
                      Row(
                        children: [
                          Text(
                            isPdf
                                ? 'PDF Quality: ${_pdfQuality.value}%'
                                : 'Image Quality: ${_imageQuality.value}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: isCompressing
                                ? null
                                : () => _compressSelectedFile(),
                            icon: isCompressing
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, size: 14),
                            label: Text(
                              isCompressing ? 'Optimizing...' : 'Re-compress',
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                        ),
                        child: Slider(
                          value: (isPdf
                                  ? _pdfQuality.value
                                  : _imageQuality.value)
                              .toDouble(),
                          min: 20,
                          max: 100,
                          divisions: 16,
                          onChanged: (val) {
                            if (isPdf) {
                              _pdfQuality.value = val.toInt();
                            } else {
                              _imageQuality.value = val.toInt();
                            }
                            _compressionPreset.value = 'custom';
                          },
                        ),
                      ),

                      // PDF options: DPI chips + Grayscale & Metadata
                      if (isPdf) ...[
                        Row(
                          children: [
                            const Text(
                              'DPI: ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            for (var dpi in [96, 150, 200, 300]) ...[
                              InkWell(
                                onTap: () {
                                  _pdfDpi.value = dpi;
                                  _compressSelectedFile();
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: _pdfDpi.value == dpi
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _pdfDpi.value == dpi
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    '$dpi DPI',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _pdfDpi.value == dpi
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _isGrayscale.value,
                                    onChanged: (val) {
                                      _isGrayscale.value = val ?? false;
                                      _compressSelectedFile();
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Grayscale',
                                    style: TextStyle(fontSize: 11)),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _stripMetadata.value,
                                    onChanged: (val) {
                                      _stripMetadata.value = val ?? true;
                                      _compressSelectedFile();
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Strip Metadata',
                                    style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ],

                      // Progressive Progress Indicator
                      if (isCompressing) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _compressionProgressText.value.isNotEmpty
                                          ? _compressionProgressText.value
                                          : 'Compressing via King Technology Media Engine...',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(_compressionProgress.value * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: _compressionProgress.value
                                      .clamp(0.05, 1.0),
                                  minHeight: 4,
                                  backgroundColor: AppColors.surface,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Compression Savings Results Banner
                      if (result != null && !isCompressing) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${result.originalSizeFormatted} ➔ ${result.compressedSizeFormatted}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            result.savingsFormatted,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Optimized via King Technology Media Engine',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  if (isPdf) {
                                    PdfViewerDialog.showBytes(
                                      title:
                                          'Preview: ${result.compressedFileName}',
                                      bytes: result.compressedBytes,
                                      fileName: result.compressedFileName,
                                    );
                                  } else {
                                    ImageLightboxDialog.show(
                                      title:
                                          'Preview: ${result.compressedFileName}',
                                      imageBytes: result.compressedBytes,
                                      fileName: result.compressedFileName,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.visibility_outlined,
                                    size: 14),
                                label: const Text('Preview',
                                    style: TextStyle(fontSize: 11)),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Compression Error Notice
                      if (error.isNotEmpty && !isCompressing) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warningDark,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Optimization Notice: $error (Original file will be used)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.warningDark,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _compressSelectedFile(),
                                child: const Text('Retry',
                                    style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String value) {
    return Obx(() {
      final isSelected = _compressionPreset.value == value;
      return InkWell(
        onTap: () => _setCompressionPreset(value),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      );
    });
  }
}

/// Standardized delete confirmation modal.
class DocumentDeleteDialog extends StatelessWidget {
  final String documentTitle;
  final Future<void> Function() onConfirm;

  const DocumentDeleteDialog({
    super.key,
    required this.documentTitle,
    required this.onConfirm,
  });

  static void show({
    required String documentTitle,
    required Future<void> Function() onConfirm,
  }) {
    AppDialog.show(
      DocumentDeleteDialog(documentTitle: documentTitle, onConfirm: onConfirm),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RxBool isDeleting = false.obs;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Move Document to Trash?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '"$documentTitle" will be moved to the trash bin. You can restore it later if needed.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isDeleting.value
                          ? null
                          : () async {
                              isDeleting.value = true;
                              try {
                                Get.back();
                                await onConfirm();
                              } catch (e) {
                                AppSnackbar.showError('Delete Failed', e.toString());
                              } finally {
                                isDeleting.value = false;
                              }
                            },
                      child: isDeleting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Move to Trash'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
