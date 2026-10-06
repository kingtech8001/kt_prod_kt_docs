import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:uuid/uuid.dart';

/// Reactive state container for an individual appliance item being edited.
/// 100% GetX reactive, zero setState.
class EditApplianceItemState {
  final String id;
  final TextEditingController nameController;
  final TextEditingController modelController;
  final TextEditingController serialController;
  final TextEditingController amountController;
  final TextEditingController customBrandController;
  final TextEditingController careNumberController;
  final RxString selectedBrand;
  final RxString selectedCategory;
  final RxInt warrantyMonths;
  final RxBool hasWarranty;
  final Rx<DateTime> warrantyValidUpto;

  EditApplianceItemState({
    required this.id,
    required String name,
    required String initialBrand,
    required String initialCategory,
    String? model,
    String? serial,
    double amount = 0.0,
    required int initialWarrantyMonths,
    required bool initialHasWarranty,
    required DateTime initialWarrantyValidUpto,
    String? careNumber,
  })  : nameController = TextEditingController(text: name),
        modelController = TextEditingController(text: model ?? ''),
        serialController = TextEditingController(text: serial ?? ''),
        amountController = TextEditingController(
          text: amount > 0 ? amount.toStringAsFixed(0) : '',
        ),
        customBrandController = TextEditingController(
          text: initialBrand != 'Other' &&
                  !AppConstants.popularBrands.contains(initialBrand)
              ? initialBrand
              : '',
        ),
        careNumberController = TextEditingController(text: careNumber ?? ''),
        selectedBrand = initialBrand.obs,
        selectedCategory = initialCategory.obs,
        warrantyMonths = initialWarrantyMonths.obs,
        hasWarranty = initialHasWarranty.obs,
        warrantyValidUpto = initialWarrantyValidUpto.obs;

  void updateWarranty(int months, DateTime purchaseDate) {
    warrantyMonths.value = months;
    if (months == 0) {
      hasWarranty.value = false;
      warrantyValidUpto.value = purchaseDate;
    } else {
      hasWarranty.value = true;
      warrantyValidUpto.value = purchaseDate.add(Duration(days: months * 30));
    }
  }

  void dispose() {
    nameController.dispose();
    modelController.dispose();
    serialController.dispose();
    amountController.dispose();
    customBrandController.dispose();
    careNumberController.dispose();
  }
}

/// 100% GetX-compliant Document Edit Dialog.
/// Zero setState, responsive fluid constraints, inline error banner, compact AppSnackbar on success.
class DocumentEditDialog extends StatelessWidget {
  final DocumentModel document;
  final Future<void> Function({
    required String title,
    String? description,
    String? documentNumber,
    ApplianceWarrantyModel? applianceWarranty,
    VehicleDocumentMetadataModel? vehicleMetadata,
  }) onSave;

  final TextEditingController _titleController;
  final TextEditingController _descriptionController;
  final TextEditingController _documentNumberController;

  // Appliance Invoice Details (If applicable)
  final TextEditingController _storeVendorController;
  final TextEditingController _billingNameController;
  final TextEditingController _totalAmountController;
  final Rx<DateTime> _purchaseDate;
  final RxList<EditApplianceItemState> _applianceItems;

  // Vehicle Document Details (If applicable)
  final TextEditingController _insuranceCompanyController;
  final TextEditingController _premiumAmountController;
  final Rx<DateTime?> _issueDate;
  final Rx<DateTime?> _expiryDate;

  final RxBool _isSaving = false.obs;
  final RxString _errorMessage = ''.obs;

