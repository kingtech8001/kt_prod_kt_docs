import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';

class AddVehicleServiceDialog extends StatelessWidget {
  final List<MasterVehicleModel> vehicles;
  final MasterVehicleModel? initialVehicle;
  final VehicleServiceModel? serviceToEdit;
  final Future<void> Function(VehicleServiceModel service) onSave;

  const AddVehicleServiceDialog({
    super.key,
    required this.vehicles,
    this.initialVehicle,
    this.serviceToEdit,
    required this.onSave,
  });

  static Future<bool?> show({
    required List<MasterVehicleModel> vehicles,
    MasterVehicleModel? initialVehicle,
    VehicleServiceModel? serviceToEdit,
    required Future<void> Function(VehicleServiceModel service) onSave,
  }) {
    return AppDialog.show<bool>(
      AddVehicleServiceDialog(
        vehicles: vehicles,
        initialVehicle: initialVehicle,
        serviceToEdit: serviceToEdit,
        onSave: onSave,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = serviceToEdit != null;

    final selectedVehicleId = (serviceToEdit?.vehicleId ??
            initialVehicle?.id ??
            (vehicles.isNotEmpty ? vehicles.first.id : ''))
        .obs;

    final selectedDate = Rx<DateTime>(serviceToEdit?.serviceDate ?? DateTime.now());
    final selectedNextDate = Rx<DateTime?>(serviceToEdit?.nextServiceDate);

    final odometerController = TextEditingController(
      text: serviceToEdit != null && serviceToEdit!.odometerKm > 0
          ? serviceToEdit!.odometerKm.toString()
          : '',
    );
    final nextKmController = TextEditingController(
      text: serviceToEdit != null && serviceToEdit!.nextServiceKm != null
          ? serviceToEdit!.nextServiceKm.toString()
          : '',
    );
    final serviceCenterController = TextEditingController(
      text: serviceToEdit?.serviceCenterName ?? '',
    );
    final billNumberController = TextEditingController(
      text: serviceToEdit?.billNumber ?? '',
    );
    final costController = TextEditingController(
      text: serviceToEdit != null && serviceToEdit!.costAmount > 0
          ? serviceToEdit!.costAmount.toStringAsFixed(0)
          : '',
    );
    final notesController = TextEditingController(
      text: serviceToEdit?.notes ?? '',
    );
    final customTypeController = TextEditingController();

    // Selected service types
    final selectedTypes = RxList<String>(
      serviceToEdit?.serviceTypes ?? ['Engine Oil Change', 'Oil Filter Replacement'],
    );

    final isSubmitting = false.obs;
    final errorMessage = ''.obs;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.build_circle_rounded,
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
                          isEditing
                              ? 'Edit Service Record'
                              : 'Log Vehicle Service & Maintenance',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Track oil change, KM readings, garage bills, and upcoming service due',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(result: false),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 18),

              // Scrollable Form Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inline Error Banner
                      Obx(() {
                        if (errorMessage.value.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
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
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Row 1: Vehicle Selector & Service Date (Responsive 2-col or stacked)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 480;
                          return Flex(
                            direction: isNarrow ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: isNarrow ? 0 : 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Select Vehicle *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Obx(
                                      () => DropdownButtonFormField<String>(
                                        initialValue: selectedVehicleId.value.isNotEmpty
                                            ? selectedVehicleId.value
                                            : null,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.directions_car, size: 20),
                                          filled: true,
                                          fillColor: AppColors.surfaceVariant,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: AppColors.border),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        items: vehicles.map((v) {
                                          final label = v.nickname != null && v.nickname!.isNotEmpty
                                              ? '${v.vehicleNumber} (${v.nickname})'
                                              : v.vehicleNumber;
                                          return DropdownMenuItem<String>(
                                            value: v.id,
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) selectedVehicleId.value = val;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isNarrow) const SizedBox(width: 14),
                              if (isNarrow) const SizedBox(height: 14),
                              Expanded(
                                flex: isNarrow ? 0 : 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Service Date *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Obx(
                                      () => InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDate.value,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime.now().add(const Duration(days: 30)),
                                          );
                                          if (picked != null) selectedDate.value = picked;
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 16,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppFormatters.formatDate(selectedDate.value),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
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
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Row 2: Current Odometer (KM) & Service Cost
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 480;
                          return Flex(
                            direction: isNarrow ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: isNarrow ? 0 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Odometer Reading (KM) *',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: odometerController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        hintText: 'e.g. 45200',
                                        prefixIcon: const Icon(Icons.speed_rounded, size: 20),
                                        suffixText: 'KM',
                                        filled: true,
                                        fillColor: AppColors.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isNarrow) const SizedBox(width: 14),
                              if (isNarrow) const SizedBox(height: 14),
                              Expanded(
                                flex: isNarrow ? 0 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Cost / Bill Amount (₹)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: costController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: 'e.g. 4850',
                                        prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                                        filled: true,
                                        fillColor: AppColors.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Service Types Selector (Interactive Chips)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Services Performed *',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Obx(
                                () => Text(
                                  '${selectedTypes.length} selected',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: AppConstants.vehicleServiceTypes.map((type) {
                                final isSelected = selectedTypes.contains(type);
                                return FilterChip(
                                  label: Text(type),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                                  backgroundColor: AppColors.surfaceVariant,
                                  checkmarkColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                    ),
                                  ),
                                  onSelected: (checked) {
                                    if (checked) {
                                      selectedTypes.add(type);
                                    } else {
                                      selectedTypes.remove(type);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Add Custom Service item
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: customTypeController,
                                  decoration: InputDecoration(
                                    hintText: 'Add custom work done (e.g. Dent repair)...',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  final val = customTypeController.text.trim();
                                  if (val.isNotEmpty && !selectedTypes.contains(val)) {
                                    selectedTypes.add(val);
                                    customTypeController.clear();
                                  }
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Next Service Due Intelligence Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.alarm_add_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Next Service Due Reminder (Recommended)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Next Service KM with quick suggestion buttons
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 480;
                                return Flex(
                                  direction: isNarrow ? Axis.vertical : Axis.horizontal,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: isNarrow ? 0 : 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Next Service KM',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: nextKmController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                            ],
                                            decoration: InputDecoration(
                                              hintText: 'e.g. 55000',
                                              prefixIcon: const Icon(Icons.speed, size: 18),
                                              suffixText: 'KM',
                                              filled: true,
                                              fillColor: AppColors.surface,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppColors.border,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            children: [
                                              ActionChip(
                                                label: const Text('+5,000 KM'),
                                                labelStyle: const TextStyle(fontSize: 11),
                                                onPressed: () {
                                                  final curr = int.tryParse(odometerController.text.trim()) ?? 0;
                                                  if (curr > 0) {
                                                    nextKmController.text = (curr + 5000).toString();
                                                  }
                                                },
                                              ),
                                              ActionChip(
                                                label: const Text('+10,000 KM'),
                                                labelStyle: const TextStyle(fontSize: 11),
                                                onPressed: () {
                                                  final curr = int.tryParse(odometerController.text.trim()) ?? 0;
                                                  if (curr > 0) {
                                                    nextKmController.text = (curr + 10000).toString();
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isNarrow) const SizedBox(width: 14),
                                    if (isNarrow) const SizedBox(height: 14),

                                    // Next Service Date with quick suggestion buttons
                                    Expanded(
                                      flex: isNarrow ? 0 : 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Next Service Date',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Obx(
                                            () => InkWell(
                                              onTap: () async {
                                                final now = DateTime.now();
                                                final picked = await showDatePicker(
                                                  context: context,
                                                  initialDate: selectedNextDate.value ??
                                                      now.add(const Duration(days: 180)),
                                                  firstDate: now,
                                                  lastDate: now.add(const Duration(days: 365 * 5)),
                                                );
                                                if (picked != null) {
                                                  selectedNextDate.value = picked;
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: AppColors.border),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.event_available,
                                                      size: 16,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        selectedNextDate.value != null
                                                            ? AppFormatters.formatDate(
                                                                selectedNextDate.value!)
                                                            : 'Select Due Date',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: selectedNextDate.value != null
                                                              ? AppColors.textPrimary
                                                              : AppColors.textTertiary,
                                                        ),
                                                      ),
                                                    ),
                                                    if (selectedNextDate.value != null)
                                                      InkWell(
                                                        onTap: () => selectedNextDate.value = null,
                                                        child: const Icon(
                                                          Icons.clear,
                                                          size: 16,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            children: [
                                              ActionChip(
                                                label: const Text('+6 Months'),
                                                labelStyle: const TextStyle(fontSize: 11),
                                                onPressed: () {
                                                  final base = selectedDate.value;
                                                  selectedNextDate.value = DateTime(
                                                    base.year,
                                                    base.month + 6,
                                                    base.day,
                                                  );
                                                },
                                              ),
                                              ActionChip(
                                                label: const Text('+1 Year'),
                                                labelStyle: const TextStyle(fontSize: 11),
                                                onPressed: () {
                                                  final base = selectedDate.value;
                                                  selectedNextDate.value = DateTime(
                                                    base.year + 1,
                                                    base.month,
                                                    base.day,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Service Center / Garage & Bill / Invoice Number
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 480;
                          return Flex(
                            direction: isNarrow ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: isNarrow ? 0 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Service Center / Garage Name',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: serviceCenterController,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Hyundai Authorized Service',
                                        filled: true,
                                        fillColor: AppColors.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isNarrow) const SizedBox(width: 14),
                              if (isNarrow) const SizedBox(height: 14),
                              Expanded(
                                flex: isNarrow ? 0 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bill / Invoice Number (Optional)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: billNumberController,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. INV-2026-894',
                                        filled: true,
                                        fillColor: AppColors.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes & Remarks
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remarks / Work Done Notes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'e.g. 5W-30 synthetic oil used, front brake pads replaced...',
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton(
                      onPressed: isSubmitting.value
                          ? null
                          : () async {
                              final vehId = selectedVehicleId.value;
                              if (vehId.isEmpty) {
                                errorMessage.value = 'Please select a vehicle.';
                                return;
                              }

                              final odoStr = odometerController.text.trim();
                              final odo = int.tryParse(odoStr);
                              if (odo == null || odo <= 0) {
                                errorMessage.value =
                                    'Please enter a valid odometer reading (KM).';
                                return;
                              }

                              if (selectedTypes.isEmpty) {
                                errorMessage.value =
                                    'Please select at least one service performed (e.g. Engine Oil Change).';
                                return;
                              }

                              final cost = double.tryParse(costController.text.trim()) ?? 0.0;
                              final nextKm = int.tryParse(nextKmController.text.trim());

                              isSubmitting.value = true;
                              errorMessage.value = '';

                              try {
                                final service = VehicleServiceModel(
                                  id: serviceToEdit?.id ?? '',
                                  vehicleId: vehId,
                                  serviceDate: selectedDate.value,
                                  odometerKm: odo,
                                  serviceTypes: selectedTypes.toList(),
                                  serviceCenterName: serviceCenterController.text.trim().isNotEmpty
                                      ? serviceCenterController.text.trim()
                                      : null,
                                  billNumber: billNumberController.text.trim().isNotEmpty
                                      ? billNumberController.text.trim()
                                      : null,
                                  costAmount: cost,
                                  nextServiceDate: selectedNextDate.value,
                                  nextServiceKm: nextKm,
                                  notes: notesController.text.trim().isNotEmpty
                                      ? notesController.text.trim()
                                      : null,
                                  createdAt: serviceToEdit?.createdAt ?? DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );

                                await onSave(service);
                                Get.back(result: true);
                              } catch (e) {
                                errorMessage.value = 'Failed to save service record: $e';
                              } finally {
                                isSubmitting.value = false;
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: isSubmitting.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Save Service Log'),
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
