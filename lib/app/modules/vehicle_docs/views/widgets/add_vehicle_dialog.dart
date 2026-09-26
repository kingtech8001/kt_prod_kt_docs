import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class AddVehicleDialog extends StatelessWidget {
  final MasterVehicleModel? vehicleToEdit;
  final Future<void> Function(MasterVehicleModel vehicle) onSave;

  const AddVehicleDialog({
    super.key,
    this.vehicleToEdit,
    required this.onSave,
  });

  static Future<void> show({
    MasterVehicleModel? vehicleToEdit,
    required Future<void> Function(MasterVehicleModel vehicle) onSave,
  }) {
    return Get.dialog<void>(
      AddVehicleDialog(
        vehicleToEdit: vehicleToEdit,
        onSave: onSave,
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = vehicleToEdit != null;

    final regNumberController = TextEditingController(
      text: vehicleToEdit?.vehicleNumber ?? '',
    );
    final nicknameController = TextEditingController(
      text: vehicleToEdit?.nickname ?? '',
    );
    final brandController = TextEditingController(
      text: vehicleToEdit?.brandMake ?? '',
    );
    final modelController = TextEditingController(
      text: vehicleToEdit?.modelName ?? '',
    );
    final ownerController = TextEditingController(
      text: vehicleToEdit?.ownerName ?? '',
    );
    final chassisController = TextEditingController(
      text: vehicleToEdit?.chassisNumber ?? '',
    );
    final engineController = TextEditingController(
      text: vehicleToEdit?.engineNumber ?? '',
    );

    final selectedType = (vehicleToEdit?.vehicleType ?? 'Four Wheeler').obs;
    final selectedFuel = (vehicleToEdit?.fuelType ?? 'Petrol').obs;
    final selectedRegDate = Rx<DateTime?>(vehicleToEdit?.registrationDate);
    final isSubmitting = false.obs;
    final errorMessage = ''.obs;

    final vehicleTypes = [
      'Four Wheeler',
      'Two Wheeler',
      'Commercial',
      'Electric Vehicle',
      'Other',
    ];

    final fuelTypes = [
      'Petrol',
      'Diesel',
      'CNG',
      'Electric',
      'Hybrid',
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
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
                      Icons.directions_car,
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
                          isEditing ? 'Edit Vehicle Profile' : 'Register New Vehicle',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Update registration details and vehicle specs'
                              : 'Add vehicle to link RC, insurance, PUC, and service docs',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 18),

              // Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inline Error Banner (Strict rule: error inside modal!)
                      Obx(() {
                        if (errorMessage.value.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage.value,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Vehicle Registration Number (Required)
                      const Text(
                        'Vehicle Registration Number *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: regNumberController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. GJ-01-AB-1234',
                          prefixIcon: const Icon(Icons.pin, size: 18),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nickname / Name & Vehicle Type (Responsive 2-col or stacked)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;
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
                                      'Nickname / Friendly Name',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: nicknameController,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Creta SX / Dad\'s Activa',
                                        prefixIcon: const Icon(Icons.label_outline, size: 18),
                                        filled: true,
                                        fillColor: AppColors.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
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
                                      'Vehicle Type',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Obx(
                                      () => DropdownButtonFormField<String>(
                                        initialValue: selectedType.value,
                                        items: vehicleTypes
                                            .map(
                                              (t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t, style: const TextStyle(fontSize: 13)),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) selectedType.value = val;
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppColors.surfaceVariant,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: AppColors.border),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
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
                      const SizedBox(height: 14),

                      // Brand / Make & Model Name
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;
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
                                      'Brand / Make',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: brandController,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Hyundai, Honda, Tata',
                                        prefixIcon: const Icon(Icons.business, size: 18),
                                        filled: true,
                                        fillColor: AppColors.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
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
                                      'Model Name / Variant',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: modelController,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Creta SX / Activa 6G',
                                        prefixIcon: const Icon(Icons.car_crash_outlined, size: 18),
                                        filled: true,
                                        fillColor: AppColors.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
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
                      const SizedBox(height: 14),

                      // Fuel Type & Owner Name
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;
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
                                      'Fuel Type',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Obx(
                                      () => DropdownButtonFormField<String>(
                                        initialValue: selectedFuel.value,
                                        items: fuelTypes
                                            .map(
                                              (f) => DropdownMenuItem(
                                                value: f,
                                                child: Text(f, style: const TextStyle(fontSize: 13)),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) selectedFuel.value = val;
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppColors.surfaceVariant,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: AppColors.border),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
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
                                      'Registered Owner Name',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: ownerController,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Mihir Gandhi',
                                        prefixIcon: const Icon(Icons.person_outline, size: 18),
                                        filled: true,
                                        fillColor: AppColors.surfaceVariant,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
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
                      const SizedBox(height: 14),

                      // Registration Date
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Registration Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedRegDate.value ?? now,
                                      firstDate: DateTime(1980),
                                      lastDate: now.add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      selectedRegDate.value = picked;
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
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
                                        const SizedBox(width: 10),
                                        Obx(
                                          () => Text(
                                            selectedRegDate.value != null
                                                ? AppFormatters.formatDate(selectedRegDate.value!)
                                                : 'Select registration date',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: selectedRegDate.value != null
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Chassis & Engine Numbers (Optional)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chassis Number (Optional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: chassisController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'Chassis No.',
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Engine Number (Optional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: engineController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'Engine No.',
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
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton(
                      onPressed: isSubmitting.value
                          ? null
                          : () async {
                              final reg = regNumberController.text.trim().toUpperCase();
                              if (reg.isEmpty) {
                                errorMessage.value = 'Please enter vehicle registration number.';
                                return;
                              }

                              isSubmitting.value = true;
                              errorMessage.value = '';

                              try {
                                final vehicle = MasterVehicleModel(
                                  id: vehicleToEdit?.id ?? '',
                                  vehicleNumber: reg,
                                  nickname: nicknameController.text.trim().isNotEmpty
                                      ? nicknameController.text.trim()
                                      : null,
                                  vehicleType: selectedType.value,
                                  brandMake: brandController.text.trim().isNotEmpty
                                      ? brandController.text.trim()
                                      : null,
                                  modelName: modelController.text.trim().isNotEmpty
                                      ? modelController.text.trim()
                                      : null,
                                  fuelType: selectedFuel.value,
                                  ownerName: ownerController.text.trim().isNotEmpty
                                      ? ownerController.text.trim()
                                      : null,
                                  chassisNumber: chassisController.text.trim().isNotEmpty
                                      ? chassisController.text.trim().toUpperCase()
                                      : null,
                                  engineNumber: engineController.text.trim().isNotEmpty
                                      ? engineController.text.trim().toUpperCase()
                                      : null,
                                  registrationDate: selectedRegDate.value,
                                  createdAt: vehicleToEdit?.createdAt ?? DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );

                                await onSave(vehicle);
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop();
                                }
                              } catch (e) {
                                errorMessage.value = 'Failed to save vehicle: $e';
                              } finally {
                                isSubmitting.value = false;
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          : Text(isEditing ? 'Save Changes' : 'Register Vehicle'),
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
