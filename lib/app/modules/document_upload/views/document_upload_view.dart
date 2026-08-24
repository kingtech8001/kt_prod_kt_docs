import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/document_upload/controllers/document_upload_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_dropzone.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/utils/file_compressor.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class DocumentUploadView extends GetView<DocumentUploadController> {
  const DocumentUploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Upload Document to Vault',
      subtitle:
          'Add utility bills, appliance warranty invoices, or corporate records with structured metadata',
      currentRoute: AppRoutes.UPLOAD,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 850;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: File Dropzone, Compression Card & Overview
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Obx(() => WebDropzone(
                                  onFileSelected: controller.onFileSelected,
                                  currentFile: controller.selectedFile.value,
                                )),
                            _buildCompressionCard(context),
                            const SizedBox(height: 20),
                            _buildSecurityBadge(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Right Column: Dynamic Category & Metadata Form
                      Expanded(
                        flex: 6,
                        child: _buildFormCard(context),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Obx(() => WebDropzone(
                            onFileSelected: controller.onFileSelected,
                            currentFile: controller.selectedFile.value,
                          )),
                      _buildCompressionCard(context),
                      const SizedBox(height: 20),
                      _buildFormCard(context),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'End-to-End Vault Security',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Files are uploaded directly into a private encrypted storage bucket. Access requires signed temporary tokens.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Metadata & Classification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Categorize your file to enable city filtering, due date reminders, and warranty status tracking.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 28),

          // Category Selector
          const Text(
            'Document Category *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: controller.selectedCategoryId.value.isNotEmpty
                        ? controller.selectedCategoryId.value
                        : null,
                    items: controller.categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: controller.onCategoryChanged,
                  ),
                ),
              )),
          const SizedBox(height: 16),

          // Subcategory Dropdown
          const Text(
            'Document Subcategory *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Obx(() => _buildSubcategoryDropdown()),
          const SizedBox(height: 16),

          // Title Field (Conditionally displayed based on Category configuration)
          Obx(() {
            if (!controller.showTitleField) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Title *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Torrent Power Bill - Feb 2026, Havells Fan Invoice',
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          }),

          // Dynamic Metadata Forms
          Obx(() {
            if (controller.isUtilityBill) {
              return Column(
                children: [
                  _buildUtilityMetadataSection(context),
                  const SizedBox(height: 20),
                ],
              );
            } else if (controller.isApplianceWarranty) {
              return Column(
                children: [
                  _buildApplianceMetadataSection(context),
                  const SizedBox(height: 20),
                ],
              );
            } else if (controller.isPersonalDoc) {
              return Column(
                children: [
                  _buildPersonalMetadataSection(context),
                  const SizedBox(height: 20),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Address Section (Conditionally displayed based on Category City Filter configuration)
          Obx(() {
            if (!controller.showCityFilter) return const SizedBox.shrink();
            return Column(
              children: [
                _buildAddressSection(),
                const SizedBox(height: 24),
              ],
            );
          }),

          // Submit Upload Button
          Obx(() {
            final isUploading = controller.isLoading.value;
            final isCompressing = controller.isCompressing.value;
            final isBusy = isUploading || isCompressing;

            String buttonText = 'Save & Secure Document';
            if (isUploading) {
              buttonText = 'Encrypting & Uploading...';
            } else if (isCompressing) {
              buttonText = 'Optimizing Document...';
            }

            return SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : controller.submitUpload,
                icon: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubcategoryDropdown() {
    List<String> options = ['General Document'];
    if (controller.isUtilityBill) {
      options = controller.dynamicUtilityTypes.isNotEmpty
          ? controller.dynamicUtilityTypes
          : AppConstants.utilitySubcategories;
    } else if (controller.isApplianceWarranty) {
      options = controller.dynamicApplianceSubcategories.isNotEmpty
          ? controller.dynamicApplianceSubcategories
          : AppConstants.applianceSubcategories;
    } else if (controller.isPersonalDoc) {
      options = controller.dynamicPersonalDocTypes.isNotEmpty
          ? controller.dynamicPersonalDocTypes.map((t) => t.name).toList()
          : ['Aadhaar Card', 'PAN Card', 'Chutni Card (Voter ID)', 'Passport', 'Driving License'];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: options.contains(controller.selectedSubcategory.value)
              ? controller.selectedSubcategory.value
              : (options.isNotEmpty ? options.first : null),
          items: options
              .map((sub) => DropdownMenuItem(
                    value: sub,
                    child: Text(sub, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) controller.selectedSubcategory.value = val;
          },
        ),
      ),
    );
  }

  Widget _buildUtilityMetadataSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.utilityAmberLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.utilityAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: AppColors.utilityAmber, size: 20),
              SizedBox(width: 8),
              Text(
                'Utility Bill Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Provider Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.utilityProviderController,
                      decoration: const InputDecoration(hintText: 'e.g. Torrent Power, Adani Gas, UGVCL'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Consumer Number / ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.consumerNumberController,
                      decoration: const InputDecoration(hintText: 'e.g. 10293849'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bill Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.billAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '3450'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: controller.utilityPaymentStatus.value,
                              items: const [
                                DropdownMenuItem(value: 'pending', child: Text('Pending Payment')),
                                DropdownMenuItem(value: 'paid', child: Text('Paid')),
                              ],
                              onChanged: (val) {
                                if (val != null) controller.utilityPaymentStatus.value = val;
                              },
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceMetadataSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warrantyEmeraldLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warrantyEmerald.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.warrantyEmerald, size: 20),
              SizedBox(width: 8),
              Text(
                'Appliance & Warranty Invoice Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Brand *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: controller.selectedBrand.value,
                              items: (controller.dynamicBrands.isNotEmpty
                                      ? [...controller.dynamicBrands, 'Other']
                                      : [...AppConstants.popularBrands, 'Other'])
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) controller.selectedBrand.value = val;
                              },
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Billing / Customer Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.billingNameController,
                      decoration: const InputDecoration(hintText: 'King Technology / Mihir Shah'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Store / Vendor Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.storeVendorNameController,
                      decoration: const InputDecoration(hintText: 'e.g. Vijay Sales, Croma, Amazon'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Warranty Period (Months)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: controller.warrantyMonths.value,
                              items: const [
                                DropdownMenuItem(value: 6, child: Text('6 Months')),
                                DropdownMenuItem(value: 12, child: Text('1 Year (12 Months)')),
                                DropdownMenuItem(value: 24, child: Text('2 Years (24 Months)')),
                                DropdownMenuItem(value: 36, child: Text('3 Years (36 Months)')),
                                DropdownMenuItem(value: 60, child: Text('5 Years (60 Months)')),
                                DropdownMenuItem(value: 120, child: Text('10 Years (Motor/Compressor)')),
                              ],
                              onChanged: (val) {
                                if (val != null) controller.updateWarrantyMonths(val);
                              },
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Serial / Model No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.serialNumberController,
                      decoration: const InputDecoration(hintText: 'SN-9384920'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Warranty Expiry Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            AppFormatters.formatDate(controller.warrantyValidUpto.value),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warrantyEmerald),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalMetadataSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Personal & Identity Document Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Person Selection Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Person / Family Member *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() {
                      final pNames = controller.dynamicPersons.map((p) => p.fullName).toList();
                      if (pNames.isEmpty) pNames.add('Mihir Gandhi');

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: pNames.contains(controller.selectedPersonName.value)
                                ? controller.selectedPersonName.value
                                : pNames.first,
                            items: pNames.map((name) {
                              final person = controller.dynamicPersons.firstWhereOrNull((p) => p.fullName == name);
                              final rel = person?.relationship != null ? ' (${person!.relationship})' : '';
                              return DropdownMenuItem(value: name, child: Text('$name$rel'));
                            }).toList(),
                            onChanged: controller.onPersonChanged,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Document Type Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Identity Document Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() {
                      final types = controller.dynamicPersonalDocTypes.map((t) => t.name).toList();
                      if (types.isEmpty) types.addAll(['Aadhaar Card', 'PAN Card', 'Chutni Card (Voter ID)', 'Passport', 'Driving License']);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: types.contains(controller.selectedPersonalDocTypeName.value)
                                ? controller.selectedPersonalDocTypeName.value
                                : types.first,
                            items: types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                            onChanged: controller.onPersonalDocTypeChanged,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // ID Number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ID / Document / Card Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.personalIdNumberController,
                      decoration: const InputDecoration(hintText: 'e.g. 1234-5678-9012 or ABCDE1234F'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Issuing Authority
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Issuing Authority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.personalIssuingAuthorityController,
                      decoration: const InputDecoration(hintText: 'e.g. UIDAI, Income Tax Dept, ECI'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Issue Date Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Issue Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() => InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: controller.personalIssueDate.value ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2050),
                            );
                            if (picked != null) controller.personalIssueDate.value = picked;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  controller.personalIssueDate.value != null
                                      ? AppFormatters.formatDate(controller.personalIssueDate.value!)
                                      : 'Select Issue Date',
                                  style: TextStyle(
                                    color: controller.personalIssueDate.value != null ? AppColors.textPrimary : AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Expiry Date Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expiry Date (if applicable)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() => InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: controller.personalExpiryDate.value ?? DateTime.now().add(const Duration(days: 3650)),
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2060),
                            );
                            if (picked != null) controller.personalExpiryDate.value = picked;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  controller.personalExpiryDate.value != null
                                      ? AppFormatters.formatDate(controller.personalExpiryDate.value!)
                                      : 'Select Expiry Date',
                                  style: TextStyle(
                                    color: controller.personalExpiryDate.value != null ? AppColors.textPrimary : AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                const Icon(Icons.event_busy, size: 16, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Location & Address Information (For City Filtering)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('City *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: controller.selectedCity.value,
                              items: (controller.dynamicCities.isNotEmpty
                                      ? controller.dynamicCities
                                      : AppConstants.supportedCities.where((c) => c != 'All Cities').toList())
                                  .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) controller.selectedCity.value = val;
                              },
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Area / Locality / Premises', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.areaLocalityController,
                      decoration: const InputDecoration(hintText: 'e.g. SG Highway, Bodakdev, Corporate HQ'),
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

  Widget _buildCompressionCard(BuildContext context) {
    return Obx(() {
      final file = controller.selectedFile.value;
      if (file == null || !controller.isSelectedFileCompressible) {
        return const SizedBox.shrink();
      }

      final result = controller.compressionResult.value;
      final isCompressing = controller.isCompressing.value;

      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    result?.isPdf == true ? Icons.picture_as_pdf_outlined : Icons.compress,
                    color: result?.isPdf == true ? AppColors.error : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            result?.isPdf == true
                                ? 'Smart PDF Compressor'
                                : 'Smart Image Compressor',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: result?.isPdf == true
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              result?.isPdf == true ? 'PDF' : 'IMAGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: result?.isPdf == true ? AppColors.error : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Optimize size for faster vault loading & preview',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (result != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: result.savingsPercent > 0
                          ? AppColors.successLight
                          : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (result.savingsPercent > 0
                                ? AppColors.success
                                : AppColors.info)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      result.savingsPercent > 0
                          ? '🔥 ${result.savingsFormatted} Saved'
                          : '⚡ Optimized',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: result.savingsPercent > 0
                            ? AppColors.successDark
                            : AppColors.info,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Prominent Progressive Loader banner shown whenever compression is actively calculating
            if (isCompressing)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Optimizing with ${controller.compressionQuality.value}% quality',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(controller.compressionProgress.value * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.compressionProgressText.value.isNotEmpty
                          ? controller.compressionProgressText.value
                          : 'Analyzing streams & calculating new compressed file size. Please wait...',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(
                        value: controller.compressionProgress.value.clamp(0.05, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

            // Comparison Banner (Before vs After)
            if (result != null || isCompressing) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Original (Before)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result?.originalSizeFormatted ??
                                (controller.selectedFile.value != null
                                    ? CompressionResult.formatFileSize(controller.selectedFile.value!.size)
                                    : '--'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Compressed (After)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.successDark),
                          ),
                          const SizedBox(height: 2),
                          if (isCompressing)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(controller.compressionProgress.value * 100).toInt()}%...',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              result?.compressedSizeFormatted ?? '--',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (result != null && result.isPdf && !result.hasEmbeddedImages) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vector Text PDF: This document consists of clean scalable text and fonts (no heavy raster scans). It is already at optimal minimum size.',
                          style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Upload Target Radios
              const Text(
                'Choose Upload Version:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              // Option 1: Compressed (Always Default Selected)
              InkWell(
                onTap: () => controller.useCompressed.value = true,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: controller.useCompressed.value
                        ? AppColors.primarySurface
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: controller.useCompressed.value
                          ? AppColors.primary
                          : AppColors.border,
                      width: controller.useCompressed.value ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: controller.useCompressed.value,
                        onChanged: (val) => controller.useCompressed.value = val ?? true,
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Upload Compressed File',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Recommended',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Optimized size (${result?.compressedSizeFormatted ?? 'calculated on finish'}). Faster preview & saving storage.',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Option 2: Original Quality
              InkWell(
                onTap: () => controller.useCompressed.value = false,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: !controller.useCompressed.value
                        ? AppColors.primarySurface
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !controller.useCompressed.value
                          ? AppColors.primary
                          : AppColors.border,
                      width: !controller.useCompressed.value ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: controller.useCompressed.value,
                        onChanged: (val) => controller.useCompressed.value = val ?? false,
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Original Quality',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Full original file (${result?.originalSizeFormatted ?? CompressionResult.formatFileSize(controller.selectedFile.value?.size ?? 0)}) without compression.',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (controller.useCompressed.value) ...[
                const SizedBox(height: 16),

                // Compression Quality Controls (Only shown for Compressed option)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Compression Quality Level',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${controller.compressionQuality.value}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Preset buttons
                      Row(
                        children: [
                          _buildQualityPresetButton(85, 'High (85%)'),
                          const SizedBox(width: 8),
                          _buildQualityPresetButton(70, 'Balanced (70%)'),
                          const SizedBox(width: 8),
                          _buildQualityPresetButton(50, 'Max (50%)'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        ),
                        child: Slider(
                          value: controller.compressionQuality.value.toDouble(),
                          min: 30,
                          max: 95,
                          divisions: 13,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.border,
                          onChanged: (val) {
                            controller.compressionQuality.value = val.round();
                          },
                          onChangeEnd: (val) {
                            controller.setCompressionQuality(val.round());
                          },
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
    });
  }

  Widget _buildQualityPresetButton(int quality, String label) {
    final isSelected = controller.compressionQuality.value == quality;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setCompressionQuality(quality),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
