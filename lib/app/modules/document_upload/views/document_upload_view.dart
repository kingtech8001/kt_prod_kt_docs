import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/document_upload/controllers/document_upload_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
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
      body: Obx(() {
        if (controller.isInitialLoading.value) {
          return const DocumentUploadSkeletonView();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingExtraLarge),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop =
                      constraints.maxWidth >= AppConstants.desktopBreakpoint;

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
                              Obx(
                                () => WebDropzone(
                                  onFileSelected: controller.onFileSelected,
                                  currentFile: controller.selectedFile.value,
                                ),
                              ),
                              _buildCompressionCard(context),
                              const SizedBox(height: 20),
                              _buildSecurityBadge(),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingExtraLarge),

                        // Right Column: Dynamic Category & Metadata Form
                        Expanded(flex: 6, child: _buildFormCard(context)),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Obx(
                          () => WebDropzone(
                            onFileSelected: controller.onFileSelected,
                            currentFile: controller.selectedFile.value,
                          ),
                        ),
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
        );
      }),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
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
                  style: TextStyle(
                    fontSize: 12,
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

          // Inline Error Banner (Section 3.B: In-Context Form Error Handling)
          Obx(() {
            final err = controller.formErrorMessage.value;
            if (err.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      err,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => controller.formErrorMessage.value = '',
                  ),
                ],
              ),
            );
          }),

          // Category Selector
          const Text(
            'Document Category *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Container(
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
            ),
          ),
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
                    hintText:
                        'e.g. Torrent Power Bill - Feb 2026, Havells Fan Invoice',
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),

          // Description / Product Notes Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Document Description / Product Notes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller.descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Invoice covering multiple products (1x Refrigerator, 2x Fans), warranty claim instructions, or store notes',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),

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
            } else if (controller.isVehicleDoc) {
              return Column(
                children: [
                  _buildVehicleMetadataSection(context),
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
              children: [_buildAddressSection(context), const SizedBox(height: 24)],
            );
          }),

          // Submit Upload Button (Section 5.A: Micro inline spinner during submission)
          Obx(() {
            final isUploading = controller.isSubmitting.value;
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
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.textOnPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
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
          : [
              'Aadhaar Card',
              'PAN Card',
              'Chutni Card (Voter ID)',
              'Passport',
              'Driving License',
            ];
    } else if (controller.isVehicleDoc) {
      options = controller.dynamicVehicleDocTypes.isNotEmpty
          ? controller.dynamicVehicleDocTypes.map((t) => t.name).toList()
          : [
              'RC Book (Registration Certificate)',
              'Insurance Policy',
              'PUC Certificate',
              'Fitness Certificate',
              'Road Tax Receipt',
              'Service & Maintenance Bill',
              'Purchase Invoice / Bill',
              'Fastag / Toll Pass',
              'Loan / Hypothecation NOC',
            ];
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
              .map(
                (sub) => DropdownMenuItem(
                  value: sub,
                  child: Text(sub, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) controller.selectedSubcategory.value = val;
          },
        ),
      ),
    );
  }

  /// Helper that renders 2 widgets side-by-side on Desktop/Tablet and stacked vertically on Mobile.
  Widget _buildResponsiveRow({
    required BuildContext context,
    required Widget first,
    required Widget second,
    int firstFlex = 1,
    int secondFlex = 1,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.tabletBreakpoint;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          first,
          const SizedBox(height: 12),
          second,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: firstFlex, child: first),
        const SizedBox(width: 12),
        Expanded(flex: secondFlex, child: second),
      ],
    );
  }

  Widget _buildUtilityMetadataSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.utilityAmberLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.utilityAmber.withValues(alpha: 0.3),
        ),
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
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Provider Name *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() {
                  final providers = controller.availableProvidersForSelectedType;
                  final currentVal = providers.contains(controller.selectedProviderName.value)
                      ? controller.selectedProviderName.value
                      : (providers.isNotEmpty ? providers.first : 'Other');
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
                        value: currentVal,
                        items: providers
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p, style: const TextStyle(fontSize: 13)),
                              ),
                            )
                            .toList(),
                        onChanged: controller.onUtilityProviderChanged,
                      ),
                    ),
                  );
                }),
                Obx(() {
                  if (controller.selectedProviderName.value != 'Other') {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      controller: controller.utilityProviderController,
                      decoration: const InputDecoration(
                        hintText: 'Enter custom provider name',
                      ),
                    ),
                  );
                }),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consumer Number / ID',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.consumerNumberController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 10293849',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill Amount (₹)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.billAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '3450'),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Container(
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
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending Payment'),
                          ),
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text('Paid'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            controller.utilityPaymentStatus.value = val;
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.billDate.value,
                        firstDate: DateTime(2010),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) controller.billDate.value = picked;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppFormatters.formatDate(controller.billDate.value),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Due Date (if applicable)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.dueDate.value ??
                            controller.billDate.value.add(const Duration(days: 15)),
                        firstDate: DateTime(2010),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) controller.dueDate.value = picked;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.dueDate.value != null
                                ? AppFormatters.formatDate(controller.dueDate.value!)
                                : 'Select Due Date',
                            style: TextStyle(
                              fontSize: 13,
                              color: controller.dueDate.value != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                          const Icon(
                            Icons.event,
                            size: 16,
                            color: AppColors.textMuted,
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
    );
  }

  Widget _buildApplianceMetadataSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warrantyEmeraldLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warrantyEmerald.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: AppColors.warrantyEmerald,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Invoice & Store Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shared Invoice Details Row 1
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Store / Vendor Name',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.storeVendorNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Vijay Sales, Croma, Amazon',
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Billing / Customer Name',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.billingNameController,
                  decoration: const InputDecoration(
                    hintText: 'King Technology / Mihir Shah',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Shared Invoice Details Row 2
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invoice / Bill Number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.invoiceNumberController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. INV-98124',
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Invoice Amount (₹)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.purchaseAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Optional total amount',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Shared Invoice Details Row 3 (Purchase Date)
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Purchase / Invoice Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.purchaseDate.value,
                        firstDate: DateTime(2010),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        controller.purchaseDate.value = picked;
                        for (var item in controller.applianceItems) {
                          item.updateWarranty(
                            item.warrantyMonths.value,
                            picked,
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppFormatters.formatDate(controller.purchaseDate.value),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            second: const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Multi-Product Repeater Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.devices_other_outlined,
                    color: AppColors.warrantyEmerald,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Products & Warranties on this Bill',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warrantyEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${controller.applianceItems.length} ${controller.applianceItems.length == 1 ? "Product" : "Products"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warrantyEmerald,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => controller.addApplianceItem(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Another Product'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warrantyEmerald,
                  side: const BorderSide(color: AppColors.warrantyEmerald),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of Product Items
          Obx(
            () => Column(
              children: List.generate(
                controller.applianceItems.length,
                (index) => _buildApplianceItemCard(
                  context,
                  index,
                  controller.applianceItems[index],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceItemCard(
    BuildContext context,
    int index,
    ApplianceItemFormState item,
  ) {
    final subcategories = controller.dynamicApplianceSubcategories.isNotEmpty
        ? controller.dynamicApplianceSubcategories
        : AppConstants.applianceSubcategories;

    final brands = controller.dynamicBrands.isNotEmpty
        ? [...controller.dynamicBrands, 'Other']
        : [...AppConstants.popularBrands, 'Other'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        AppColors.warrantyEmerald.withValues(alpha: 0.15),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warrantyEmerald,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Product ${index + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (controller.applianceItems.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  tooltip: 'Remove product from bill',
                  onPressed: () => controller.removeApplianceItem(index),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Item Category & Brand Row
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appliance Category *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: subcategories.contains(
                          item.selectedCategory.value,
                        )
                            ? item.selectedCategory.value
                            : (subcategories.isNotEmpty
                                ? subcategories.first
                                : null),
                        items: subcategories
                            .map(
                              (sub) => DropdownMenuItem(
                                value: sub,
                                child: Text(
                                  sub,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) item.selectedCategory.value = val;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Brand *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: brands.contains(item.selectedBrand.value)
                            ? item.selectedBrand.value
                            : (brands.isNotEmpty ? brands.first : 'Other'),
                        items: brands
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(
                                  b,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) item.selectedBrand.value = val;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom Brand textfield if Other
          Obx(() {
            if (item.selectedBrand.value != 'Other') {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: item.customBrandController,
                decoration: const InputDecoration(
                  labelText: 'Enter Custom Brand Name',
                  hintText: 'e.g. Dyson, Bosch, Morphy Richards',
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          // Product Name & Item Price Row
          _buildResponsiveRow(
            context: context,
            firstFlex: 3,
            secondFlex: 2,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Name / Model',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: item.productNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 260L Frost Free Refrigerator',
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price / Amount (₹)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: item.purchaseAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 24990',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Serial Number & Care Number Row
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Serial Number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: item.serialNumberController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. SN-982410',
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Model Number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: item.modelNumberController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. GL-T292RPZY',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Warranty Duration & Status Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(
                      () => Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 16,
                            color: item.hasWarrantyCoverage.value
                                ? AppColors.warrantyEmerald
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.hasWarrantyCoverage.value
                                ? 'Warranty Coverage Active'
                                : 'No Warranty (Invoice Only)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: item.hasWarrantyCoverage.value
                                  ? AppColors.warrantyEmerald
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                      () => Switch(
                        value: item.hasWarrantyCoverage.value,
                        activeColor: AppColors.warrantyEmerald,
                        onChanged: (val) => controller
                            .toggleItemWarrantyCoverage(index, val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildResponsiveRow(
                  context: context,
                  first: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Warranty Period',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: item.warrantyMonths.value,
                              items: const [
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text(
                                    'No Warranty (Invoice Only)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 6,
                                  child: Text(
                                    '6 Months',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 12,
                                  child: Text(
                                    '1 Year (12 Months)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 24,
                                  child: Text(
                                    '2 Years (24 Months)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 36,
                                  child: Text(
                                    '3 Years (36 Months)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text(
                                    '5 Years (60 Months)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 120,
                                  child: Text(
                                    '10 Years (Motor / Compressor)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  controller.updateItemWarrantyMonths(
                                    index,
                                    val,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  second: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expiry Date Preview',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            item.hasWarrantyCoverage.value &&
                                    item.warrantyMonths.value > 0
                                ? AppFormatters.formatDate(
                                    item.warrantyValidUpto.value,
                                  )
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.hasWarrantyCoverage.value &&
                                      item.warrantyMonths.value > 0
                                  ? AppColors.warrantyEmerald
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Person / Family Member *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() {
                  final pNames = controller.dynamicPersons
                      .map((p) => p.fullName)
                      .toList();
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
                        value: pNames.contains(
                          controller.selectedPersonName.value,
                        )
                            ? controller.selectedPersonName.value
                            : pNames.first,
                        items: pNames.map((name) {
                          final person = controller.dynamicPersons
                              .firstWhereOrNull((p) => p.fullName == name);
                          final rel = person?.relationship != null
                              ? ' (${person!.relationship})'
                              : '';
                          return DropdownMenuItem(
                            value: name,
                            child: Text('$name$rel'),
                          );
                        }).toList(),
                        onChanged: controller.onPersonChanged,
                      ),
                    ),
                  );
                }),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Document Type *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() {
                  final types = controller.dynamicPersonalDocTypes
                      .map((t) => t.name)
                      .toList();
                  if (types.isEmpty) {
                    types.addAll([
                      'Aadhaar Card',
                      'PAN Card',
                      'Passport',
                      'Driving License',
                    ]);
                  }

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
                        value: types.contains(
                          controller.selectedPersonalDocTypeName.value,
                        )
                            ? controller.selectedPersonalDocTypeName.value
                            : types.first,
                        items: types
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: controller.onPersonalDocTypeChanged,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ID / Document / Card Number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.personalIdNumberController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 1234-5678-9012 or ABCDE1234F',
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Issuing Authority',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.personalIssuingAuthorityController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. UIDAI, Income Tax Dept, ECI',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Issue Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.personalIssueDate.value ??
                            DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime(2050),
                      );
                      if (picked != null)
                        controller.personalIssueDate.value = picked;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
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
                                ? AppFormatters.formatDate(
                                    controller.personalIssueDate.value!,
                                  )
                                : 'Select Issue Date',
                            style: TextStyle(
                              color: controller.personalIssueDate.value != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expiry Date (if applicable)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.personalExpiryDate.value ??
                            DateTime.now().add(const Duration(days: 3650)),
                        firstDate: DateTime(1950),
                        lastDate: DateTime(2060),
                      );
                      if (picked != null)
                        controller.personalExpiryDate.value = picked;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
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
                                ? AppFormatters.formatDate(
                                    controller.personalExpiryDate.value!,
                                  )
                                : 'Select Expiry Date',
                            style: TextStyle(
                              color: controller.personalExpiryDate.value != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const Icon(
                            Icons.event_busy,
                            size: 16,
                            color: AppColors.textMuted,
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
    );
  }

  Widget _buildVehicleMetadataSection(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_car_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Vehicle Document Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => controller.openAddVehicleDialog(),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Vehicle', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Vehicle *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Obx(() {
                  final vList = controller.dynamicVehicles;
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
                        value: vList.any((v) => v.vehicleNumber == controller.selectedVehicleNumber.value)
                            ? controller.selectedVehicleNumber.value
                            : (vList.isNotEmpty ? vList.first.vehicleNumber : null),
                        items: vList.map((v) {
                          return DropdownMenuItem(
                            value: v.vehicleNumber,
                            child: Text(v.displayName, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final veh = vList.firstWhereOrNull((v) => v.vehicleNumber == val);
                            if (veh != null) controller.updateSelectedVehicle(veh);
                          }
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle Document Type *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Obx(() {
                  final types = controller.dynamicVehicleDocTypes.map((t) => t.name).toList();
                  if (types.isEmpty) {
                    types.addAll([
                      'RC Book (Registration Certificate)',
                      'Insurance Policy',
                      'PUC Certificate',
                      'Fitness Certificate',
                      'Service & Maintenance Bill',
                    ]);
                  }
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
                        value: types.contains(controller.selectedVehicleDocTypeName.value)
                            ? controller.selectedVehicleDocTypeName.value
                            : types.first,
                        items: types.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) controller.updateSelectedVehicleDocType(val);
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Dynamic Pass & FASTag Section
          Obx(() {
            if (!controller.isVehiclePassDoc) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.toll_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Annual Pass & FASTag Configuration',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildResponsiveRow(
                    context: context,
                    first: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pass Type *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          final passTypes = AppConstants.vehiclePassTypes;
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
                                value: passTypes.contains(controller.selectedVehiclePassType.value)
                                    ? controller.selectedVehiclePassType.value
                                    : passTypes.first,
                                items: passTypes.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(p, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) controller.selectedVehiclePassType.value = val;
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    second: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toll Plaza / Location / Society Name',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: controller.vehiclePassPlazaController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Kherki Daula Plaza or Sea Link or Tower B',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FASTag Barcode / RFID Tag ID (Optional)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: controller.vehicleFastagIdController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 34161FA82032890... (from FASTag card or sticker)',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.isVehiclePassDoc
                      ? 'Pass / Receipt / Permit Number'
                      : 'Policy / Certificate / Reg Number',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                )),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.vehiclePolicyOrCertNumberController,
                  decoration: InputDecoration(
                    hintText: controller.isVehiclePassDoc
                        ? 'e.g. Pass receipt # or tag ID'
                        : 'e.g. Policy # or PUC # or Reg #',
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.isVehiclePassDoc
                      ? 'Issuing Bank / Tag Issuer / Authority'
                      : 'Insurance Company / Agency Name',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                )),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.vehicleInsuranceCompanyController,
                  decoration: InputDecoration(
                    hintText: controller.isVehiclePassDoc
                        ? 'e.g. ICICI Bank, IDFC, Paytm, NHAI, Society Office'
                        : 'e.g. HDFC ERGO, ICICI Lombard, New India',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.isVehiclePassDoc ? 'Pass Valid From' : 'Issue / Start Date',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                )),
                const SizedBox(height: 4),
                Obx(
                  () => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.vehicleIssueDate.value ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        controller.vehicleIssueDate.value = picked;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.vehicleIssueDate.value != null
                                ? AppFormatters.formatDate(controller.vehicleIssueDate.value!)
                                : 'Select Start Date',
                            style: TextStyle(
                              color: controller.vehicleIssueDate.value != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.isVehiclePassDoc
                      ? 'Pass Expiry Date (Annual/Monthly Renewal)'
                      : 'Expiry / Renewal Date (For Insurance/PUC/Fitness)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                )),
                const SizedBox(height: 4),
                Obx(
                  () => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.vehicleExpiryDate.value ??
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 15)),
                      );
                      if (picked != null) {
                        controller.vehicleExpiryDate.value = picked;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.vehicleExpiryDate.value != null
                                ? AppFormatters.formatDate(controller.vehicleExpiryDate.value!)
                                : 'Select Expiry Date',
                            style: TextStyle(
                              color: controller.vehicleExpiryDate.value != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const Icon(Icons.event_busy, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildResponsiveRow(
            context: context,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.isVehiclePassDoc ? 'Pass Fee / Amount (₹)' : 'Premium / Bill Amount (₹)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                )),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.vehiclePremiumAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 3500',
                    prefixText: '₹ ',
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Center / Vendor Name',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.vehicleServiceCenterController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Concept Hyundai / Cargo Honda',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notes & Remarks (Optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller.vehicleNotesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Comprehensive zero-dep policy with RSA included',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
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
              Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 20,
              ),
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
          _buildResponsiveRow(
            context: context,
            firstFlex: 2,
            secondFlex: 3,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'City *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Container(
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
                        items:
                            (controller.dynamicCities.isNotEmpty
                                    ? controller.dynamicCities
                                    : AppConstants.supportedCities
                                          .where((c) => c != 'All Cities')
                                          .toList())
                                .map(
                                  (city) => DropdownMenuItem(
                                    value: city,
                                    child: Text(city),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null)
                            controller.selectedCity.value = val;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Area / Locality / Premises',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller.areaLocalityController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. SG Highway, Bodakdev, Corporate HQ',
                  ),
                ),
              ],
            ),
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
      final errorMsg = controller.compressionError.value;
      final hasSafeCompression = result?.hasSizeReduction == true;
      final isPdf = FileCompressor.isPdf(file.name);
      final isCompressedSelected = controller.useCompressed.value;

      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompressedSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompressedSelected
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
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
                    color: isCompressedSelected
                        ? AppColors.primarySurface
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.compress,
                    color: isCompressedSelected
                        ? (isPdf ? AppColors.error : AppColors.primary)
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            'Upload Version & Compression',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPdf
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPdf ? 'PDF' : 'IMAGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isPdf
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  size: 11,
                                  color: AppColors.secondary,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'API Engine',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Select whether to optimize size with cloud engine or upload raw file',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompressedSelected && result != null && !isCompressing)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasSafeCompression
                          ? AppColors.successLight
                          : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            (hasSafeCompression
                                    ? AppColors.success
                                    : AppColors.info)
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      hasSafeCompression
                          ? '🔥 ${result.savingsFormatted} Saved'
                          : 'Optimal Size',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: hasSafeCompression
                            ? AppColors.successDark
                            : AppColors.info,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Upload Target Radios (Primary Selection)
            const Text(
              'Choose Upload Version:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Option 1 (Default): Upload Original Quality
            InkWell(
              onTap: () => controller.setUploadCompressionMode(false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: !isCompressedSelected
                      ? AppColors.primarySurface
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: !isCompressedSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: !isCompressedSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: controller.useCompressed.value,
                      onChanged: (val) =>
                          controller.setUploadCompressionMode(val ?? false),
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
                                'Upload Original Quality',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Full original file (${CompressionResult.formatFileSize(file.size)}) without compression.',
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
              ),
            ),

            const SizedBox(height: 8),

            // Option 2: Upload Compressed File
            InkWell(
              onTap: () => controller.setUploadCompressionMode(true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCompressedSelected
                      ? AppColors.primarySurface
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCompressedSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: isCompressedSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: controller.useCompressed.value,
                      onChanged: (val) =>
                          controller.setUploadCompressionMode(val ?? true),
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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'API Optimized',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result != null
                                ? 'Optimized size (${result.compressedSizeFormatted}). Saves cloud storage & loads faster.'
                                : 'Compresses via King Technology Media Engine API before saving to vault.',
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
              ),
            ),

            // ONLY DISPLAY OPTIMIZATION OPTIONS WHEN COMPRESSED IS SELECTED
            if (isCompressedSelected) ...[
              const SizedBox(height: 18),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 14),

              // Optimization Section Header with Re-compress Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_fix_high_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Optimization Settings',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: isCompressing
                        ? null
                        : () => controller.recompressFile(),
                    icon: isCompressing
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 14),
                    label: Text(
                      isCompressing ? 'Compressing...' : 'Re-compress File',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      backgroundColor: AppColors.primarySurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Inline Error Card (Rule: Error messages rendered inline in active modals/forms)
              if (errorMsg.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppColors.warningDark,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'API Notice: $errorMsg',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warningDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: isCompressing
                            ? null
                            : () => controller.compressSelectedFile(),
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Retry API', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Prominent Progressive Loader banner shown while compression API is executing
              if (isCompressing)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isPdf
                                  ? 'Optimizing PDF with ${controller.pdfCompressionLevel.value.toUpperCase()} level...'
                                  : 'Optimizing image with ${controller.compressionQuality.value}% quality...',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
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
                            : 'Processing binary streams on King Technology Media Engine...',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                        child: LinearProgressIndicator(
                          value: controller.compressionProgress.value.clamp(
                            0.05,
                            1.0,
                          ),
                          minHeight: 6,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Quality Control & Re-generate Panel (Only Quality Required)
              if (!isCompressing) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.isQualityDirty
                          ? AppColors.secondary.withValues(alpha: 0.5)
                          : AppColors.border,
                      width: controller.isQualityDirty ? 1.5 : 1,
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
                                isPdf
                                    ? Icons.picture_as_pdf_outlined
                                    : Icons.photo_size_select_large_outlined,
                                size: 16,
                                color: isPdf ? AppColors.error : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Compression Quality',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${controller.compressionQuality.value}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: controller.compressionQuality.value.toDouble(),
                          min: 10,
                          max: 100,
                          divisions: 18,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.border,
                          onChanged: (val) {
                            controller.setCompressionQuality(val.round());
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Quick Preset Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQualityChip(
                            40,
                            '40% (Extreme)',
                            controller.compressionQuality.value == 40,
                            () => controller.setCompressionQuality(40),
                          ),
                          _buildQualityChip(
                            60,
                            '60% (High)',
                            controller.compressionQuality.value == 60,
                            () => controller.setCompressionQuality(60),
                          ),
                          _buildQualityChip(
                            75,
                            '75% (Recommended)',
                            controller.compressionQuality.value == 75,
                            () => controller.setCompressionQuality(75),
                          ),
                          _buildQualityChip(
                            90,
                            '90% (Light)',
                            controller.compressionQuality.value == 90,
                            () => controller.setCompressionQuality(90),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),
                      // Prominent Re-generate Button
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isCompressing
                                  ? null
                                  : () => controller.recompressFile(),
                              icon: isCompressing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(
                                isCompressing
                                    ? 'Compressing...'
                                    : '⚡ Re-generate with ${controller.compressionQuality.value}% Quality',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: controller.isQualityDirty
                                    ? AppColors.secondary
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (controller.isQualityDirty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Quality adjusted to ${controller.compressionQuality.value}%. Tap "Re-generate" to update file compression.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Comparison Banner (Before vs After)
              if (result != null || isCompressing) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Original (Before)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  result?.originalSizeFormatted ??
                                      CompressionResult.formatFileSize(file.size),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  hasSafeCompression
                                      ? 'Compressed (After)'
                                      : 'Original (Retained)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: hasSafeCompression
                                        ? AppColors.successDark
                                        : AppColors.info,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (isCompressing)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: hasSafeCompression
                                          ? AppColors.success
                                          : AppColors.info,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (result != null && !isCompressing) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (result.pageCount != null && result.pageCount! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${result.pageCount} Pages',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (hasSafeCompression)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🔥 Saved ${CompressionResult.formatFileSize(result.totalSavedBytes)} (${result.savingsPercent.toStringAsFixed(1)}%)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.successDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // View Compressed Document Button
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (isPdf) {
                                    PdfViewerDialog.showBytes(
                                      title: 'Preview Compressed PDF: ${file.name}',
                                      bytes: result.compressedBytes,
                                      fileName: result.compressedFileName,
                                    );
                                  } else {
                                    ImageLightboxDialog.show(
                                      title: 'Preview Compressed Image: ${file.name}',
                                      imageBytes: result.compressedBytes,
                                      fileName: result.compressedFileName,
                                    );
                                  }
                                },
                                icon: Icon(
                                  isPdf
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.visibility_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  isPdf
                                      ? '👁️ View Compressed PDF'
                                      : '👁️ View Compressed Image',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            if (file.bytes != null) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  if (isPdf) {
                                    PdfViewerDialog.showBytes(
                                      title: 'Original PDF: ${file.name}',
                                      bytes: file.bytes!,
                                      fileName: file.name,
                                    );
                                  } else {
                                    ImageLightboxDialog.show(
                                      title: 'Original Image: ${file.name}',
                                      imageBytes: file.bytes!,
                                      fileName: file.name,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.compare_arrows_rounded,
                                  size: 14,
                                ),
                                label: const Text(
                                  'View Original',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                if (result != null && !hasSafeCompression && !isCompressing) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: AppColors.info,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'File is already optimized. The original file will be uploaded unchanged.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.info,
                            ),
                          ),
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
    });
  }

  Widget _buildQualityChip(
    int quality,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