  DocumentEditDialog({
    super.key,
    required this.document,
    required this.onSave,
  })  : _titleController = TextEditingController(text: document.title),
        _descriptionController =
            TextEditingController(text: document.description ?? ''),
        _documentNumberController = TextEditingController(
          text: (document.documentNumber != null &&
                  document.documentNumber!.trim().isNotEmpty)
              ? document.documentNumber!.trim()
              : (document.applianceWarranty?.invoiceNumber ??
                  document.vehicleMetadata?.policyOrCertNumber ??
                  document.personalMetadata?.idNumber ??
                  document.utilityMetadata?.consumerNumber ??
                  ''),
        ),
        _storeVendorController = TextEditingController(
            text: document.applianceWarranty?.storeVendorName ?? ''),
        _billingNameController = TextEditingController(
            text: document.applianceWarranty?.billingName ?? ''),
        _totalAmountController = TextEditingController(
          text: (document.applianceWarranty?.purchaseAmount != null &&
                  document.applianceWarranty!.purchaseAmount > 0)
              ? document.applianceWarranty!.purchaseAmount.toStringAsFixed(0)
              : '',
        ),
        _purchaseDate = (document.applianceWarranty?.purchaseDate ??
                document.createdAt)
            .obs,
        _applianceItems = <EditApplianceItemState>[].obs,
        _insuranceCompanyController = TextEditingController(
          text: document.vehicleMetadata?.insuranceCompany ?? '',
        ),
        _premiumAmountController = TextEditingController(
          text: (document.vehicleMetadata?.premiumAmount != null &&
                  document.vehicleMetadata!.premiumAmount! > 0)
              ? document.vehicleMetadata!.premiumAmount!.toStringAsFixed(0)
              : '',
        ),
        _issueDate = Rx<DateTime?>(document.vehicleMetadata?.issueDate),
        _expiryDate = Rx<DateTime?>(document.vehicleMetadata?.expiryDate) {
    _initializeItems();
  }

  bool get _isAppliance =>
      document.applianceWarranty != null ||
      document.categoryCode == 'appliance_warranty';

  bool get _isVehicle =>
      document.vehicleMetadata != null ||
      document.categoryCode == 'vehicle_docs';

  void _initializeItems() {
    final w = document.applianceWarranty;
    if (w != null && w.items.isNotEmpty) {
      for (var item in w.items) {
        _applianceItems.add(
          EditApplianceItemState(
            id: item.id,
            name: item.productName,
            initialBrand: item.brand,
            initialCategory: item.productCategory,
            model: item.modelNumber,
            serial: item.serialNumber,
            amount: item.purchaseAmount,
            initialWarrantyMonths: item.warrantyPeriodMonths,
            initialHasWarranty: item.hasWarranty,
            initialWarrantyValidUpto: item.warrantyValidUpto,
            careNumber: item.customerCareNumber,
          ),
        );
      }
    } else if (_isAppliance) {
      _applianceItems.add(
        EditApplianceItemState(
          id: const Uuid().v4(),
          name: document.title,
          initialBrand: w?.brand ?? 'Havells',
          initialCategory: document.subCategory,
          initialWarrantyMonths: w?.warrantyPeriodMonths ?? 12,
          initialHasWarranty: w?.hasWarranty ?? true,
          initialWarrantyValidUpto: w?.warrantyValidUpto ??
              DateTime.now().add(const Duration(days: 365)),
        ),
      );
    }
  }

  static Future<bool?> show({
    required DocumentModel document,
    required Future<void> Function({
      required String title,
      String? description,
      String? documentNumber,
      ApplianceWarrantyModel? applianceWarranty,
      VehicleDocumentMetadataModel? vehicleMetadata,
    }) onSave,
  }) {
    return AppDialog.show<bool>(
      DocumentEditDialog(document: document, onSave: onSave),
      barrierDismissible: false,
    );
  }

  void _addApplianceItem() {
    _applianceItems.add(
      EditApplianceItemState(
        id: const Uuid().v4(),
        name: '',
        initialBrand: 'Havells',
        initialCategory: 'Ceiling / Table Fans',
        initialWarrantyMonths: 12,
        initialHasWarranty: true,
        initialWarrantyValidUpto:
            _purchaseDate.value.add(const Duration(days: 365)),
      ),
    );
  }

