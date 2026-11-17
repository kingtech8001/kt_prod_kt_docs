import 'dart:async';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/services/document_scanner_service.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_dropzone.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/platform_file_compat.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

/// Callback typedef for renewing personal document (Health Insurance, Mediclaim, etc.)
typedef PersonalDocRenewCallback = Future<void> Function({
  required DocumentModel previousDocument,
  required PersonalDocumentMetadataModel newMetadata,
  required String newTitle,
  required Uint8List fileBytes,
  required String fileName,
  String? newDescription,
});

class RenewPersonalDocDialog extends StatelessWidget {
  final DocumentModel previousDocument;
  final PersonalDocRenewCallback onRenew;

  const RenewPersonalDocDialog({
    super.key,
    required this.previousDocument,
    required this.onRenew,
  });

  static Future<bool?> show({
    required DocumentModel previousDocument,
    required PersonalDocRenewCallback onRenew,
  }) {
    return AppDialog.show<bool>(
      RenewPersonalDocDialog(
        previousDocument: previousDocument,
        onRenew: onRenew,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = previousDocument.personalMetadata;
    final docTypeName = meta?.docTypeName ?? previousDocument.subCategory;

    final isInsurance = (meta?.isInsurance ?? false) ||
        docTypeName.toLowerCase().contains('insurance') ||
        docTypeName.toLowerCase().contains('mediclaim') ||
        previousDocument.subCategory.toLowerCase().contains('insurance') ||
        previousDocument.subCategory.toLowerCase().contains('mediclaim');

    final isLicenseOrPassport =
        docTypeName.toLowerCase().contains('license') ||
        docTypeName.toLowerCase().contains('licence') ||
        docTypeName.toLowerCase().contains('passport') ||
        previousDocument.subCategory.toLowerCase().contains('license') ||
        previousDocument.subCategory.toLowerCase().contains('licence') ||
        previousDocument.subCategory.toLowerCase().contains('passport');

    final isTypicallyNoExpiry =
        docTypeName.toLowerCase().contains('aadhaar') ||
        docTypeName.toLowerCase().contains('pan') ||
        docTypeName.toLowerCase().contains('voter') ||
        docTypeName.toLowerCase().contains('chutni') ||
        docTypeName.toLowerCase().contains('birth') ||
        docTypeName.toLowerCase().contains('ration');

    // Date computation for defaults
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prevExpiry = meta?.expiryDate;
    final prevIssue = meta?.issueDate;

    // Initial hasExpiry determination:
    final initialHasExpiry = prevExpiry != null ||
        isLicenseOrPassport ||
        (isInsurance && !isTypicallyNoExpiry);
    final hasExpiryDate = initialHasExpiry.obs;

    // Default new issue date: if prevExpiry is in future, use prevExpiry; else use today
    final defaultNewIssue = (prevExpiry != null && prevExpiry.isAfter(today))
        ? prevExpiry
        : today;

    // Default new expiry date: +1 year for health insurance, +10 for passport/license, +5 for others
    final int defaultYears = isInsurance ? 1 : (isLicenseOrPassport ? 10 : 5);
    final defaultNewExpiry = DateTime(
      defaultNewIssue.year + defaultYears,
      defaultNewIssue.month,
      defaultNewIssue.day,
    );

    // Reactive State
    final selectedNewFile = Rx<PlatformFile?>(null);
    final selectedNewBytes = Rx<Uint8List?>(null);
    final selectedIssueDate = Rx<DateTime>(defaultNewIssue);
    final selectedExpiryDate = Rx<DateTime>(defaultNewExpiry);

    // Scanning & Autofill Reactive State
    final isScanning = false.obs;
    final scanProgress = 0.0.obs;
    final scanAutoFilledSummary = ''.obs;

    // Insurance-specific state
    final selectedPolicyType = Rx<String>(meta?.policyType ?? 'Family Floater');
    final selectedSumInsured = Rx<double?>(meta?.sumInsured ?? 500000);

    // Form Controllers for changeable fields only
    final policyNumberController = TextEditingController(
      text: meta?.idNumber ?? previousDocument.documentNumber ?? '',
    );
    final issuingAuthorityController = TextEditingController(
      text: meta?.issuingAuthority ?? meta?.insuranceCompany ?? '',
    );
    final insuranceCompanyController = TextEditingController(
      text: meta?.insuranceCompany ?? meta?.issuingAuthority ?? '',
    );
    final sumInsuredController = TextEditingController(
      text: (meta?.sumInsured != null && meta!.sumInsured! > 0)
          ? meta.sumInsured!.toStringAsFixed(0)
          : '500000',
    );
    final premiumController = TextEditingController(
      text: (meta?.premiumAmount != null && meta!.premiumAmount! > 0)
          ? meta.premiumAmount!.toStringAsFixed(0)
          : '',
    );
    final tpaController = TextEditingController(
      text: meta?.tpaName ?? '',
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

        // 1. Policy Number
        final extractedNum = result.documentNumber ?? result.personalFields['idNumber'];
        if (extractedNum != null && extractedNum.toString().trim().isNotEmpty) {
          policyNumberController.text = extractedNum.toString().trim();
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
          hasExpiryDate.value = true;
          selectedExpiryDate.value = result.secondaryDate!;
          autoFilledCount++;
          filledFields.add('Expiry Date');
        } else if (!isTypicallyNoExpiry && result.primaryDate != null) {
          selectedExpiryDate.value = DateTime(
            result.primaryDate!.year + defaultYears,
            result.primaryDate!.month,
            result.primaryDate!.day,
          );
        }

        // 4. Insurance Company / Issuing Authority
        final extractedCompany = result.personalFields['insuranceCompany'] ?? result.personalFields['issuingAuthority'];
        if (extractedCompany != null && extractedCompany.toString().trim().isNotEmpty) {
          insuranceCompanyController.text = extractedCompany.toString().trim();
          issuingAuthorityController.text = extractedCompany.toString().trim();
          autoFilledCount++;
          filledFields.add('Provider/Authority');
        }

        // 5. Premium Amount
        final extractedPremium = result.amount ?? result.personalFields['premiumAmount'];
        if (extractedPremium != null && extractedPremium > 0) {
          premiumController.text = extractedPremium.toStringAsFixed(0);
          autoFilledCount++;
          filledFields.add('Premium');
        }

        // 6. Sum Insured
        final extractedSum = result.personalFields['sumInsured'];
        if (extractedSum != null && extractedSum is num && extractedSum > 0) {
          sumInsuredController.text = extractedSum.toStringAsFixed(0);
          selectedSumInsured.value = extractedSum.toDouble();
          autoFilledCount++;
          filledFields.add('Sum Insured');
        }

        if (autoFilledCount > 0) {
          scanAutoFilledSummary.value =
              'Auto-filled $autoFilledCount fields (${filledFields.join(', ')}) from document';
        }
      } catch (e) {
        AppLogger.error('RENEW_PERSONAL', 'Document scan failed: $e');
      } finally {
        timer.cancel();
        scanProgress.value = 1.0;
        isScanning.value = false;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 860),
        child: Column(
          children: [
            // 1. Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isInsurance
                          ? Icons.health_and_safety_outlined
                          : (isLicenseOrPassport
                              ? Icons.drive_eta_rounded
                              : Icons.badge_outlined),
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isInsurance
                                    ? 'Renew Health Insurance Policy'
                                    : 'Re-upload / Renew $docTypeName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.primaryLight
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                isInsurance
                                    ? 'Cycle #${(meta?.renewalCount ?? 0) + 1}'
                                    : 'Version #${(meta?.renewalCount ?? 0) + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isInsurance
                              ? 'Update policy validity, premium and certificate. Person and category are locked.'
                              : 'Upload updated document file (e.g. address change, renewed license, new copy) and log new version.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Get.back(result: false),
                  ),
                ],
              ),
            ),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inline Error Banner
                    Obx(() {
                      if (errorMessage.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage.value,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.error, size: 16),
                              onPressed: () => errorMessage.value = '',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),

                    // A. Locked Metadata Panel
                    _buildLockedPersonPanel(meta),

                    const SizedBox(height: 18),

                    // B. Previous Cycle Reference Card
                    _buildPreviousCycleCard(meta, prevIssue, prevExpiry),

                    const SizedBox(height: 22),

                    // Section Divider
                    Row(
                      children: [
                        const Icon(Icons.edit_calendar_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          isInsurance ? 'New Policy Cycle Details' : 'New Validity Details',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // C. New Document Upload Area
                    _buildFileUploadArea(
                      selectedNewFile: selectedNewFile,
                      selectedNewBytes: selectedNewBytes,
                      isScanning: isScanning,
                      scanProgress: scanProgress,
                      scanAutoFilledSummary: scanAutoFilledSummary,
                      onScan: scanAndAutofill,
                      errorMessage: errorMessage,
                    ),

                    const SizedBox(height: 18),

                    // D. Policy / Certificate Number
                    TextFormField(
                      controller: policyNumberController,
                      decoration: InputDecoration(
                        labelText: isInsurance
                            ? 'New Policy Number'
                            : 'Document / ID Number (e.g. Aadhaar / License / Passport #)',
                        hintText: isInsurance
                            ? 'e.g. P/161111/01/2027/000123'
                            : 'Enter number',
                        prefixIcon: const Icon(Icons.tag, size: 18),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),

                    if (!isInsurance) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: issuingAuthorityController,
                        decoration: const InputDecoration(
                          labelText: 'Issuing Authority / Govt Body (e.g. UIDAI, RTO)',
                          hintText: 'e.g. UIDAI, RTO Ahmedabad, MEA',
                          prefixIcon:
                              Icon(Icons.account_balance_outlined, size: 18),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // E. Insurance Company & Policy Plan Type (if Insurance)
                    if (isInsurance) ...[
                      // Insurance Company Auto-complete
                      Autocomplete<String>(
                        initialValue: TextEditingValue(
                            text: insuranceCompanyController.text),
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return AppConstants.popularHealthInsuranceProviders
                                .take(6);
                          }
                          return AppConstants.popularHealthInsuranceProviders
                              .where((p) => p.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (selection) {
                          insuranceCompanyController.text = selection;
                        },
                        fieldViewBuilder:
                            (context, textController, focusNode, onFieldSubmitted) {
                          textController.addListener(() {
                            insuranceCompanyController.text = textController.text;
                          });
                          return TextFormField(
                            controller: textController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Health Insurance Provider / Insurer',
                              hintText: 'e.g. Star Health, Care Health, HDFC ERGO',
                              prefixIcon: Icon(Icons.business_outlined, size: 18),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Policy Type Chips
                      const Text(
                        'Policy Type',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Family Floater',
                              'Individual',
                              'Senior Citizen',
                              'Group Mediclaim',
                              'Top-Up / Super Top-Up',
                            ].map((type) {
                              final isSelected =
                                  selectedPolicyType.value == type;
                              return ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) selectedPolicyType.value = type;
                                },
                                selectedColor: AppColors.primarySurface,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              );
                            }).toList(),
                          )),

                      const SizedBox(height: 16),

                      // Sum Insured & Premium Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: sumInsuredController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Sum Insured / Coverage (₹)',
                                hintText: 'e.g. 500000 or 1000000',
                                prefixText: '₹ ',
                                prefixIcon: Icon(Icons.shield_outlined, size: 18),
                                filled: true,
                                fillColor: AppColors.surface,
                              ),
                              onChanged: (val) {
                                selectedSumInsured.value =
                                    double.tryParse(val) ?? 0;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: premiumController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Renewal Premium (₹)',
                                hintText: 'e.g. 18500',
                                prefixText: '₹ ',
                                prefixIcon: Icon(Icons.currency_rupee, size: 18),
                                filled: true,
                                fillColor: AppColors.surface,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Quick Sum Insured Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          {'label': '₹5 L', 'val': 500000.0},
                          {'label': '₹10 L', 'val': 1000000.0},
                          {'label': '₹15 L', 'val': 1500000.0},
                          {'label': '₹25 L', 'val': 2500000.0},
                          {'label': '₹50 L', 'val': 5000000.0},
                        ].map((chip) {
                          final val = chip['val'] as double;
                          return ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: Text(chip['label'] as String,
                                style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              sumInsuredController.text = val.toStringAsFixed(0);
                              selectedSumInsured.value = val;
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // TPA / Member ID
                      TextFormField(
                        controller: tpaController,
                        decoration: const InputDecoration(
                          labelText: 'TPA / Claim Service Provider / Member ID (Optional)',
                          hintText: 'e.g. Medi Assist / Vidal Health / Care Health In-House',
                          prefixIcon: Icon(Icons.badge_outlined, size: 18),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // F. Dates: Issue Date
                    Obx(() => _buildDatePickerField(
                          label: 'Issue / Start Date',
                          date: selectedIssueDate.value,
                          onSelect: (newDate) {
                            selectedIssueDate.value = newDate;
                            selectedExpiryDate.value = DateTime(
                              newDate.year + defaultYears,
                              newDate.month,
                              newDate.day,
                            );
                          },
                        )),

                    const SizedBox(height: 18),

                    // G. Validity / Expiry Option Section
                    Obx(() {
                      final hasExpiry = hasExpiryDate.value;
                      final expiry = selectedExpiryDate.value;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: hasExpiry
                              ? AppColors.surface
                              : AppColors.successLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasExpiry
                                ? AppColors.border
                                : AppColors.success.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      hasExpiry
                                          ? Icons.event_available_rounded
                                          : Icons.verified_user_rounded,
                                      size: 18,
                                      color: hasExpiry
                                          ? AppColors.primary
                                          : AppColors.success,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Validity / Expiry Date Option',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      hasExpiry
                                          ? 'Has Expiry Date'
                                          : 'No Expiry (Lifetime)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: hasExpiry
                                            ? AppColors.primary
                                            : AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: hasExpiry,
                                      onChanged: (val) {
                                        hasExpiryDate.value = val;
                                      },
                                      activeTrackColor: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            if (!hasExpiry) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.success
                                          .withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: AppColors.success, size: 18),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Lifetime Validity (No Expiry Date) — Aadhaar Card, PAN Card, Voter ID, and birth records remain permanently valid.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Date picker field for documents with validity
                              _buildDatePickerField(
                                label: isInsurance
                                    ? 'New Policy Expiry Date'
                                    : 'New Expiry / Validity Date (e.g. Driving License, Passport)',
                                date: expiry,
                                onSelect: (newDate) {
                                  selectedExpiryDate.value = newDate;
                                },
                              ),

                              const SizedBox(height: 10),

                              // Quick Expiry Preset Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    'Quick Validity Presets:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (isInsurance) ...[
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('+1 Year (Annual)',
                                          style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        final base = selectedIssueDate.value;
                                        selectedExpiryDate.value = DateTime(
                                          base.year + 1,
                                          base.month,
                                          base.day,
                                        );
                                      },
                                    ),
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('+2 Years',
                                          style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        final base = selectedIssueDate.value;
                                        selectedExpiryDate.value = DateTime(
                                          base.year + 2,
                                          base.month,
                                          base.day,
                                        );
                                      },
                                    ),
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('+3 Years',
                                          style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        final base = selectedIssueDate.value;
                                        selectedExpiryDate.value = DateTime(
                                          base.year + 3,
                                          base.month,
                                          base.day,
                                        );
                                      },
                                    ),
                                  ] else ...[
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('+1 Year',
                                          style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        final base = selectedIssueDate.value;
                                        selectedExpiryDate.value = DateTime(
                                          base.year + 1,
                                          base.month,
                                          base.day,
                                        );
                                      },
                                    ),
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('+5 Years',
                                          style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        final base = selectedIssueDate.value;
                                        selectedExpiryDate.value = DateTime(
                                          base.year + 5,
                                          base.month,
                                          base.day,
                                        );
                                      },
                                    ),
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('+10 Years (Passport)',
                                          style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        final base = selectedIssueDate.value;
                                        selectedExpiryDate.value = DateTime(
                                          base.year + 10,
                                          base.month,
                                          base.day,
                                        );
                                      },
                                    ),
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('+20 Years (License)',
                                          style: TextStyle(fontSize: 11)),
                                      onPressed: () {
                                        final base = selectedIssueDate.value;
                                        selectedExpiryDate.value = DateTime(
                                          base.year + 20,
                                          base.month,
                                          base.day,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),

                              if (prevExpiry != null) ...[
                                const SizedBox(height: 10),
                                if (!selectedExpiryDate.value.isAfter(prevExpiry))
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorLight
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.error
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.warning_amber_rounded,
                                            color: AppColors.error,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'New validity date (${AppFormatters.formatDate(selectedExpiryDate.value)}) must be strictly after previous cycle expiry (${AppFormatters.formatDate(prevExpiry)}).',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.successLight
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.success
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline,
                                            color: AppColors.success, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Continuity verified: new cycle extends past previous expiry (${AppFormatters.formatDate(prevExpiry)}).',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 18),

                    // Notes / Remarks
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isInsurance
                            ? 'Policy Notes / Special Coverage Details (Optional)'
                            : 'Version Remarks / Reason for Re-upload (Optional)',
                        hintText: isInsurance
                            ? 'e.g. Critical illness rider added, cashless hospital list verified'
                            : 'e.g. Address updated, new chip smart card issued, driving license renewed',
                        prefixIcon: const Icon(Icons.notes, size: 18),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Modal Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Get.back(result: false),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                  ),
                  Obx(() {
                    final hasExpiry = hasExpiryDate.value;
                    final canSubmit = selectedNewFile.value != null &&
                        !isSubmitting.value &&
                        (!hasExpiry ||
                            prevExpiry == null ||
                            selectedExpiryDate.value.isAfter(prevExpiry));

                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: canSubmit
                          ? () async {
                              errorMessage.value = '';
                              if (selectedNewBytes.value == null ||
                                  selectedNewFile.value == null) {
                                errorMessage.value =
                                    'Please upload the document file.';
                                return;
                              }

                              if (hasExpiry &&
                                  prevExpiry != null &&
                                  !selectedExpiryDate.value.isAfter(prevExpiry)) {
                                errorMessage.value =
                                    'New validity date must be strictly after previous expiry date (${AppFormatters.formatDate(prevExpiry)}).';
                                return;
                              }

                              isSubmitting.value = true;
                              try {
                                final personName =
                                    meta?.personName ?? 'Personal';
                                final String newTitle;
                                if (isInsurance) {
                                  newTitle =
                                      '$docTypeName - $personName (${selectedExpiryDate.value.year})';
                                } else if (hasExpiry) {
                                  newTitle =
                                      '$docTypeName - $personName (Exp ${selectedExpiryDate.value.year})';
                                } else {
                                  newTitle = '$docTypeName - $personName';
                                }

                                final updatedMeta = (meta ??
                                        PersonalDocumentMetadataModel(
                                          personName: personName,
                                          docTypeName: docTypeName,
                                        ))
                                    .copyWith(
                                  idNumber: policyNumberController.text
                                          .trim()
                                          .isNotEmpty
                                      ? policyNumberController.text.trim()
                                      : null,
                                  issueDate: selectedIssueDate.value,
                                  expiryDate: hasExpiry
                                      ? selectedExpiryDate.value
                                      : null,
                                  clearExpiryDate: !hasExpiry,
                                  insuranceCompany: isInsurance &&
                                          insuranceCompanyController.text
                                              .trim()
                                              .isNotEmpty
                                      ? insuranceCompanyController.text.trim()
                                      : null,
                                  issuingAuthority: isInsurance
                                      ? (insuranceCompanyController.text
                                              .trim()
                                              .isNotEmpty
                                          ? insuranceCompanyController.text
                                              .trim()
                                          : meta?.issuingAuthority)
                                      : (issuingAuthorityController.text
                                              .trim()
                                              .isNotEmpty
                                          ? issuingAuthorityController.text
                                              .trim()
                                          : meta?.issuingAuthority),
                                  policyType: isInsurance
                                      ? selectedPolicyType.value
                                      : null,
                                  sumInsured: isInsurance
                                      ? double.tryParse(
                                          sumInsuredController.text.trim())
                                      : null,
                                  premiumAmount: isInsurance
                                      ? double.tryParse(
                                          premiumController.text.trim())
                                      : null,
                                  tpaName: isInsurance &&
                                          tpaController.text.trim().isNotEmpty
                                      ? tpaController.text.trim()
                                      : null,
                                  notes: notesController.text.trim().isNotEmpty
                                      ? notesController.text.trim()
                                      : null,
                                );

                                final newDesc = hasExpiry
                                    ? 'Renewed / updated cycle of "${previousDocument.title}". Valid until ${AppFormatters.formatDate(selectedExpiryDate.value)}.'
                                    : 'Re-uploaded / updated copy of "${previousDocument.title}" with lifetime validity.';

                                await onRenew(
                                  previousDocument: previousDocument,
                                  newMetadata: updatedMeta,
                                  newTitle: newTitle,
                                  fileBytes: selectedNewBytes.value!,
                                  fileName: selectedNewFile.value!.name,
                                  newDescription: newDesc,
                                );

                                Get.back(result: true);
                              } catch (e) {
                                errorMessage.value =
                                    'Failed to save renewal: $e';
                              } finally {
                                isSubmitting.value = false;
                              }
                            }
                          : null,
                      icon: isSubmitting.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.post_add_rounded, size: 18),
                      label: Text(
                        isSubmitting.value
                            ? 'Processing...'
                            : (isInsurance
                                ? 'Activate Renewal Cycle'
                                : 'Save & Upload New Version'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedPersonPanel(PersonalDocumentMetadataModel? meta) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      meta?.personName ?? 'General Individual',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.lock_outline,
                        size: 14, color: AppColors.textMuted),
                  ],
                ),
                Text(
                  'Document Type: ${meta?.docTypeName ?? previousDocument.subCategory} • Personal & Identity Vault',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'LOCKED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousCycleCard(
    PersonalDocumentMetadataModel? meta,
    DateTime? prevIssue,
    DateTime? prevExpiry,
  ) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    'Previous Cycle Reference (To be Archived)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (prevExpiry != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: meta?.isExpired ?? false
                        ? AppColors.errorLight.withValues(alpha: 0.2)
                        : AppColors.warningLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    meta?.expiryStatusLabel ?? 'Expiring',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: meta?.isExpired ?? false
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Lifetime Validity',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
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
                    const Text('Policy / ID Number',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      meta?.idNumber ??
                          previousDocument.documentNumber ??
                          'Not Specified',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Provider / Authority',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      meta?.insuranceCompany ??
                          meta?.issuingAuthority ??
                          'Not Specified',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Previous Validity',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      prevExpiry != null
                          ? '${AppFormatters.formatDate(prevIssue)} → ${AppFormatters.formatDate(prevExpiry)}'
                          : 'Lifetime Validity (No Expiry)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
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

  Widget _buildFileUploadArea({
    required Rx<PlatformFile?> selectedNewFile,
    required Rx<Uint8List?> selectedNewBytes,
    required RxBool isScanning,
    required RxDouble scanProgress,
    required RxString scanAutoFilledSummary,
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
                    : AppColors.successLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: scanning ? AppColors.primary : AppColors.success,
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf,
                          color: AppColors.success, size: 24),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          scanning
                              ? 'Scanning & analyzing document metadata...'
                              : 'Ready to upload • ${AppFormatters.formatFileSize(file.size)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: scanning ? FontWeight.w600 : FontWeight.normal,
                            color: scanning ? AppColors.primary : AppColors.success,
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
                    OutlinedButton.icon(
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Change File'),
                      onPressed: () => _pickNewDocument(
                        selectedNewFile: selectedNewFile,
                        selectedNewBytes: selectedNewBytes,
                        onScan: onScan,
                        errorMessage: errorMessage,
                      ),
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
          onTap: () => _pickNewDocument(
            selectedNewFile: selectedNewFile,
            selectedNewBytes: selectedNewBytes,
            onScan: onScan,
            errorMessage: errorMessage,
          ),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primaryLight,
                  width: 1.5,
                  style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_upload_outlined,
                      size: 28, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Upload New Policy Certificate (Required)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Click or drag & drop new policy document (PDF, PNG, JPG up to 25 MB) • Auto-scans fields',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _pickNewDocument({
    required Rx<PlatformFile?> selectedNewFile,
    required Rx<Uint8List?> selectedNewBytes,
    required Future<void> Function(Uint8List bytes, String fileName) onScan,
    required RxString errorMessage,
  }) async {
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
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime date,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: Get.context!,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2045),
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  AppFormatters.formatDate(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
