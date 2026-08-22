import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/document_upload/controllers/document_upload_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_dropzone.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
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
                      // Left Column: File Dropzone & Overview
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Obx(() => WebDropzone(
                                  onFileSelected: controller.onFileSelected,
                                  currentFile: controller.selectedFile.value,
                                )),
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

          // Title
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

          // Address Section (Always relevant for location-based search)
          _buildAddressSection(),
          const SizedBox(height: 24),

          // Submit Upload Button
          Obx(() => SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: controller.isLoading.value ? null : controller.submitUpload,
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    controller.isLoading.value ? 'Encrypting & Uploading...' : 'Save & Secure Document',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              )),
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
}
