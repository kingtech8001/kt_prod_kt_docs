import 'dart:async';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_dropzone.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/platform_file_compat.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

/// Callback typedef for renewing appliance warranty or logging AMC / extended warranty
typedef ApplianceWarrantyRenewCallback =
    Future<void> Function({
      required DocumentModel previousDocument,
      required ApplianceWarrantyModel newWarranty,
      required String newTitle,
      required Uint8List fileBytes,
      required String fileName,
      String? newDescription,
    });

class RenewApplianceWarrantyDialog extends StatelessWidget {
  final DocumentModel previousDocument;
  final ApplianceWarrantyRenewCallback onRenew;

  const RenewApplianceWarrantyDialog({
    super.key,
    required this.previousDocument,
    required this.onRenew,
  });

  static Future<bool?> show({
    required DocumentModel previousDocument,
    required ApplianceWarrantyRenewCallback onRenew,
  }) {
    return AppDialog.show<bool>(
      RenewApplianceWarrantyDialog(
        previousDocument: previousDocument,
        onRenew: onRenew,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = previousDocument.applianceWarranty;
    final primaryItem = w?.primaryItem;
    final productName =
        primaryItem?.productName ?? w?.productName ?? previousDocument.title;
    final brand = primaryItem?.brand ?? w?.brand ?? 'Brand';
    final serialNumber = primaryItem?.serialNumber ?? w?.serialNumber ?? '';
    final modelNumber = primaryItem?.modelNumber ?? w?.modelNumber ?? '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prevExpiry = primaryItem?.effectiveValidUpto ?? w?.effectiveValidUpto;

    // Start date for the new renewal:
    final defaultStartDate = (prevExpiry != null && prevExpiry.isAfter(today))
        ? prevExpiry
        : today;

    // Default 1-year extension
    final defaultNewExpiry = DateTime(
      defaultStartDate.year + 1,
      defaultStartDate.month,
      defaultStartDate.day,
    );

    // Reactive State
    final selectedNewFile = Rx<PlatformFile?>(null);
    final selectedNewBytes = Rx<Uint8List?>(null);
    final selectedWarrantyType = 'extended'
        .obs; // 'extended', 'amc', 'component', 'lifetime', 'no_warranty'
    final selectedExpiryDate = Rx<DateTime>(defaultNewExpiry);
    final hasValidity = true.obs;

    final isSubmitting = false.obs;
    final errorMessage = ''.obs;

    // Controllers
    final providerController = TextEditingController(
      text: w?.amcProvider ?? (brand.isNotEmpty ? '$brand Care' : ''),
    );
    final policyNumberController = TextEditingController(
      text: w?.policyNumber ?? '',
    );
    final renewalCostController = TextEditingController(
      text: w?.renewalAmount != null
          ? w!.renewalAmount!.toStringAsFixed(0)
          : '',
    );
    final notesController = TextEditingController(text: w?.renewalNotes ?? '');
    final titleController = TextEditingController(
      text: '${productName.trim()} - Extended Warranty',
    );

    void updateTitle() {
      final type = selectedWarrantyType.value;
      String typeLabel = 'Extended Warranty';
      if (type == 'amc') typeLabel = 'Annual Maintenance Contract (AMC)';
      if (type == 'component') typeLabel = 'Component / Motor Warranty';
      if (type == 'lifetime') typeLabel = 'Lifetime Guarantee Certificate';
      if (type == 'no_warranty') typeLabel = 'Service / Repair Bill';
      titleController.text = '${productName.trim()} - $typeLabel';
    }

    void setPresetDuration(int years) {
      final base = (prevExpiry != null && prevExpiry.isAfter(today))
          ? prevExpiry
          : today;
      selectedExpiryDate.value = DateTime(
        base.year + years,
        base.month,
        base.day,
      );
      hasValidity.value = true;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 850),
        child: Column(
          children: [
            // 1. Header
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
                      Icons.add_moderator_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Renew / Extend Warranty & AMC',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$productName ($brand) • Model: ${modelNumber.isNotEmpty ? modelNumber : "N/A"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    tooltip: 'Close',
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
                    // Inline Error Message Banner
                    Obx(() {
                      if (errorMessage.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage.value,
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

                    // Context Banner: Previous Cycle Details
                    Container(
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
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'CURRENT APPLIANCE DETAILS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Invoice #${w?.invoiceNumber ?? previousDocument.documentNumber ?? "N/A"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Product Name',
                                  productName,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Brand & Model',
                                  '$brand • ${modelNumber.isNotEmpty ? modelNumber : "N/A"}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Serial Number',
                                  serialNumber.isNotEmpty
                                      ? serialNumber
                                      : 'Not recorded',
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Previous Warranty Until',
                                  prevExpiry != null
                                      ? AppFormatters.formatDate(prevExpiry)
                                      : 'Lifetime / No Expiry',
                                  isHighlighted: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 1: Warranty Renewal Type
                    const Text(
                      'Select Warranty Extension / Renewal Type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() {
                      final selected = selectedWarrantyType.value;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTypeChip(
                            label: 'Extended Warranty',
                            typeValue: 'extended',
                            icon: Icons.verified_user_outlined,
                            isSelected: selected == 'extended',
                            onTap: () {
                              selectedWarrantyType.value = 'extended';
                              hasValidity.value = true;
                              updateTitle();
                            },
                          ),
                          _buildTypeChip(
                            label: 'AMC Contract',
                            typeValue: 'amc',
                            icon: Icons.handyman_outlined,
                            isSelected: selected == 'amc',
                            onTap: () {
                              selectedWarrantyType.value = 'amc';
                              hasValidity.value = true;
                              updateTitle();
                            },
                          ),
                          _buildTypeChip(
                            label: 'Component / Motor',
                            typeValue: 'component',
                            icon: Icons.speed_outlined,
                            isSelected: selected == 'component',
                            onTap: () {
                              selectedWarrantyType.value = 'component';
                              hasValidity.value = true;
                              setPresetDuration(5);
                              updateTitle();
                            },
                          ),
                          _buildTypeChip(
                            label: 'Lifetime Guarantee',
                            typeValue: 'lifetime',
                            icon: Icons.all_inclusive_outlined,
                            isSelected: selected == 'lifetime',
                            onTap: () {
                              selectedWarrantyType.value = 'lifetime';
                              hasValidity.value = false;
                              updateTitle();
                            },
                          ),
                          _buildTypeChip(
                            label: 'Invoice / Bill Only',
                            typeValue: 'no_warranty',
                            icon: Icons.receipt_long_outlined,
                            isSelected: selected == 'no_warranty',
                            onTap: () {
                              selectedWarrantyType.value = 'no_warranty';
                              hasValidity.value = false;
                              updateTitle();
                            },
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 20),

                    // Section 2: File Upload (Dropzone & Picker)
                    const Text(
                      'Upload Renewal Certificate / AMC Slip / Invoice',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final file = selectedNewFile.value;
                      final bytes = selectedNewBytes.value;

                      if (file != null && bytes != null) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${(file.size / 1024).toStringAsFixed(1)} KB • Attached successfully',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  selectedNewFile.value = null;
                                  selectedNewBytes.value = null;
                                },
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                label: const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return _buildDropzone(
                        onFilePicked: (pickedFile, pickedBytes) {
                          errorMessage.value = '';
                          selectedNewFile.value = pickedFile;
                          selectedNewBytes.value = pickedBytes;
                        },
                      );
                    }),

                    const SizedBox(height: 20),

                    // Section 3: Validity & Expiry Tracker
                    Obx(() {
                      if (!hasValidity.value) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.border.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedWarrantyType.value == 'lifetime'
                                      ? 'Lifetime Guarantee selected: No expiration date required.'
                                      : 'No warranty validity tracked for invoice / repair bills.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Extended Warranty / AMC Valid Until',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              // Duration Quick Presets
                              Wrap(
                                spacing: 6,
                                children: [
                                  _buildPresetChip(
                                    '+1 Year',
                                    () => setPresetDuration(1),
                                  ),
                                  _buildPresetChip(
                                    '+2 Years',
                                    () => setPresetDuration(2),
                                  ),
                                  _buildPresetChip(
                                    '+3 Years',
                                    () => setPresetDuration(3),
                                  ),
                                  _buildPresetChip(
                                    '+5 Years',
                                    () => setPresetDuration(5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedExpiryDate.value,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2050),
                              );
                              if (picked != null) {
                                selectedExpiryDate.value = picked;
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.event_available_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppFormatters.formatDate(
                                      selectedExpiryDate.value,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Change Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 20),

                    // Section 4: Provider, Policy / Contract # & Cost
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AMC / Warranty Provider',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: providerController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Samsung Care+, Urban Company',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Policy / Contract Number',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: policyNumberController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. AMC-2026-99128',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Renewal Amount / Premium (₹)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: renewalCostController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. 4500',
                                  prefixText: '₹ ',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Document Title',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: titleController,
                                decoration: InputDecoration(
                                  hintText: 'Document title',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Coverage Notes & Inclusions',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Includes 2 preventive maintenance visits & gas replenishment',
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Footer Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(() {
                    return ElevatedButton.icon(
                      onPressed: isSubmitting.value
                          ? null
                          : () async {
                              // Validation
                              if (selectedNewBytes.value == null ||
                                  selectedNewFile.value == null) {
                                errorMessage.value =
                                    'Please select or drop the renewal invoice / AMC document.';
                                return;
                              }

                              if (titleController.text.trim().isEmpty) {
                                errorMessage.value =
                                    'Please provide a document title.';
                                return;
                              }

                              isSubmitting.value = true;
                              errorMessage.value = '';

                              try {
                                final cost = double.tryParse(
                                  renewalCostController.text.trim(),
                                );
                                final wType = selectedWarrantyType.value;
                                final hasExp =
                                    hasValidity.value &&
                                    wType != 'lifetime' &&
                                    wType != 'no_warranty';

                                // Construct updated ApplianceItemModel list
                                final updatedItems = (w?.items ?? []).map((
                                  item,
                                ) {
                                  return item.copyWith(
                                    extendedWarrantyUpto: hasExp
                                        ? selectedExpiryDate.value
                                        : null,
                                    warrantyType: wType,
                                    policyNumber:
                                        policyNumberController.text
                                            .trim()
                                            .isNotEmpty
                                        ? policyNumberController.text.trim()
                                        : item.policyNumber,
                                    amcProvider:
                                        providerController.text
                                            .trim()
                                            .isNotEmpty
                                        ? providerController.text.trim()
                                        : item.amcProvider,
                                    warrantyStatus: hasExp
                                        ? (selectedExpiryDate.value.isBefore(
                                                DateTime.now(),
                                              )
                                              ? 'expired'
                                              : 'active')
                                        : (wType == 'lifetime'
                                              ? 'active'
                                              : 'no_warranty'),
                                  );
                                }).toList();

                                final newWarranty =
                                    (w ??
                                            ApplianceWarrantyModel(
                                              billingName:
                                                  previousDocument.title,
                                              storeVendorName:
                                                  providerController.text
                                                      .trim(),
                                              invoiceNumber:
                                                  policyNumberController.text
                                                      .trim(),
                                              purchaseDate: DateTime.now(),
                                              purchaseAmount: cost ?? 0.0,
                                            ))
                                        .copyWith(
                                          warrantyType: wType,
                                          extendedWarrantyUpto: hasExp
                                              ? selectedExpiryDate.value
                                              : null,
                                          policyNumber:
                                              policyNumberController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? policyNumberController.text
                                                    .trim()
                                              : null,
                                          amcProvider:
                                              providerController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? providerController.text.trim()
                                              : null,
                                          renewalAmount: cost,
                                          renewalNotes:
                                              notesController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? notesController.text.trim()
                                              : null,
                                          items: updatedItems.isNotEmpty
                                              ? updatedItems
                                              : null,
                                        );

                                await onRenew(
                                  previousDocument: previousDocument,
                                  newWarranty: newWarranty,
                                  newTitle: titleController.text.trim(),
                                  fileBytes: selectedNewBytes.value!,
                                  fileName: selectedNewFile.value!.name,
                                  newDescription:
                                      notesController.text.trim().isNotEmpty
                                      ? notesController.text.trim()
                                      : null,
                                );

                                Get.back(result: true);
                              } catch (e, st) {
                                AppLogger.error(
                                  'RENEW_APPLIANCE_DIALOG',
                                  'Error executing warranty renewal: $e',
                                  error: e,
                                  stackTrace: st,
                                );
                                errorMessage.value = e.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                );
                              } finally {
                                isSubmitting.value = false;
                              }
                            },
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
                        isSubmitting.value
                            ? 'Renewing...'
                            : 'Save & Renew Warranty',
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

  Widget _buildInfoItem(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required String label,
    required String typeValue,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDropzone({
    required void Function(PlatformFile file, Uint8List bytes) onFilePicked,
  }) {
    return DropTarget(
      onDragDone: (detail) async {
        if (detail.files.isEmpty) return;
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
          onFilePicked(pf, bytes);
        } catch (error, stackTrace) {
          AppLogger.error(
            'RENEW_APPLIANCE_WARRANTY_DIALOG',
            'Operation failed; applying fallback.',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
      child: InkWell(
        onTap: () async {
          try {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
            );
            if (result.isNotEmpty) {
              final chosen = result.first;
              final bytes = chosen.bytes ?? await chosen.loadBytes();
              onFilePicked(chosen, bytes);
            }
          } catch (error, stackTrace) {
            AppLogger.error(
              'RENEW_APPLIANCE_WARRANTY_DIALOG',
              'Operation failed; applying fallback.',
              error: error,
              stackTrace: stackTrace,
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 36,
                color: AppColors.primary,
              ),
              SizedBox(height: 8),
              Text(
                'Click to browse or drag & drop renewal slip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Supports PDF, JPG, PNG up to 25 MB',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
