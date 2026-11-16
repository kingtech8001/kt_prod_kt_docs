import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_connection_account.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/utils/platform_file_compat.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

typedef LogNextUtilityBillCallback = Future<void> Function({
  required String consumerNumber,
  String? meterNumber,
  required String providerName,
  required String utilityType,
  String? premiseName,
  String? flatHouseNo,
  String? city,
  required String title,
  String? description,
  required double billAmount,
  required DateTime billDate,
  DateTime? dueDate,
  required String paymentStatus,
  DateTime? paymentDate,
  String? paymentReferenceId,
  required Uint8List fileBytes,
  required String fileName,
});

class UploadNextUtilityBillDialog extends StatelessWidget {
  final UtilityConnectionAccount connection;
  final LogNextUtilityBillCallback onLogBill;

  const UploadNextUtilityBillDialog({
    super.key,
    required this.connection,
    required this.onLogBill,
  });

  static Future<bool?> show({
    required UtilityConnectionAccount connection,
    required LogNextUtilityBillCallback onLogBill,
  }) {
    return AppDialog.show<bool>(
      UploadNextUtilityBillDialog(
        connection: connection,
        onLogBill: onLogBill,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selectedNewFile = Rxn<PlatformFile>();
    final selectedNewBytes = Rxn<Uint8List>();
    final isSubmitting = false.obs;
    final errorMessage = ''.obs;

    final titleController = TextEditingController(
      text: '${connection.displayName} - ${AppFormatters.formatDate(now)}',
    );
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final paymentRefController = TextEditingController();

    final billDate = now.obs;
    final dueDate = now.add(const Duration(days: 15)).obs;
    final isPaid = false.obs;
    final paymentDate = now.obs;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
        child: Column(
          children: [
            // Header
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
                      color: connection.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      connection.iconData,
                      color: connection.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Next Cycle Bill',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          connection.displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(result: false),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Connection Account Reference Card (Locked)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      connection.providerName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        connection.utilityType,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Consumer #: ${connection.consumerNumber}${connection.city != null ? " • ${connection.city}" : ""}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'LOCKED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Upload New Bill File
                    const Text(
                      'Select New Bill Document (PDF / Image)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final file = selectedNewFile.value;
                      if (file == null) {
                        return InkWell(
                          onTap: () => _pickNewFile(selectedNewFile, selectedNewBytes),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Click to select or drop new bill PDF / Image',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'PDF, JPG, PNG up to 25MB',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              color: AppColors.error,
                              size: 28,
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
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    AppFormatters.formatFileSize(file.size),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                selectedNewFile.value = null;
                                selectedNewBytes.value = null;
                              },
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              tooltip: 'Remove File',
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 18),

                    // 3. Bill Title / Cycle Name
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Bill Cycle / Document Title',
                        hintText: 'e.g. Nov-Dec/26 EC bill',
                        prefixIcon: Icon(Icons.title, size: 18),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    // 4. Amount & Payment Status Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'New Bill Amount (₹)',
                              hintText: 'e.g. 3545.45',
                              prefixIcon: Icon(Icons.currency_rupee, size: 18),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Obx(() {
                            return InkWell(
                              onTap: () => isPaid.toggle(),
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Payment Status',
                                  prefixIcon: Icon(Icons.payment, size: 18),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isPaid.value ? 'PAID' : 'PENDING',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isPaid.value ? AppColors.success : AppColors.warning,
                                      ),
                                    ),
                                    Switch(
                                      value: isPaid.value,
                                      onChanged: (v) => isPaid.value = v,
                                      activeThumbColor: AppColors.success,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 5. Bill Date & Due Date Row
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            return InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: billDate.value,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) billDate.value = picked;
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Bill Date',
                                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                                ),
                                child: Text(
                                  AppFormatters.formatDate(billDate.value),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Obx(() {
                            return InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate.value,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) dueDate.value = picked;
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Due Date',
                                  prefixIcon: Icon(Icons.event_available, size: 18),
                                ),
                                child: Text(
                                  AppFormatters.formatDate(dueDate.value),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 6. Optional Payment Reference (if paid)
                    Obx(() {
                      if (!isPaid.value) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextField(
                          controller: paymentRefController,
                          decoration: const InputDecoration(
                            labelText: 'Payment Reference / Transaction ID (Optional)',
                            hintText: 'e.g. UPI-984210934 or Cheque #',
                            prefixIcon: Icon(Icons.receipt_outlined, size: 18),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      );
                    }),

                    // 7. Notes / Remarks
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Remarks (Optional)',
                        hintText: 'e.g. Includes solar credit adjustments',
                        prefixIcon: Icon(Icons.notes, size: 18),
                      ),
                      maxLines: 2,
                    ),

                    // In-Context Error Banner
                    Obx(() {
                      if (errorMessage.value.isEmpty) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage.value,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
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

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
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
                              errorMessage.value = '';
                              if (selectedNewFile.value == null ||
                                  selectedNewBytes.value == null ||
                                  selectedNewBytes.value!.isEmpty) {
                                errorMessage.value =
                                    'Please select and upload the new bill PDF or image file.';
                                return;
                              }
                              final amt = double.tryParse(amountController.text.trim());
                              if (amt == null || amt <= 0) {
                                errorMessage.value =
                                    'Please enter a valid bill amount greater than ₹0.';
                                return;
                              }
                              final title = titleController.text.trim().isNotEmpty
                                  ? titleController.text.trim()
                                  : '${connection.displayName} - ${AppFormatters.formatDate(billDate.value)}';

                              isSubmitting.value = true;
                              try {
                                await onLogBill(
                                  consumerNumber: connection.consumerNumber,
                                  meterNumber: connection.meterNumber,
                                  providerName: connection.providerName,
                                  utilityType: connection.utilityType,
                                  premiseName: connection.premiseName,
                                  flatHouseNo: connection.flatHouseNo,
                                  city: connection.city,
                                  title: title,
                                  description: notesController.text.trim().isNotEmpty
                                      ? notesController.text.trim()
                                      : null,
                                  billAmount: amt,
                                  billDate: billDate.value,
                                  dueDate: dueDate.value,
                                  paymentStatus: isPaid.value ? 'paid' : 'pending',
                                  paymentDate: isPaid.value ? paymentDate.value : null,
                                  paymentReferenceId: paymentRefController.text.trim().isNotEmpty
                                      ? paymentRefController.text.trim()
                                      : null,
                                  fileBytes: selectedNewBytes.value!,
                                  fileName: selectedNewFile.value!.name,
                                );
                                Get.back(result: true);
                              } catch (e) {
                                errorMessage.value = 'Failed to log bill: $e';
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
                        isSubmitting.value ? 'Uploading & Logging...' : 'Confirm & Log Bill',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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

  Future<void> _pickNewFile(
    Rx<PlatformFile?> selectedNewFile,
    Rx<Uint8List?> selectedNewBytes,
  ) async {
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
      }
    } catch (e) {
      Get.snackbar(
        'File Selection Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
