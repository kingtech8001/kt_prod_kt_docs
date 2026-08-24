import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/address_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/folder_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_metadata_model.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/category_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/document_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/folder_repository.dart';
import 'package:kt_prod_kt_docs/app/data/repositories/master_data_repository.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/file_compressor.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:mime/mime.dart';

class DocumentUploadController extends GetxController {
  final DocumentRepository _documentRepository;
  final CategoryRepository _categoryRepository;
  final FolderRepository _folderRepository;
  final MasterDataRepository _masterDataRepository;

  DocumentUploadController(
    this._documentRepository,
    this._categoryRepository,
    this._folderRepository,
    this._masterDataRepository,
  );

  final isLoading = false.obs;
  final categories = <CategoryModel>[].obs;
  final folders = <FolderModel>[].obs;

  // Compression State
  final isCompressing = false.obs;
  final compressionResult = Rxn<CompressionResult>();
  final useCompressed = true.obs;
  final compressionQuality = 70.obs;
  final compressionProgress = 0.0.obs;
  final compressionProgressText = ''.obs;

  // Dynamic Master Data
  final dynamicCities = <String>[].obs;
  final dynamicBrands = <String>[].obs;
  final dynamicApplianceSubcategories = <String>[].obs;
  final dynamicUtilityTypes = <String>[].obs;
  final dynamicPersons = <MasterPersonModel>[].obs;
  final dynamicPersonalDocTypes = <MasterPersonalDocTypeModel>[].obs;

  // Selected File
  final selectedFile = Rxn<PlatformFile>();

  // General Fields
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final documentNumberController = TextEditingController();
  final selectedCategoryId = ''.obs;
  final selectedSubcategory = ''.obs;
  final selectedFolderId = RxnString();

  // Address Fields
  final premiseNameController = TextEditingController();
  final flatHouseNoController = TextEditingController();
  final buildingNameController = TextEditingController();
  final areaLocalityController = TextEditingController();
  final selectedCity = 'Ahmedabad'.obs;
  final stateController = TextEditingController(text: 'Gujarat');
  final postalCodeController = TextEditingController();

  // Utility Bill Specific Fields
  final utilityProviderController = TextEditingController();
  final consumerNumberController = TextEditingController();
  final meterNumberController = TextEditingController();
  final billAmountController = TextEditingController();
  final billDate = Rx<DateTime>(DateTime.now());
  final dueDate = Rxn<DateTime>();
  final utilityPaymentStatus = 'pending'.obs;

  // Appliance Warranty Specific Fields
  final productNameController = TextEditingController();
  final selectedBrand = 'Havells'.obs;
  final customBrandController = TextEditingController();
  final modelNumberController = TextEditingController();
  final serialNumberController = TextEditingController();
  final billingNameController = TextEditingController();
  final storeVendorNameController = TextEditingController();
  final invoiceNumberController = TextEditingController();
  final purchaseAmountController = TextEditingController();
  final purchaseDate = Rx<DateTime>(DateTime.now());
  final warrantyMonths = 12.obs;
  final warrantyValidUpto = Rx<DateTime>(DateTime.now().add(const Duration(days: 365)));
  final customerCareNumberController = TextEditingController();

  // Personal / Identity Specific Fields
  final selectedPersonId = RxnString();
  final selectedPersonName = 'Mihir Gandhi'.obs;
  final selectedPersonalDocTypeId = RxnString();
  final selectedPersonalDocTypeName = 'Aadhaar Card'.obs;
  final personalIdNumberController = TextEditingController();
  final personalIssueDate = Rxn<DateTime>();
  final personalExpiryDate = Rxn<DateTime>();
  final personalIssuingAuthorityController = TextEditingController();
  final personalNotesController = TextEditingController();

  CategoryModel? get currentCategory {
    if (selectedCategoryId.value.isEmpty) return null;
    return categories.firstWhereOrNull((c) => c.id == selectedCategoryId.value);
  }

  bool get showCityFilter => currentCategory?.hasCityFilter ?? true;
  bool get showTitleField => currentCategory?.hasTitleField ?? true;

  bool get isUtilityBill {
    return currentCategory?.code == 'utility_bills';
  }

