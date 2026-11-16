import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

typedef SaveBillCycleCallback = Future<void> Function({
  required String documentId,
  required String title,
  String? description,
  required double billAmount,
  required DateTime billDate,
  DateTime? dueDate,
  required String paymentStatus,
  DateTime? paymentDate,
  String? paymentReferenceId,
  String? meterNumber,
  double? unitsConsumed,
});

class EditUtilityBillDialog extends StatelessWidget {
  final DocumentModel bill;
  final SaveBillCycleCallback onSave;

  const EditUtilityBillDialog({
    super.key,
    required this.bill,
    required this.onSave,
  });

  static Future<bool?> show({
    required DocumentModel bill,
    required SaveBillCycleCallback onSave,
  }) {
    return AppDialog.show<bool>(
      EditUtilityBillDialog(
        bill: bill,
        onSave: onSave,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = bill.utilityMetadata;

    final titleController = TextEditingController(text: bill.title);
    final amountController = TextEditingController(
      text: meta != null ? meta.billAmount.toStringAsFixed(0) : '0',
    );
    final billDate = Rx<DateTime>(meta?.billDate ?? bill.createdAt);
    final dueDate = Rxn<DateTime>(meta?.dueDate);
    final paymentStatus = (meta?.paymentStatus ?? 'pending').obs;
    final paymentDate = Rxn<DateTime>(meta?.paymentDate);
    final paymentRefController = TextEditingController(
      text: meta?.paymentReferenceId ?? '',
    );
    final meterNumberController = TextEditingController(
      text: meta?.meterNumber ?? '',
    );
    final unitsConsumedController = TextEditingController(
      text: meta?.unitsConsumed != null ? meta!.unitsConsumed!.toString() : '',
    );
    final descriptionController = TextEditingController(
      text: bill.description ?? '',
    );

    final isSaving = false.obs;
    final errorMessage = RxnString();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Billing Cycle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Update amount, dates, payment status, or notes',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Get.back(result: false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Error Banner
              Obx(() {
                if (errorMessage.value == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage.value!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // 1. Bill Title
              const Text(
                'Bill Cycle Title *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. September-October 2026 EC bill',
                  prefixIcon: Icon(Icons.title, size: 18),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Bill Amount & Payment Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Amount (₹) *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. 3545',
                            prefixIcon: Icon(Icons.currency_rupee, size: 18),
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
                          'Payment Status *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusSmall,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: paymentStatus.value,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'paid',
                                    child: Text('PAID'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'pending',
                                    child: Text('PENDING'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'overdue',
                                    child: Text('OVERDUE'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'auto_debit',
                                    child: Text('AUTO DEBIT'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    paymentStatus.value = val;
                                    if (val == 'paid' && paymentDate.value == null) {
                                      paymentDate.value = DateTime.now();
                                    }
                                  }
                                },
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

              // 3. Bill Date & Due Date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill / Cycle Date *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Obx(
                          () => InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: billDate.value,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) billDate.value = picked;
                            },
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusSmall,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSmall,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppFormatters.formatDate(billDate.value),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
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
                          'Due Date (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Obx(
                          () => InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    dueDate.value ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) dueDate.value = picked;
                            },
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusSmall,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSmall,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_outlined,
                                      size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dueDate.value != null
                                          ? AppFormatters.formatDate(
                                              dueDate.value!)
                                          : 'No Due Date',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: dueDate.value != null
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  if (dueDate.value != null)
                                    InkWell(
                                      onTap: () => dueDate.value = null,
                                      child: const Icon(Icons.clear, size: 16),
                                    ),
                                ],
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

              // 4. Payment Date & Payment Reference (when paid)
              Obx(() {
                if (paymentStatus.value != 'paid' &&
                    paymentStatus.value != 'auto_debit') {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: paymentDate.value ??
                                        DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    paymentDate.value = picked;
                                  }
                                },
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSmall,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusSmall,
                                    ),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 16,
                                          color: AppColors.success),
                                      const SizedBox(width: 8),
                                      Text(
                                        paymentDate.value != null
                                            ? AppFormatters.formatDate(
                                                paymentDate.value!)
                                            : 'Select Payment Date',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
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
                                'Payment Ref / UTR #',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              TextField(
                                controller: paymentRefController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. UPI / NetBanking Ref',
                                  prefixIcon: Icon(Icons.receipt_outlined,
                                      size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              }),

              // 5. Meter Number & Units Consumed
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meter Number',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: meterNumberController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. MTR-1118',
                            prefixIcon: Icon(Icons.speed_outlined, size: 18),
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
                          'Units Consumed (kWh/Units)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: unitsConsumedController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. 420.5',
                            prefixIcon: Icon(Icons.bolt_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6. Notes / Description
              const Text(
                'Notes / Description (Optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Includes penalty / revised solar rebate',
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: isSaving.value
                          ? null
                          : () async {
                              final title = titleController.text.trim();
                              final amountStr = amountController.text.trim();

                              if (title.isEmpty) {
                                errorMessage.value =
                                    'Bill Title cannot be empty.';
                                return;
                              }

                              final amount = double.tryParse(amountStr);
                              if (amount == null || amount < 0) {
                                errorMessage.value =
                                    'Please enter a valid bill amount.';
                                return;
                              }

                              isSaving.value = true;
                              errorMessage.value = null;

                              try {
                                final units = double.tryParse(
                                  unitsConsumedController.text.trim(),
                                );
                                await onSave(
                                  documentId: bill.id,
                                  title: title,
                                  description: descriptionController.text
                                          .trim()
                                          .isNotEmpty
                                      ? descriptionController.text.trim()
                                      : null,
                                  billAmount: amount,
                                  billDate: billDate.value,
                                  dueDate: dueDate.value,
                                  paymentStatus: paymentStatus.value,
                                  paymentDate: paymentDate.value,
                                  paymentReferenceId: paymentRefController
                                          .text
                                          .trim()
                                          .isNotEmpty
                                      ? paymentRefController.text.trim()
                                      : null,
                                  meterNumber: meterNumberController.text
                                          .trim()
                                          .isNotEmpty
                                      ? meterNumberController.text.trim()
                                      : null,
                                  unitsConsumed: units,
                                );
                                Get.back(result: true);
                              } catch (e) {
                                errorMessage.value =
                                    'Failed to update bill cycle: $e';
                              } finally {
                                isSaving.value = false;
                              }
                            },
                      icon: isSaving.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isSaving.value ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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
