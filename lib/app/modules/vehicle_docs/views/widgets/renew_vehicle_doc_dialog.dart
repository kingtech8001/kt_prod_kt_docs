import 'dart:async';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/services/document_scanner_service.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_dropzone.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/platform_file_compat.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Callback typedef for renewing vehicle document
typedef VehicleDocRenewCallback = Future<void> Function({
  required DocumentModel previousDocument,
  required VehicleDocumentMetadataModel newMetadata,
  required String newTitle,
  required Uint8List fileBytes,
  required String fileName,
  String? newDescription,
});

class RenewVehicleDocDialog extends StatelessWidget {
  final DocumentModel previousDocument;
  final VehicleDocRenewCallback onRenew;

  const RenewVehicleDocDialog({
    super.key,
    required this.previousDocument,
    required this.onRenew,
  });

  static Future<bool?> show({
    required DocumentModel previousDocument,
    required VehicleDocRenewCallback onRenew,
  }) {
    return AppDialog.show<bool>(
      RenewVehicleDocDialog(
        previousDocument: previousDocument,
        onRenew: onRenew,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = previousDocument.vehicleMetadata;
    final isPuc = (meta?.docTypeName.toLowerCase().contains('puc') ?? false) ||
        previousDocument.subCategory.toLowerCase().contains('puc');
    final isInsurance = (meta?.docTypeName.toLowerCase().contains('insurance') ?? false) ||
        previousDocument.subCategory.toLowerCase().contains('insurance');

    // Date computation for defaults
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prevExpiry = meta?.expiryDate;
    final prevIssue = meta?.issueDate;

    // Default new issue date: if prevExpiry is in future, use prevExpiry; else use today
    final defaultNewIssue = (prevExpiry != null && prevExpiry.isAfter(today))
        ? prevExpiry
        : today;

    // Default new expiry date: +6 months for PUC, +1 year for Insurance/others
    final defaultNewExpiry = isPuc
        ? DateTime(defaultNewIssue.year, defaultNewIssue.month + 6, defaultNewIssue.day)
        : DateTime(defaultNewIssue.year + 1, defaultNewIssue.month, defaultNewIssue.day);

    // Reactive State
    final selectedNewFile = Rx<PlatformFile?>(null);
    final selectedNewBytes = Rx<Uint8List?>(null);
    final selectedIssueDate = Rx<DateTime>(defaultNewIssue);
    final selectedExpiryDate = Rx<DateTime>(defaultNewExpiry);

    // Scanning & Autofill Reactive State
    final isScanning = false.obs;
    final scanProgress = 0.0.obs;
    final scanAutoFilledSummary = ''.obs;
    final scanMismatchWarning = ''.obs;

    // Bundled TP Coverage State
    final isBundledTpActive = (meta?.isBundledInsurance ?? false).obs;
    final selectedTpExpiry = Rx<DateTime?>(meta?.tpExpiryDate);

    // Form Controllers for changeable fields only
    final certNumberController = TextEditingController(
      text: meta?.policyOrCertNumber ?? previousDocument.documentNumber ?? '',
    );
    final insuranceCompanyController = TextEditingController(
      text: meta?.insuranceCompany ?? '',
    );
    final premiumController = TextEditingController(
      text: (meta?.premiumAmount != null && meta!.premiumAmount! > 0)
          ? meta.premiumAmount!.toStringAsFixed(0)
          : '',
    );
    final notesController = TextEditingController(
      text: meta?.notes ?? '',
    );

    final isSubmitting = false.obs;
    final errorMessage = ''.obs;

    Future<void> scanAndAutofill(Uint8List bytes, String fileName) async {
      isScanning.value = true;
      scanProgress.value = 0.15;
      scanAutoFilledSummary.value = '';
      scanMismatchWarning.value = '';

      Timer? timer = Timer.periodic(const Duration(milliseconds: 70), (t) {
        if (!isScanning.value) {
          t.cancel();
        } else if (scanProgress.value < 0.88) {
          scanProgress.value += 0.03;
        }
      });

      try {
        await Future.delayed(const Duration(milliseconds: 20));

        final result = await DocumentScannerService.scanDocument(
          bytes: bytes,
          fileName: fileName,
          onProgress: (p) {
            final mapped = 0.15 + (p * 0.77);
            if (mapped > scanProgress.value) {
              scanProgress.value = mapped;
            }
          },
        );

        scanProgress.value = 1.0;

        int autoFilledCount = 0;
        final List<String> filledFields = [];

        // 1. Policy / Certificate Number
        final extractedNum = result.documentNumber ?? result.vehicleFields['policyOrCertNumber'];
        if (extractedNum != null && extractedNum.toString().trim().isNotEmpty) {
          certNumberController.text = extractedNum.toString().trim();
          autoFilledCount++;
          filledFields.add('Policy #');
        }

        // 2. Issue Date
        if (result.primaryDate != null) {
          selectedIssueDate.value = result.primaryDate!;
          autoFilledCount++;
          filledFields.add('Issue Date');
        }

        // 3. Expiry Date
        if (result.secondaryDate != null) {
          selectedExpiryDate.value = result.secondaryDate!;
          autoFilledCount++;
          filledFields.add('Expiry Date');
        } else if (result.primaryDate != null) {
          selectedExpiryDate.value = isPuc
              ? DateTime(result.primaryDate!.year, result.primaryDate!.month + 6, result.primaryDate!.day)
              : DateTime(result.primaryDate!.year + 1, result.primaryDate!.month, result.primaryDate!.day);
        }

        // 4. Insurance Underwriter
        if (isInsurance) {
          final extractedCompany = result.vehicleFields['insuranceCompany'];
          if (extractedCompany != null && extractedCompany.toString().trim().isNotEmpty) {
            insuranceCompanyController.text = extractedCompany.toString().trim();
            autoFilledCount++;
            filledFields.add('Underwriter');
          }
        }

        // 5. Premium Amount
        final extractedPremium = result.amount ?? result.vehicleFields['premiumAmount'];
        if (extractedPremium != null && extractedPremium > 0) {
          premiumController.text = extractedPremium.toStringAsFixed(0);
          autoFilledCount++;
          filledFields.add('Premium');
        }

        // 6. Cross-verify vehicle registration if extracted
        final docVehicle = result.vehicleFields['vehicleNumber'];
        final lockedVehicle = meta?.vehicleNumber;
        if (docVehicle != null && lockedVehicle != null) {
          final cleanDocVeh = docVehicle.toString().replaceAll('-', '').replaceAll(' ', '').toUpperCase();
          final cleanLockedVeh = lockedVehicle.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
          if (cleanDocVeh != cleanLockedVeh) {
            scanMismatchWarning.value =
                'Notice: Scanned document mentions vehicle "$docVehicle", while this record is for "$lockedVehicle". Please verify details.';
          }
        }

        if (autoFilledCount > 0) {
          scanAutoFilledSummary.value =
              'Auto-filled $autoFilledCount fields (${filledFields.join(', ')}) from document';
        }
      } catch (e) {
        AppLogger.error('RENEW_VEHICLE', 'Document scan failed: $e');
      } finally {
        timer.cancel();
        scanProgress.value = 1.0;
        isScanning.value = false;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.autorenew_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Renew ${meta?.docTypeName ?? "Vehicle Document"}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Archive previous certificate and activate new validity period',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (!isSubmitting.value) Get.back(result: false);
                    },
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // 2. Scrollable Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Read-Only / Locked Vehicle & Document Details Banner
                    _buildLockedDetailsBanner(meta),

                    const SizedBox(height: 18),

                    // B. Previous Cycle Cross-Verification Reference Box
                    _buildPreviousValidityReference(meta, previousDocument),

                    const SizedBox(height: 22),

                    const Text(
                      'Renewal Details (Required Changes)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // C. New Document File Upload (Required)
                    _buildFileUploadSection(
                      selectedNewFile: selectedNewFile,
                      selectedNewBytes: selectedNewBytes,
                      isScanning: isScanning,
                      scanProgress: scanProgress,
                      scanAutoFilledSummary: scanAutoFilledSummary,
                      scanMismatchWarning: scanMismatchWarning,
                      onScan: scanAndAutofill,
                      errorMessage: errorMessage,
                    ),

                    const SizedBox(height: 16),

                    // D. New Certificate / Policy Number
                    TextField(
                      controller: certNumberController,
                      decoration: InputDecoration(
                        labelText: isInsurance
                            ? 'New Policy / Covernote Number'
                            : (isPuc ? 'New PUC Certificate Number' : 'New Policy / Certificate Number'),
                        hintText: isInsurance
                            ? 'e.g. HDFC-ERGO-2027-9912'
                            : (isPuc ? 'e.g. PUC-GJ01-2026-9812' : 'e.g. CERT-12345'),
                        prefixIcon: const Icon(Icons.tag, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 16),

                    // E. Date Selection & Presets (+6 Months for PUC, +1 Year for Insurance)
                    _buildValidityDatesSection(
                      context: context,
                      isPuc: isPuc,
                      isInsurance: isInsurance,
                      selectedIssueDate: selectedIssueDate,
                      selectedExpiryDate: selectedExpiryDate,
                      prevExpiry: prevExpiry,
                      errorMessage: errorMessage,
                    ),

                    // F. Insurance-Specific Changeable Details
                    if (isInsurance) ...[
                      const SizedBox(height: 18),
                      _buildInsuranceFieldsSection(
                        context: context,
                        meta: meta,
                        insuranceCompanyController: insuranceCompanyController,
                        premiumController: premiumController,
                        isBundledTpActive: isBundledTpActive,
                        selectedTpExpiry: selectedTpExpiry,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // G. Notes / Endorsements
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Renewal Notes / Coverage Endorsements (Optional)',
                        hintText: 'e.g. Renewed with Zero-Dep + RSA add-on',
                        prefixIcon: Icon(Icons.notes_outlined, size: 20),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),

                    // H. In-Context Inline Error Banner (Strict Rule 3B)
                    Obx(() {
                      if (errorMessage.value.isEmpty) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage.value,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // 3. Footer Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (!isSubmitting.value) Get.back(result: false);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton.icon(
                      onPressed: isSubmitting.value
                          ? null
                          : () => _handleSubmit(
                                selectedNewFile: selectedNewFile.value,
                                selectedNewBytes: selectedNewBytes.value,
                                newIssueDate: selectedIssueDate.value,
                                newExpiryDate: selectedExpiryDate.value,
                                certNumber: certNumberController.text.trim(),
                                insuranceCompany: insuranceCompanyController.text.trim(),
                                premiumText: premiumController.text.trim(),
                                notes: notesController.text.trim(),
                                isBundledTpActive: isBundledTpActive.value,
                                tpExpiryDate: selectedTpExpiry.value,
                                prevIssue: prevIssue,
                                prevExpiry: prevExpiry,
                                isSubmitting: isSubmitting,
                                errorMessage: errorMessage,
                              ),
                      icon: isSubmitting.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        isSubmitting.value ? 'Activating Renewal...' : 'Confirm & Activate Renewal',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Read-only locked summary banner (Vehicle, Model, Category, Doc Type cannot be modified)
  Widget _buildLockedDetailsBanner(VehicleDocumentMetadataModel? meta) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'LOCKED VEHICLE & DOCUMENT BINDING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Read-Only',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vehicle Registration', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      meta?.vehicleNumber ?? 'Unknown Vehicle',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (meta?.vehicleName != null && meta!.vehicleName.isNotEmpty)
                      Text(meta.vehicleName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Document Type', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      meta?.docTypeName ?? 'Vehicle Document',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Folder: ${previousDocument.folderName ?? "Fleet Docs"}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Comparison panel displaying previous cycle validity and numbers
  Widget _buildPreviousValidityReference(
    VehicleDocumentMetadataModel? meta,
    DocumentModel prevDoc,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                'PREVIOUS CERTIFICATE RECORD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (meta?.expiryDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: meta!.statusBadgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    meta.expiryStatusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: meta.statusBadgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _buildRefTile(
                'Previous Number',
                meta?.policyOrCertNumber ?? prevDoc.documentNumber ?? '—',
              ),
              _buildRefTile(
                'Previous Issue',
                meta?.issueDate != null ? AppFormatters.formatDate(meta!.issueDate!) : '—',
              ),
              _buildRefTile(
                'Previous Expiry',
                meta?.expiryDate != null ? AppFormatters.formatDate(meta!.expiryDate!) : '—',
              ),
              _buildRefTile(
                'Archived File',
                prevDoc.fileName,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  /// File picker section for uploading the new certificate / policy with instant scan & autofill
  Widget _buildFileUploadSection({
    required Rx<PlatformFile?> selectedNewFile,
    required Rx<Uint8List?> selectedNewBytes,
    required RxBool isScanning,
    required RxDouble scanProgress,
    required RxString scanAutoFilledSummary,
    required RxString scanMismatchWarning,
    required Future<void> Function(Uint8List bytes, String fileName) onScan,
    required RxString errorMessage,
  }) {
    return Obx(() {
      final file = selectedNewFile.value;
      final scanning = isScanning.value;
      final progress = scanProgress.value;

      if (file != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scanning
                    ? AppColors.primarySurface
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: scanning
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.5),
                  width: scanning ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  if (scanning)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            strokeWidth: 3,
                            color: AppColors.primary,
                            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  const SizedBox(width: 12),
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
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scanning
                              ? '${AppFormatters.formatFileSize(file.size)} • Scanning & analyzing metadata...'
                              : '${AppFormatters.formatFileSize(file.size)} • Ready for renewal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: scanning ? FontWeight.w600 : FontWeight.normal,
                            color: scanning ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!scanning) ...[
                    IconButton(
                      onPressed: () {
                        final b = selectedNewBytes.value;
                        if (b != null) onScan(b, file.name);
                      },
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Re-scan document',
                    ),
                    IconButton(
                      onPressed: () {
                        selectedNewFile.value = null;
                        selectedNewBytes.value = null;
                        scanAutoFilledSummary.value = '';
                        scanMismatchWarning.value = '';
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      tooltip: 'Remove file',
                    ),
                  ],
                ],
              ),
            ),
            if (scanAutoFilledSummary.value.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scanAutoFilledSummary.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (scanMismatchWarning.value.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scanMismatchWarning.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }

      return DropTarget(
        onDragDone: (detail) async {
          if (detail.files.isNotEmpty) {
            errorMessage.value = '';
            try {
              final f = detail.files.first;
              final bytes = await f.readAsBytes();
              final pf = DroppedPlatformFile(
                name: f.name,
                size: bytes.lengthInBytes,
                bytes: bytes,
                uri: f.path.isNotEmpty ? Uri.tryParse(f.path) : null,
              );
              pf.bytes = bytes;
              selectedNewFile.value = pf;
              selectedNewBytes.value = bytes;
              onScan(bytes, pf.name);
            } catch (e) {
              errorMessage.value = 'Failed to load dropped file: $e';
            }
          }
        },
        child: InkWell(
          onTap: () async {
            errorMessage.value = '';
            try {
              final result = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
              );
              if (result.isNotEmpty) {
                final chosen = result.first;
                final bytes = chosen.bytes ?? await chosen.loadBytes();
                selectedNewFile.value = chosen;
                selectedNewBytes.value = bytes;
                onScan(bytes, chosen.name);
              }
            } catch (e) {
              errorMessage.value = 'Failed to choose file: $e';
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Select or Drop New Certificate / Policy File',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'PDF, PNG, or JPG (Up to 25 MB) • Auto-scans and fills metadata',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Validity date selectors with quick action preset chips (+6 Months / +1 Year)
  Widget _buildValidityDatesSection({
    required BuildContext context,
    required bool isPuc,
    required bool isInsurance,
    required Rx<DateTime> selectedIssueDate,
    required Rx<DateTime> selectedExpiryDate,
    DateTime? prevExpiry,
    required RxString errorMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'New Validity Period',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const Spacer(),
            // Quick preset button for standard cycle
            if (isPuc)
              ActionChip(
                label: const Text('+6 Months Cycle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                avatar: const Icon(Icons.flash_on, size: 14, color: AppColors.primary),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: BorderSide.none,
                onPressed: () {
                  final base = selectedIssueDate.value;
                  selectedExpiryDate.value = DateTime(base.year, base.month + 6, base.day);
                  errorMessage.value = '';
                },
              )
            else if (isInsurance)
              ActionChip(
                label: const Text('+1 Year Annual Term', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                avatar: const Icon(Icons.flash_on, size: 14, color: AppColors.primary),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                side: BorderSide.none,
                onPressed: () {
                  final base = selectedIssueDate.value;
                  selectedExpiryDate.value = DateTime(base.year + 1, base.month, base.day);
                  errorMessage.value = '';
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // New Issue Date Picker
            Expanded(
              child: Obx(
                () => InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedIssueDate.value,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      selectedIssueDate.value = picked;
                      // Auto adjust expiry if expiry is now before issue
                      if (selectedExpiryDate.value.isBefore(picked)) {
                        selectedExpiryDate.value = isPuc
                            ? DateTime(picked.year, picked.month + 6, picked.day)
                            : DateTime(picked.year + 1, picked.month, picked.day);
                      }
                      errorMessage.value = '';
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'New Issue / Start Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(
                      AppFormatters.formatDate(selectedIssueDate.value),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // New Expiry Date Picker
            Expanded(
              child: Obx(
                () => InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedExpiryDate.value,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      selectedExpiryDate.value = picked;
                      errorMessage.value = '';
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'New Expiry / Renewal Date',
                      prefixIcon: const Icon(Icons.event_available_outlined, size: 18),
                      helperText: prevExpiry != null ? 'Must be after ${AppFormatters.formatDate(prevExpiry)}' : null,
                    ),
                    child: Text(
                      AppFormatters.formatDate(selectedExpiryDate.value),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Insurance specific inputs (Insurer, Premium, Bundled 3/5-Yr TP Preservation)
  Widget _buildInsuranceFieldsSection({
    required BuildContext context,
    required VehicleDocumentMetadataModel? meta,
    required TextEditingController insuranceCompanyController,
    required TextEditingController premiumController,
    required RxBool isBundledTpActive,
    required Rx<DateTime?> selectedTpExpiry,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Car Insurance Terms & Policy Details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RawAutocomplete<String>(
                  textEditingController: insuranceCompanyController,
                  focusNode: FocusNode(),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return AppConstants.popularInsuranceProviders.take(5);
                    }
                    return AppConstants.popularInsuranceProviders.where((p) =>
                        p.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Insurance Underwriter',
                        hintText: 'e.g. HDFC ERGO, ICICI Lombard',
                        prefixIcon: Icon(Icons.business_outlined, size: 18),
                      ),
                      textInputAction: TextInputAction.next,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title: Text(option, style: const TextStyle(fontSize: 12)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: premiumController,
                  decoration: const InputDecoration(
                    labelText: 'Renewal Premium (₹)',
                    hintText: 'e.g. 42500',
                    prefixIcon: Icon(Icons.currency_rupee, size: 18),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bundled Third-Party (TP) Liability Preservation
          Obx(() {
            return Column(
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isBundledTpActive.value,
                  onChanged: (val) {
                    isBundledTpActive.value = val ?? false;
                    if (isBundledTpActive.value && selectedTpExpiry.value == null) {
                      selectedTpExpiry.value = DateTime.now().add(const Duration(days: 365 * 3));
                    }
                  },
                  title: const Text(
                    'Retain 3/5-Year Bundled Third-Party (TP) Cover',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'For new vehicle policies where TP liability remains valid for 3 or 5 years',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (isBundledTpActive.value)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedTpExpiry.value ?? DateTime.now().add(const Duration(days: 365 * 3)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) selectedTpExpiry.value = picked;
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Third-Party (TP) Expiry Date',
                          prefixIcon: Icon(Icons.verified_user_outlined, size: 18),
                        ),
                        child: Text(
                          selectedTpExpiry.value != null
                              ? AppFormatters.formatDate(selectedTpExpiry.value!)
                              : 'Select TP Expiry',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Cross-date verification and form submission handler
  Future<void> _handleSubmit({
    required PlatformFile? selectedNewFile,
    required Uint8List? selectedNewBytes,
    required DateTime newIssueDate,
    required DateTime newExpiryDate,
    required String certNumber,
    required String insuranceCompany,
    required String premiumText,
    required String notes,
    required bool isBundledTpActive,
    required DateTime? tpExpiryDate,
    DateTime? prevIssue,
    DateTime? prevExpiry,
    required RxBool isSubmitting,
    required RxString errorMessage,
  }) async {
    errorMessage.value = '';

    // 1. Validate File
    if (selectedNewFile == null || selectedNewBytes == null || selectedNewBytes.isEmpty) {
      errorMessage.value = 'Please select and upload the new certificate / policy document file.';
      return;
    }

    // 2. Validate Issue vs Expiry
    if (!newExpiryDate.isAfter(newIssueDate)) {
      errorMessage.value = 'New expiry date (${AppFormatters.formatDate(newExpiryDate)}) must be after new issue date (${AppFormatters.formatDate(newIssueDate)}).';
      return;
    }

    // 3. Cross-verify with previous expiry date
    if (prevExpiry != null) {
      final prevExpiryDay = DateTime(prevExpiry.year, prevExpiry.month, prevExpiry.day);
      final newExpiryDay = DateTime(newExpiryDate.year, newExpiryDate.month, newExpiryDate.day);
      if (!newExpiryDay.isAfter(prevExpiryDay)) {
        errorMessage.value = 'Cross-Verification Failed: New expiry date (${AppFormatters.formatDate(newExpiryDate)}) must be strictly AFTER previous expiry date (${AppFormatters.formatDate(prevExpiry)}).';
        return;
      }
    }

    // 4. Cross-verify with previous issue date
    if (prevIssue != null) {
      final prevIssueDay = DateTime(prevIssue.year, prevIssue.month, prevIssue.day);
      final newIssueDay = DateTime(newIssueDate.year, newIssueDate.month, newIssueDate.day);
      if (newIssueDay.isBefore(prevIssueDay)) {
        errorMessage.value = 'Cross-Verification Failed: New issue date (${AppFormatters.formatDate(newIssueDate)}) cannot be earlier than previous cycle start (${AppFormatters.formatDate(prevIssue)}).';
        return;
      }
    }

    isSubmitting.value = true;
    try {
      final meta = previousDocument.vehicleMetadata!;
      final newTitle = '${meta.docTypeName} - ${meta.vehicleNumber} (${AppFormatters.formatDate(newExpiryDate)})';
      final premiumAmount = double.tryParse(premiumText);

      final updatedMetadata = meta.copyWith(
        policyOrCertNumber: certNumber.isNotEmpty ? certNumber : meta.policyOrCertNumber,
        issueDate: newIssueDate,
        expiryDate: newExpiryDate,
        insuranceCompany: insuranceCompany.isNotEmpty ? insuranceCompany : meta.insuranceCompany,
        premiumAmount: premiumAmount ?? meta.premiumAmount,
        notes: notes.isNotEmpty ? notes : meta.notes,
        insuranceType: isBundledTpActive ? 'Bundled (1-Yr OD + 3/5-Yr TP)' : meta.insuranceType,
        odExpiryDate: isBundledTpActive ? newExpiryDate : meta.odExpiryDate,
        tpExpiryDate: isBundledTpActive ? tpExpiryDate : meta.tpExpiryDate,
      );

      await onRenew(
        previousDocument: previousDocument,
        newMetadata: updatedMetadata,
        newTitle: newTitle,
        fileBytes: selectedNewBytes,
        fileName: selectedNewFile.name,
        newDescription: 'Renewed certificate valid until ${AppFormatters.formatDate(newExpiryDate)}',
      );

      Get.back(result: true);
    } catch (e) {
      errorMessage.value = 'Failed to activate renewal: $e';
    } finally {
      isSubmitting.value = false;
    }
  }
}