  void _removeApplianceItem(int index) {
    if (_applianceItems.length > 1) {
      final removed = _applianceItems.removeAt(index);
      removed.dispose();
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _errorMessage.value = 'Document title is required.';
      return;
    }

    _isSaving.value = true;
    _errorMessage.value = '';

    try {
      ApplianceWarrantyModel? updatedAppliance;
      if (_isAppliance && _applianceItems.isNotEmpty) {
        final List<ApplianceItemModel> items = [];
        double computedTotal = 0.0;

        for (var item in _applianceItems) {
          final brand = item.selectedBrand.value == 'Other' &&
                  item.customBrandController.text.isNotEmpty
              ? item.customBrandController.text.trim()
              : item.selectedBrand.value;
          final amount =
              double.tryParse(item.amountController.text.trim()) ?? 0.0;
          computedTotal += amount;
          final name = item.nameController.text.trim().isNotEmpty
              ? item.nameController.text.trim()
              : '$brand ${item.selectedCategory.value}';

          items.add(
            ApplianceItemModel(
              id: item.id,
              productName: name,
              productCategory: item.selectedCategory.value,
              brand: brand,
              modelNumber: item.modelController.text.trim().isNotEmpty
                  ? item.modelController.text.trim()
                  : null,
              serialNumber: item.serialController.text.trim().isNotEmpty
                  ? item.serialController.text.trim()
                  : null,
              purchaseAmount: amount,
              warrantyPeriodMonths:
                  item.hasWarranty.value ? item.warrantyMonths.value : 0,
              warrantyValidUpto: item.hasWarranty.value
                  ? item.warrantyValidUpto.value
                  : _purchaseDate.value,
              customerCareNumber:
                  item.careNumberController.text.trim().isNotEmpty
                      ? item.careNumberController.text.trim()
                      : null,
              warrantyStatus: item.hasWarranty.value ? 'active' : 'no_warranty',
            ),
          );
        }

        final explicitTotal =
            double.tryParse(_totalAmountController.text.trim());
        final totalAmount =
            (explicitTotal != null && explicitTotal > 0)
                ? explicitTotal
                : computedTotal;

        updatedAppliance = ApplianceWarrantyModel(
          id: document.applianceWarranty?.id,
          documentId: document.id,
          items: items,
          billingName: _billingNameController.text.trim().isNotEmpty
              ? _billingNameController.text.trim()
              : 'King Technology',
          storeVendorName: _storeVendorController.text.trim().isNotEmpty
              ? _storeVendorController.text.trim()
              : 'Authorized Vendor',
          invoiceNumber: _documentNumberController.text.trim().isNotEmpty
              ? _documentNumberController.text.trim()
              : 'INV-${DateTime.now().millisecondsSinceEpoch}',
          purchaseDate: _purchaseDate.value,
          purchaseAmount: totalAmount,
        );
      }

      VehicleDocumentMetadataModel? updatedVehicle;
      if (_isVehicle && document.vehicleMetadata != null) {
        final premium = double.tryParse(_premiumAmountController.text.trim());
        updatedVehicle = document.vehicleMetadata!.copyWith(
          policyOrCertNumber: _documentNumberController.text.trim().isNotEmpty
              ? _documentNumberController.text.trim()
              : null,
          insuranceCompany: _insuranceCompanyController.text.trim().isNotEmpty
              ? _insuranceCompanyController.text.trim()
              : null,
          premiumAmount: premium,
          issueDate: _issueDate.value,
          expiryDate: _expiryDate.value,
          notes: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );
      }

      await onSave(
        title: title,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        documentNumber: _documentNumberController.text.trim().isNotEmpty
            ? _documentNumberController.text.trim()
            : null,
        applianceWarranty: updatedAppliance,
        vehicleMetadata: updatedVehicle,
      );

      _disposeControllers();
      // Rule 3.B: Close dialog first, then fire success snackbar
      Get.back(result: true);
      AppSnackbar.showSuccess(
        'Document Updated',
        'Document details have been updated successfully.',
      );
    } catch (e) {
      // Rule 3.B: Render submission error INSIDE the modal, keep dialog open
      _errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isSaving.value = false;
    }
  }