  bool get isApplianceWarranty {
    return currentCategory?.code == 'appliance_warranty';
  }

  bool get isPersonalDoc {
    return currentCategory?.code == 'identity_docs';
  }

  bool get selectedDocTypeHasExpiry {
    final type = dynamicPersonalDocTypes.firstWhereOrNull((t) => t.name == selectedPersonalDocTypeName.value);
    return type?.hasExpiry ?? false;
  }

  @override
  void onInit() {
    super.onInit();
    loadCategoriesAndFolders();
    loadMasterData();
  }

  Future<void> loadMasterData() async {
    try {
      final cList = await _masterDataRepository.getCities(activeOnly: true);
      if (cList.isNotEmpty) {
        dynamicCities.assignAll(cList.map((c) => c.name));
        selectedCity.value = cList.first.name;
      }

      final bList = await _masterDataRepository.getBrands(activeOnly: true);
      if (bList.isNotEmpty) {
        dynamicBrands.assignAll(bList.map((b) => b.name));
        selectedBrand.value = bList.first.name;
      }

      final sList = await _masterDataRepository.getApplianceSubcategories(activeOnly: true);
      if (sList.isNotEmpty) {
        dynamicApplianceSubcategories.assignAll(sList.map((s) => s.name));
      }

      final pList = await _masterDataRepository.getUtilityProviders(activeOnly: true);
      if (pList.isNotEmpty) {
        dynamicUtilityTypes.assignAll(pList.map((p) => p.utilityType).toSet().toList());
      }

      final personList = await _masterDataRepository.getPersons(activeOnly: true);
      if (personList.isNotEmpty) {
        dynamicPersons.assignAll(personList);
        selectedPersonId.value = personList.first.id;
        selectedPersonName.value = personList.first.fullName;
      }

      final docTypeList = await _masterDataRepository.getPersonalDocTypes(activeOnly: true);
      if (docTypeList.isNotEmpty) {
        dynamicPersonalDocTypes.assignAll(docTypeList);
        selectedPersonalDocTypeId.value = docTypeList.first.id;
        selectedPersonalDocTypeName.value = docTypeList.first.name;
      }
    } catch (e, st) {
      AppLogger.error('UPLOAD_CTRL', 'Error loading master data: $e', error: e, stackTrace: st);
    }
  }

