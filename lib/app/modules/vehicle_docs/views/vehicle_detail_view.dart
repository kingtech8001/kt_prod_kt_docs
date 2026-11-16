import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/modules/vehicle_docs/controllers/vehicle_detail_controller.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/status_badge.dart';
import 'package:kt_prod_kt_docs/app/widgets/web_scaffold.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class VehicleDetailView extends GetView<VehicleDetailController> {
  const VehicleDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      title: 'Vehicle Details',
      currentRoute: AppRoutes.VEHICLE_DOCS,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final vehicle = controller.vehicle.value;
        if (vehicle == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.car_crash_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text(
                  'Vehicle Not Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Vehicle Vault'),
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
                    _buildHeader(context, vehicle),
                    const SizedBox(height: AppConstants.paddingLarge),
                    _buildVehicleDetailsCard(context, vehicle),
                    const SizedBox(height: AppConstants.paddingLarge),
                    _buildHistorySection(context, vehicle),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, MasterVehicleModel vehicle) {
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
          // Back Button & Breadcrumb
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Get.back(),
                tooltip: 'Back to Vehicle Vault',
              ),
              const SizedBox(width: 8),
              const Text(
                'Vehicle Vault',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(' / ', style: TextStyle(color: AppColors.textMuted)),
              Text(
                vehicle.vehicleNumber,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          vehicle.displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusSmall),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            vehicle.vehicleType,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.brandMake ?? ""} ${vehicle.modelName ?? ""} • Fuel: ${vehicle.fuelType ?? "Petrol"}'
                      '${vehicle.ownerName != null ? " • Owner: ${vehicle.ownerName}" : ""}',
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
                    icon: const Icon(Icons.build_outlined, size: 16),
                    label: const Text('Log Service'),
                    onPressed: controller.openAddServiceDialog,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsCard(BuildContext context, MasterVehicleModel vehicle) {
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
                    'Vehicle Specifications & Identity (Editable)',
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
                      controller.isSaving.value ? 'Saving...' : 'Save Vehicle Details',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.saveVehicleDetails,
                  )),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Form Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoCol = constraints.maxWidth > 700;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildFormField(
                    label: 'Registration / Plate Number *',
                    controller: controller.vehicleNumberController,
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    icon: Icons.pin_outlined,
                  ),
                  _buildFormField(
                    label: 'Vehicle Nickname / Alias',
                    controller: controller.nicknameController,
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    icon: Icons.label_outline,
                  ),
                  _buildFormField(
                    label: 'Brand / Make (e.g. Honda, Hyundai, Tata)',
                    controller: controller.brandMakeController,
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    icon: Icons.branding_watermark_outlined,
                  ),
                  _buildFormField(
                    label: 'Model Name (e.g. SP 125, Creta, City)',
                    controller: controller.modelNameController,
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    icon: Icons.two_wheeler_outlined,
                  ),
                  _buildDropdownField(
                    label: 'Vehicle Type',
                    value: controller.selectedVehicleType.value,
                    items: const [
                      'Two Wheeler',
                      'Four Wheeler',
                      'Commercial',
                      'Electric Vehicle',
                      'Other'
                    ],
                    onChanged: (val) {
                      if (val != null) controller.selectedVehicleType.value = val;
                    },
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                  ),
                  _buildDropdownField(
                    label: 'Fuel Type',
                    value: controller.selectedFuelType.value,
                    items: const ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'],
                    onChanged: (val) {
                      if (val != null) controller.selectedFuelType.value = val;
                    },
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                  ),
                  _buildFormField(
                    label: 'Registered Owner Name',
                    controller: controller.ownerNameController,
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    icon: Icons.person_outline,
                  ),
                  _buildFormField(
                    label: 'Chassis Number (VIN)',
                    controller: controller.chassisNumberController,
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    icon: Icons.tag,
                  ),
                  _buildFormField(
                    label: 'Engine Number',
                    controller: controller.engineNumberController,
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    icon: Icons.engineering_outlined,
                  ),
                  _buildDatePickerField(
                    context: context,
                    label: 'Registration / Purchase Date',
                    date: controller.registrationDate.value,
                    width: isTwoCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    onSelected: (dt) => controller.registrationDate.value = dt,
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required double width,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : items.first,
                isExpanded: true,
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
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

  Widget _buildHistorySection(BuildContext context, MasterVehicleModel vehicle) {
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
          // Section Tabs: Documents & Policies vs Service & Maintenance
          Obx(() => Row(
                children: [
                  _buildTabButton(
                    title: 'Documents & Policies (${controller.documents.length})',
                    icon: Icons.description_outlined,
                    isSelected: controller.selectedHistoryTab.value == 0,
                    onTap: () => controller.selectedHistoryTab.value = 0,
                  ),
                  const SizedBox(width: 12),
                  _buildTabButton(
                    title: 'Service & Maintenance (${controller.services.length})',
                    icon: Icons.build_circle_outlined,
                    isSelected: controller.selectedHistoryTab.value == 1,
                    onTap: () => controller.selectedHistoryTab.value = 1,
                  ),
                ],
              )),
          const SizedBox(height: AppConstants.paddingMedium),
          const Divider(),
          const SizedBox(height: AppConstants.paddingMedium),

          Obx(() {
            if (controller.selectedHistoryTab.value == 0) {
              return _buildDocumentsTab(context);
            } else {
              return _buildServicesTab(context);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab(BuildContext context) {
    final docs = controller.filteredDocuments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-filters
        Row(
          children: [
            const Text(
              'Filter Doc Type: ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            for (final f in ['All', 'Insurance', 'PUC', 'RC & Registration'])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Obx(() {
                  final isSel = controller.selectedDocSubFilter.value == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) controller.selectedDocSubFilter.value = f;
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.primary : AppColors.textSecondary,
                    ),
                  );
                }),
              ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),

        if (docs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.folder_open_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No documents found for this filter.',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _buildDocumentRow(context, doc);
            },
          ),
      ],
    );
  }

  Widget _buildDocumentRow(BuildContext context, DocumentModel doc) {
    final meta = doc.vehicleMetadata;
    final isExpired = meta?.isExpired ?? false;
    final isExpiringSoon = meta?.isExpiringSoon ?? false;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(
          color: isExpired
              ? AppColors.error.withValues(alpha: 0.4)
              : (isExpiringSoon
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : AppColors.border),
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
              doc.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file_outlined,
              color: doc.isPdf ? AppColors.error : AppColors.primary,
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
                        doc.title,
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
                    if (meta?.renewalCount != null && meta!.renewalCount > 0)
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
                  '${meta?.docTypeName ?? doc.subCategory}'
                  '${meta?.policyOrCertNumber != null && meta!.policyOrCertNumber!.isNotEmpty ? " • Policy #: ${meta.policyOrCertNumber}" : ""}'
                  '${meta?.expiryDate != null ? " • Expires: ${AppFormatters.formatDate(meta!.expiryDate)}" : ""}',
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
                onPressed: () => controller.previewDocument(doc),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 19),
                tooltip: 'Download Document',
                onPressed: () => controller.downloadDocument(doc),
              ),
              if (meta != null &&
                  (meta.docTypeName.toLowerCase().contains('insurance') ||
                      meta.docTypeName.toLowerCase().contains('puc')))
                IconButton(
                  icon: const Icon(Icons.autorenew_rounded, size: 20, color: AppColors.primary),
                  tooltip: 'Renew Document',
                  onPressed: () => controller.openRenewDialog(doc),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab(BuildContext context) {
    final services = controller.services;

    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.build_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'No service & maintenance records logged yet.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: controller.openAddServiceDialog,
                icon: const Icon(Icons.add),
                label: const Text('Log First Service'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = services[index];
        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            border: Border.all(color: AppColors.border),
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
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: AppColors.primary,
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
                        Text(
                          'Service Date: ${AppFormatters.formatDate(s.serviceDate)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (s.serviceCenterName != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${s.serviceCenterName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cost: ${AppFormatters.formatCurrency(s.costAmount)}'
                      ' • Odometer: ${s.odometerKm} km'
                      '${s.nextServiceDate != null ? " • Next Due: ${AppFormatters.formatDate(s.nextServiceDate!)}" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Service Record',
                onPressed: () => controller.openEditServiceDialog(s),
              ),
            ],
          ),
        );
      },
    );
  }
}