  void _disposeControllers() {
    _titleController.dispose();
    _descriptionController.dispose();
    _documentNumberController.dispose();
    _storeVendorController.dispose();
    _billingNameController.dispose();
    _totalAmountController.dispose();
    _insuranceCompanyController.dispose();
    _premiumAmountController.dispose();
    for (var item in _applianceItems) {
      item.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (_isAppliance || _isVehicle) ? 680 : 480,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dialog Header
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
                        child: Icon(
                          _isAppliance
                              ? Icons.kitchen_outlined
                              : _isVehicle
                                  ? Icons.directions_car_outlined
                                  : Icons.edit_document,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isAppliance
                            ? 'Edit Appliance Invoice'
                            : _isVehicle
                                ? 'Edit Vehicle Document'
                                : 'Edit Document Details',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textSecondary,
                    splashRadius: 18,
                    onPressed: () {
                      _disposeControllers();
                      Get.back(result: false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Inline Error Banner (Rule 3.B)
              Obx(() {
                if (_errorMessage.value.isEmpty) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage.value,
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

              // 3. Scrollable Content Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Document Title *',
                          hintText: 'e.g. Croma Electronics Invoice',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _documentNumberController,
                        decoration: InputDecoration(
                          labelText: _isVehicle
                              ? 'Policy / Certificate / Doc Number'
                              : (_isAppliance
                                  ? 'Invoice Number'
                                  : 'Invoice / Document Number'),
                          hintText: _isVehicle
                              ? 'e.g. POL-98123 or Certificate Number'
                              : 'e.g. INV-98123',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Document Description / Notes',
                          hintText: 'e.g. Contains multiple appliances, repair notes...',
                          alignLabelWithHint: true,
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),

                      // Vehicle Document Section
                      if (_isVehicle) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _insuranceCompanyController,
                                decoration: const InputDecoration(
                                  labelText: 'Insurance Co. / Issuer',
                                  hintText: 'e.g. HDFC ERGO, ICICI Lombard',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _premiumAmountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Premium Amount (₹)',
                                  hintText: 'e.g. 12500',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _issueDate.value ??
                                          DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      _issueDate.value = picked;
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusSmall,
                                  ),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Issue / Start Date',
                                      suffixIcon: _issueDate.value != null
                                          ? IconButton(
                                              icon: const Icon(Icons.clear,
                                                  size: 16),
                                              onPressed: () =>
                                                  _issueDate.value = null,
                                            )
                                          : const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                            ),
                                    ),
                                    child: Text(
                                      _issueDate.value != null
                                          ? AppFormatters.formatDate(
                                              _issueDate.value!,
                                            )
                                          : 'Select Issue Date',
                                      style: TextStyle(
                                        color: _issueDate.value != null
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Obx(
                                () => InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _expiryDate.value ??
                                          DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2050),
                                    );
                                    if (picked != null) {
                                      _expiryDate.value = picked;
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusSmall,
                                  ),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Expiry Date',
                                      suffixIcon: _expiryDate.value != null
                                          ? IconButton(
                                              icon: const Icon(Icons.clear,
                                                  size: 16),
                                              onPressed: () =>
                                                  _expiryDate.value = null,
                                            )
                                          : const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                            ),
                                    ),
                                    child: Text(
                                      _expiryDate.value != null
                                          ? AppFormatters.formatDate(
                                              _expiryDate.value!,
                                            )
                                          : 'Select Expiry Date',
                                      style: TextStyle(
                                        color: _expiryDate.value != null
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Multi-Product Appliance Section
                      if (_isAppliance) ...[
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 12),

                        // Invoice Level Fields
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _storeVendorController,
                                decoration: const InputDecoration(
                                  labelText: 'Store / Vendor',
                                  hintText: 'e.g. Vijay Sales, Amazon',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _billingNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Customer / Billing Name',
                                  hintText: 'e.g. King Technology',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _totalAmountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Total Bill Amount (₹)',
                                  hintText: 'e.g. 65000',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Obx(
                                () => InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _purchaseDate.value,
                                      firstDate: DateTime(2010),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      _purchaseDate.value = picked;
                                      for (var item in _applianceItems) {
                                        item.updateWarranty(
                                          item.warrantyMonths.value,
                                          picked,
                                        );
                                      }
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Purchase Date',
                                      suffixIcon:
                                          Icon(Icons.calendar_today, size: 18),
                                    ),
                                    child: Text(
                                      AppFormatters.formatDate(
                                          _purchaseDate.value),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Items Repeater Header
                        Obx(
                          () => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.devices_other,
                                    color: AppColors.warrantyEmerald,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Products Covered (${_applianceItems.length})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _addApplianceItem,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Product'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // List of Products
                        Obx(
                          () => Column(
                            children:
                                List.generate(_applianceItems.length, (idx) {
                              final item = _applianceItems[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.radiusSmall),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Product #${idx + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.warrantyEmerald,
                                          ),
                                        ),
                                        if (_applianceItems.length > 1)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.error,
                                              size: 18,
                                            ),
                                            splashRadius: 16,
                                            onPressed: () =>
                                                _removeApplianceItem(idx),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: TextField(
                                            controller: item.nameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Product Name / Model',
                                              hintText:
                                                  'e.g. LG Smart Refrigerator',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: Obx(
                                            () =>
                                                DropdownButtonFormField<String>(
                                              initialValue: AppConstants.popularBrands
                                                      .contains(item
                                                          .selectedBrand.value)
                                                  ? item.selectedBrand.value
                                                  : 'Other',
                                              decoration: const InputDecoration(
                                                labelText: 'Brand',
                                              ),
                                              items: [
                                                ...AppConstants.popularBrands,
                                                'Other',
                                              ].map((b) {
                                                return DropdownMenuItem(
                                                  value: b,
                                                  child: Text(
                                                    b,
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  item.selectedBrand.value =
                                                      val;
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Obx(() {
                                      if (item.selectedBrand.value != 'Other') {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: TextField(
                                          controller:
                                              item.customBrandController,
                                          decoration: const InputDecoration(
                                            labelText: 'Custom Brand Name',
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: item.serialController,
                                            decoration: const InputDecoration(
                                              labelText: 'Serial Number',
                                              hintText: 'SN-XXXXX',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Obx(
                                            () => DropdownButtonFormField<int>(
                                              initialValue: item.warrantyMonths.value,
                                              decoration: const InputDecoration(
                                                labelText: 'Warranty Period',
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 0,
                                                  child: Text('No Warranty'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 6,
                                                  child: Text('6 Months'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 12,
                                                  child: Text('1 Year'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 24,
                                                  child: Text('2 Years'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 36,
                                                  child: Text('3 Years'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 60,
                                                  child: Text('5 Years'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 120,
                                                  child: Text('10 Years'),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  item.updateWarranty(
                                                    val,
                                                    _purchaseDate.value,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _disposeControllers();
                      Get.back(result: false);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton(
                      onPressed: _isSaving.value ? null : _handleSave,
                      child: _isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
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

/// Standardized delete confirmation modal.
class DocumentDeleteDialog extends StatelessWidget {
  final String documentTitle;
  final Future<void> Function() onConfirm;

  const DocumentDeleteDialog({
    super.key,
    required this.documentTitle,
    required this.onConfirm,
  });

  static void show({
    required String documentTitle,
    required Future<void> Function() onConfirm,
  }) {
    AppDialog.show(
      DocumentDeleteDialog(documentTitle: documentTitle, onConfirm: onConfirm),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RxBool isDeleting = false.obs;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Move Document to Trash?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '"$documentTitle" will be moved to the trash bin. You can restore it later if needed.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isDeleting.value
                          ? null
                          : () async {
                              isDeleting.value = true;
                              try {
                                Get.back();
                                await onConfirm();
                              } catch (e) {
                                AppSnackbar.showError('Delete Failed', e.toString());
                              } finally {
                                isDeleting.value = false;
                              }
                            },
                      child: isDeleting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Move to Trash'),
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