  Future<void> loadCategoriesAndFolders() async {
    AppLogger.debug('UPLOAD_CTRL', 'Loading categories and folders for upload form...');
    try {
      final cats = await _categoryRepository.getAllCategories();
      categories.assignAll(cats);
      if (cats.isNotEmpty) {
        selectedCategoryId.value = cats.first.id;
        updateSubcategoriesForCategory(cats.first.code);
      }

      final flds = await _folderRepository.getFolders();
      folders.assignAll(flds);
      AppLogger.info('UPLOAD_CTRL', 'Categories (${cats.length}) & Folders (${flds.length}) loaded.');
    } catch (e, st) {
      AppLogger.error('UPLOAD_CTRL', 'Error in loadCategoriesAndFolders: $e', error: e, stackTrace: st);
      Get.snackbar('Error Loading Setup', e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  void onCategoryChanged(String? catId) {
    if (catId == null) return;
    selectedCategoryId.value = catId;
    final cat = categories.firstWhereOrNull((c) => c.id == catId);
    if (cat != null) {
      updateSubcategoriesForCategory(cat.code);
    }
  }

  void onPersonChanged(String? personName) {
    if (personName == null) return;
    selectedPersonName.value = personName;
    final person = dynamicPersons.firstWhereOrNull((p) => p.fullName == personName);
    selectedPersonId.value = person?.id;
    _updateTitleForPersonalDoc();
  }

  void onPersonalDocTypeChanged(String? docTypeName) {
    if (docTypeName == null) return;
    selectedPersonalDocTypeName.value = docTypeName;
    final type = dynamicPersonalDocTypes.firstWhereOrNull((t) => t.name == docTypeName);
    selectedPersonalDocTypeId.value = type?.id;
    selectedSubcategory.value = docTypeName;
    _updateTitleForPersonalDoc();
  }

  void _updateTitleForPersonalDoc() {
    if (isPersonalDoc) {
      titleController.text = '${selectedPersonalDocTypeName.value} - ${selectedPersonName.value}';
    }
  }

  void updateSubcategoriesForCategory(String catCode) {
    if (catCode == 'utility_bills') {
      final list = dynamicUtilityTypes.isNotEmpty ? dynamicUtilityTypes : AppConstants.utilitySubcategories;
      selectedSubcategory.value = list.first;
      if (titleController.text.isEmpty || titleController.text.contains(' - ')) {
        titleController.text = 'Electricity / Light Bill';
      }
    } else if (catCode == 'appliance_warranty') {
      final list = dynamicApplianceSubcategories.isNotEmpty ? dynamicApplianceSubcategories : AppConstants.applianceSubcategories;
      selectedSubcategory.value = list.first;
      if (titleController.text.isEmpty || titleController.text.contains(' - ')) {
        titleController.text = 'Appliance Warranty Invoice';
      }
    } else if (catCode == 'identity_docs') {
      final list = dynamicPersonalDocTypes.map((t) => t.name).toList();
      selectedSubcategory.value = list.isNotEmpty ? list.first : 'Aadhaar Card';
      _updateTitleForPersonalDoc();
    } else {
      selectedSubcategory.value = 'General Document';
    }
  }

  bool get isSelectedFileCompressible {
    final file = selectedFile.value;
    if (file == null) return false;
    return FileCompressor.isCompressible(file.name);
  }

  Future<void> compressSelectedFile() async {
    final file = selectedFile.value;
    if (file == null || file.bytes == null) return;
    if (!FileCompressor.isCompressible(file.name)) {
      compressionResult.value = null;
      return;
    }

    isCompressing.value = true;
    compressionProgress.value = 0.12;
    compressionProgressText.value = 'Preparing optimization...';

    // Smooth progressive progress ticker to prevent any freezes during single-threaded execution
    Timer? ticker;
    ticker = Timer.periodic(const Duration(milliseconds: 70), (t) {
      if (compressionProgress.value < 0.90) {
        compressionProgress.value = (compressionProgress.value + 0.05).clamp(0.12, 0.90);
      }
    });

    try {
      // Yield to event loop to guarantee the UI renders the loader immediately
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await FileCompressor.compressFile(
        bytes: file.bytes!,
        fileName: file.name,
        quality: compressionQuality.value,
        onProgress: (progress, message) {
          if (progress > compressionProgress.value) {
            compressionProgress.value = progress.clamp(0.12, 0.95);
          }
          compressionProgressText.value = message;
        },
      );

      ticker.cancel();
      compressionProgress.value = 1.0;
      compressionProgressText.value = 'Optimization complete!';
      await Future.delayed(const Duration(milliseconds: 60));

      compressionResult.value = result;
      useCompressed.value = true; // Always default to compressed as requested
    } catch (e, st) {
      ticker.cancel();
      AppLogger.error('UPLOAD_CTRL', 'Error compressing file: $e', error: e, stackTrace: st);
    } finally {
      ticker.cancel();
      isCompressing.value = false;
    }
  }

  void setCompressionQuality(int quality) {
    if (compressionQuality.value == quality) return;
    compressionQuality.value = quality;
    compressSelectedFile();
  }

  void onFileSelected(PlatformFile file) {
    AppLogger.info('UPLOAD_CTRL', 'File selected: ${file.name}, Size: ${file.size} bytes');
    selectedFile.value = file;
    if (titleController.text.isEmpty) {
      if (isPersonalDoc) {
        _updateTitleForPersonalDoc();
      } else {
        final nameWithoutExt = file.name.contains('.')
            ? file.name.substring(0, file.name.lastIndexOf('.'))
            : file.name;
        titleController.text = nameWithoutExt.replaceAll('_', ' ');
      }
    }

    // Trigger local client compression
    compressSelectedFile();
  }

  void updateWarrantyMonths(int months) {
    warrantyMonths.value = months;
    warrantyValidUpto.value = purchaseDate.value.add(Duration(days: months * 30));
  }

  Future<void> submitUpload() async {
    final file = selectedFile.value;
    if (file == null) {
      Get.snackbar(
        'File Missing',
        'Please select or drag-and-drop a document file to upload.',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }

    if (file.bytes == null) {
      Get.snackbar(
        'File Read Error',
        'Could not read file binary data. Please try selecting the file again.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    String title = titleController.text.trim();
    if (title.isEmpty) {
      if (!showTitleField) {
        // Auto-derive title from file name or subcategory
        final rawName = file.name;
        title = rawName.contains('.')
            ? rawName.substring(0, rawName.lastIndexOf('.'))
            : rawName;
        if (title.isEmpty) title = selectedSubcategory.value;
      } else {
        Get.snackbar(
          'Title Required',
          'Please enter a descriptive document title.',
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
        return;
      }
    }

    isLoading.value = true;
    AppLogger.info('UPLOAD_CTRL', 'Starting secure document upload for: $title (${file.name})');

    try {
      final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';

      // 1. Prepare Address Metadata (Only if city filter is enabled for this category)
      AddressModel? address;
      if (showCityFilter && (selectedCity.value.isNotEmpty || areaLocalityController.text.isNotEmpty)) {
        address = AddressModel(
          premiseName: premiseNameController.text.trim().isNotEmpty
              ? premiseNameController.text.trim()
              : null,
          flatHouseNo: flatHouseNoController.text.trim().isNotEmpty
              ? flatHouseNoController.text.trim()
              : null,
          buildingName: buildingNameController.text.trim().isNotEmpty
              ? buildingNameController.text.trim()
              : null,
          areaLocality: areaLocalityController.text.trim().isNotEmpty
              ? areaLocalityController.text.trim()
              : 'General',
          city: selectedCity.value,
          state: stateController.text.trim().isNotEmpty ? stateController.text.trim() : 'Gujarat',
          postalCode: postalCodeController.text.trim().isNotEmpty
              ? postalCodeController.text.trim()
              : null,
        );
      }

      // 2. Prepare Domain Specific Metadata
      UtilityMetadataModel? utilityMeta;
      if (isUtilityBill) {
        final amount = double.tryParse(billAmountController.text.trim()) ?? 0.0;
        utilityMeta = UtilityMetadataModel(
          utilityType: selectedSubcategory.value,
          providerName: utilityProviderController.text.trim().isNotEmpty
              ? utilityProviderController.text.trim()
              : 'Generic Provider',
          consumerNumber: consumerNumberController.text.trim().isNotEmpty
              ? consumerNumberController.text.trim()
              : 'CN-${DateTime.now().millisecondsSinceEpoch}',
          meterNumber: meterNumberController.text.trim().isNotEmpty
              ? meterNumberController.text.trim()
              : null,
          billAmount: amount,
          billDate: billDate.value,
          dueDate: dueDate.value,
          paymentStatus: utilityPaymentStatus.value,
          paymentDate: utilityPaymentStatus.value == 'paid' ? DateTime.now() : null,
        );
      }

      ApplianceWarrantyModel? applianceMeta;
      if (isApplianceWarranty) {
        final amount = double.tryParse(purchaseAmountController.text.trim()) ?? 0.0;
        final brand = selectedBrand.value == 'Other' && customBrandController.text.isNotEmpty
            ? customBrandController.text.trim()
            : selectedBrand.value;

        applianceMeta = ApplianceWarrantyModel(
          productName: productNameController.text.trim().isNotEmpty
              ? productNameController.text.trim()
              : title,
          productCategory: selectedSubcategory.value,
          brand: brand,
          modelNumber: modelNumberController.text.trim().isNotEmpty
              ? modelNumberController.text.trim()
              : null,
          serialNumber: serialNumberController.text.trim().isNotEmpty
              ? serialNumberController.text.trim()
              : null,
          billingName: billingNameController.text.trim().isNotEmpty
              ? billingNameController.text.trim()
              : 'King Technology',
          storeVendorName: storeVendorNameController.text.trim().isNotEmpty
              ? storeVendorNameController.text.trim()
              : 'Authorized Vendor',
          invoiceNumber: invoiceNumberController.text.trim().isNotEmpty
              ? invoiceNumberController.text.trim()
              : 'INV-${DateTime.now().millisecondsSinceEpoch}',
          purchaseDate: purchaseDate.value,
          purchaseAmount: amount,
          warrantyPeriodMonths: warrantyMonths.value,
          warrantyValidUpto: warrantyValidUpto.value,
          customerCareNumber: customerCareNumberController.text.trim().isNotEmpty
              ? customerCareNumberController.text.trim()
              : null,
        );
      }

      PersonalDocumentMetadataModel? personalMeta;
      if (isPersonalDoc) {
        personalMeta = PersonalDocumentMetadataModel(
          personId: selectedPersonId.value,
          personName: selectedPersonName.value,
          docTypeId: selectedPersonalDocTypeId.value,
          docTypeName: selectedPersonalDocTypeName.value,
          idNumber: personalIdNumberController.text.trim().isNotEmpty
              ? personalIdNumberController.text.trim()
              : null,
          issueDate: personalIssueDate.value,
          expiryDate: personalExpiryDate.value,
          issuingAuthority: personalIssuingAuthorityController.text.trim().isNotEmpty
              ? personalIssuingAuthorityController.text.trim()
              : null,
          notes: personalNotesController.text.trim().isNotEmpty
              ? personalNotesController.text.trim()
              : null,
        );
      }

      // Determine file bytes, file name, and mime type based on user's compression selection
      Uint8List uploadBytes = file.bytes!;
      String uploadFileName = file.name;
      String uploadMimeType = mimeType;

      if (useCompressed.value && compressionResult.value != null) {
        uploadBytes = compressionResult.value!.compressedBytes;
        uploadFileName = compressionResult.value!.compressedFileName;
        uploadMimeType = compressionResult.value!.mimeType;
        AppLogger.info(
          'UPLOAD_CTRL',
          'Uploading COMPRESSED version ($uploadFileName, ${uploadBytes.length} bytes, savings: ${compressionResult.value!.savingsFormatted})',
        );
      } else {
        AppLogger.info(
          'UPLOAD_CTRL',
          'Uploading ORIGINAL version ($uploadFileName, ${uploadBytes.length} bytes)',
        );
      }

      // 3. Create Document Record (Repository handles storage upload and db record)
      final createdDoc = await _documentRepository.createDocument(
        title: title,
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null,
        documentNumber: documentNumberController.text.trim().isNotEmpty
            ? documentNumberController.text.trim()
            : (personalMeta?.idNumber),
        categoryId: selectedCategoryId.value,
        subCategory: selectedSubcategory.value,
        folderId: selectedFolderId.value,
        fileName: uploadFileName,
        fileBytes: uploadBytes,
        mimeType: uploadMimeType,
        address: address,
        utilityMetadata: utilityMeta,
        applianceWarranty: applianceMeta,
        personalMetadata: personalMeta,
      );

      AppLogger.info('UPLOAD_CTRL', 'Document successfully created in Vault! ID: ${createdDoc.id}');

      Get.snackbar(
        'Upload Successful',
        'Document "${createdDoc.title}" stored securely in Kt DocHolder.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      if (isPersonalDoc) {
        Get.offNamed(AppRoutes.PERSONAL_DOCS);
      } else if (isUtilityBill) {
        Get.offNamed(AppRoutes.UTILITY_BILLS);
      } else if (isApplianceWarranty) {
        Get.offNamed(AppRoutes.APPLIANCES);
      } else {
        Get.offNamed(AppRoutes.DOCUMENTS);
      }
    } catch (e, st) {
      AppLogger.error('UPLOAD_CTRL', 'Fatal error during document upload: $e', error: e, stackTrace: st);
      Get.snackbar(
        'Upload Failed',
        'Error uploading file: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    documentNumberController.dispose();
    premiseNameController.dispose();
    flatHouseNoController.dispose();
    buildingNameController.dispose();
    areaLocalityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    utilityProviderController.dispose();
    consumerNumberController.dispose();
    meterNumberController.dispose();
    billAmountController.dispose();
    productNameController.dispose();
    customBrandController.dispose();
    modelNumberController.dispose();
    serialNumberController.dispose();
    billingNameController.dispose();
    storeVendorNameController.dispose();
    invoiceNumberController.dispose();
    purchaseAmountController.dispose();
    customerCareNumberController.dispose();
    personalIdNumberController.dispose();
    personalIssuingAuthorityController.dispose();
    personalNotesController.dispose();
    super.onClose();
  }
}
