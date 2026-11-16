import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/modules/personal_docs/controllers/personal_doc_detail_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/google_drive_logo.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class PersonalDocDetailView extends GetView<PersonalDocDetailController> {
  const PersonalDocDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Personal Document Details',
      currentRoute: AppRoutes.PERSONAL_DOCS,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = controller.document.value;
        if (doc == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text(
                  'Document Not Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Personal Vault'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.reloadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, doc),
                    const SizedBox(height: AppConstants.paddingLarge),
                    _buildDetailsCard(context, doc),
                    const SizedBox(height: AppConstants.paddingLarge),
                    _buildHistoryTimelineCard(context, doc),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, DocumentModel doc) {
    final meta = doc.personalMetadata;
    final isExpired = meta?.isExpired ?? false;
    final isExpiringSoon = meta?.isExpiringSoon ?? false;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Get.back(),
                tooltip: 'Back to Personal Vault',
              ),
              const SizedBox(width: 8),
              const Text(
                'Personal & Insurance Vault',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(' / ', style: TextStyle(color: AppColors.textMuted)),
              Flexible(
                child: Text(
                  doc.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Main Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: doc.isGoogleAttachment
                      ? const Color(0xFFF0FDF4)
                      : (controller.isInsurance
                          ? const Color(0xFFEFF6FF)
                          : AppColors.primarySurface),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(
                    color: doc.isGoogleAttachment
                        ? const Color(0xFF86EFAC)
                        : (controller.isInsurance
                            ? const Color(0xFF93C5FD)
                            : AppColors.primary.withValues(alpha: 0.2)),
                  ),
                ),
                child: Center(
                  child: doc.isGoogleAttachment
                      ? const GoogleDriveLogo(size: 28)
                      : Icon(
                          controller.isInsurance
                              ? Icons.health_and_safety_outlined
                              : (doc.isPdf ? Icons.picture_as_pdf : Icons.badge_outlined),
                          color: controller.isInsurance
                              ? const Color(0xFF1D4ED8)
                              : (doc.isPdf ? AppColors.error : AppColors.primary),
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doc.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        StatusBadge(
                          label: isExpired
                              ? 'EXPIRED'
                              : (isExpiringSoon ? 'EXPIRING' : 'ACTIVE'),
                          type: isExpired
                              ? StatusBadgeType.error
                              : (isExpiringSoon
                                  ? StatusBadgeType.warning
                                  : StatusBadgeType.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meta?.personName ?? "General"}'
                      '${meta?.relationship != null ? " (${meta!.relationship})" : ""}'
                      ' • ${meta?.docTypeName ?? doc.subCategory}'
                      '${meta?.policyNumber != null && meta!.policyNumber!.isNotEmpty ? " • Policy #: ${meta.policyNumber}" : ""}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Preview'),
                    onPressed: () => controller.previewDocument(doc),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Download'),
                    onPressed: () => controller.downloadDocument(doc),
                  ),
                  if (controller.isInsurance)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.autorenew_rounded, size: 16),
                      label: const Text('Renew Policy'),
                      onPressed: () => controller.openRenewDialog(doc),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, DocumentModel doc) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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
                  Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Document & Policy Details (Editable)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Obx(() => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: controller.isSaving.value
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
                      controller.isSaving.value ? 'Saving...' : 'Save Document Details',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.saveDocumentDetails,
                  )),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Form Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoCol = constraints.maxWidth > 700;
              final colWidth =
                  isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildFormField(
                    label: 'Document Title *',
                    controller: controller.titleController,
                    width: colWidth,
                    icon: Icons.title_outlined,
                  ),
                  _buildFormField(
                    label: 'Person Name (Cardholder / Insured) *',
                    controller: controller.personNameController,
                    width: colWidth,
                    icon: Icons.person_outline,
                  ),
                  _buildFormField(
                    label: 'Relationship (Self, Spouse, Son, Mother, etc.)',
                    controller: controller.relationshipController,
                    width: colWidth,
                    icon: Icons.people_outline,
                  ),
                  _buildFormField(
                    label: 'Document Type (e.g. Health Insurance, Aadhaar Card) *',
                    controller: controller.docTypeNameController,
                    width: colWidth,
                    icon: Icons.category_outlined,
                  ),
                  _buildFormField(
                    label: 'ID / Policy / Covernote Number',
                    controller: controller.idNumberController,
                    width: colWidth,
                    icon: Icons.tag,
                  ),
                  _buildFormField(
                    label: 'Issuing Authority / Govt Body',
                    controller: controller.issuingAuthorityController,
                    width: colWidth,
                    icon: Icons.account_balance_outlined,
                  ),
                  _buildDatePickerField(
                    context: context,
                    label: 'Issue / Policy Start Date',
                    date: controller.issueDate.value,
                    width: colWidth,
                    onSelected: (dt) => controller.issueDate.value = dt,
                  ),
                  _buildDatePickerField(
                    context: context,
                    label: 'Expiry / Renewal Due Date',
                    date: controller.expiryDate.value,
                    width: colWidth,
                    onSelected: (dt) => controller.expiryDate.value = dt,
                  ),

                  // If insurance or financial policy
                  if (controller.isInsurance) ...[
                    _buildFormField(
                      label: 'Insurance Underwriter / Company Name',
                      controller: controller.insuranceCompanyController,
                      width: colWidth,
                      icon: Icons.business_outlined,
                    ),
                    _buildFormField(
                      label: 'Policy Type (Family Floater, Individual, Term)',
                      controller: controller.policyTypeController,
                      width: colWidth,
                      icon: Icons.policy_outlined,
                    ),
                    _buildFormField(
                      label: 'Sum Insured / Coverage Amount (₹)',
                      controller: controller.sumInsuredController,
                      width: colWidth,
                      icon: Icons.currency_rupee,
                      isNumeric: true,
                    ),
                    _buildFormField(
                      label: 'Annual Premium Amount (₹)',
                      controller: controller.premiumAmountController,
                      width: colWidth,
                      icon: Icons.receipt_outlined,
                      isNumeric: true,
                    ),
                    _buildFormField(
                      label: 'TPA (Third Party Administrator) Name',
                      controller: controller.tpaNameController,
                      width: colWidth,
                      icon: Icons.medical_services_outlined,
                    ),
                    _buildFormField(
                      label: 'Coverage Endorsements & Notes',
                      controller: controller.notesController,
                      width: colWidth,
                      icon: Icons.note_outlined,
                    ),
                  ],

                  // Description
                  _buildFormField(
                    label: 'Description / Notes',
                    controller: controller.descriptionController,
                    width: constraints.maxWidth,
                    icon: Icons.notes_outlined,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required double width,
    required IconData icon,
    bool isNumeric = false,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required double width,
    required ValueChanged<DateTime> onSelected,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(1980),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (picked != null) onSelected(picked);
            },
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    date != null ? AppFormatters.formatDate(date) : 'Select Date',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTimelineCard(BuildContext context, DocumentModel doc) {
    final history = controller.renewalHistory;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    controller.isInsurance
                        ? 'Policy Renewal History & Lineage (${history.length})'
                        : 'Document Version History (${history.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (controller.isInsurance)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.autorenew_rounded, size: 16),
                  label: const Text('Renew / Upload Next Term'),
                  onPressed: () => controller.openRenewDialog(doc),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          const Divider(),
          const SizedBox(height: AppConstants.paddingMedium),

          if (history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text('No history records available.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildHistoryRow(context, item, isCurrent: item.id == doc.id);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    DocumentModel item, {
    required bool isCurrent,
  }) {
    final meta = item.personalMetadata;
    final isExpired = meta?.isExpired ?? false;
    final isExpiringSoon = meta?.isExpiringSoon ?? false;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              item.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file_outlined,
              color: item.isPdf ? AppColors.error : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else if (meta?.renewalCount != null && meta!.renewalCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Renewal #${meta.renewalCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${meta?.policyNumber != null && meta!.policyNumber!.isNotEmpty ? "Policy #: ${meta.policyNumber} • " : ""}'
                  '${meta?.expiryDate != null ? "Validity: ${meta?.issueDate != null ? AppFormatters.formatDate(meta!.issueDate) : ''} to ${AppFormatters.formatDate(meta!.expiryDate)}" : "Uploaded: ${AppFormatters.formatDate(item.createdAt)}"}'
                  '${meta?.premiumAmount != null ? " • Premium: ${AppFormatters.formatCurrency(meta!.premiumAmount)}" : ""}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          StatusBadge(
            label: isExpired ? 'EXPIRED' : (isExpiringSoon ? 'EXPIRING' : 'ACTIVE'),
            type: isExpired
                ? StatusBadgeType.error
                : (isExpiringSoon ? StatusBadgeType.warning : StatusBadgeType.success),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Wrap(
            spacing: 4,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 19),
                tooltip: 'Preview Document',
                onPressed: () => controller.previewDocument(item),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 19),
                tooltip: 'Download Document',
                onPressed: () => controller.downloadDocument(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
