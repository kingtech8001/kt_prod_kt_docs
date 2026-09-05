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
import 'package:kt_prod_kt_docs/app/data/datasets/documents_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/folder_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/settings_dataset.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_compressor.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

class ApplianceItemFormState {
  final String id;
  final productNameController = TextEditingController();
  final selectedCategory = 'Ceiling / Table Fans'.obs;
  final selectedBrand = 'Havells'.obs;
  final customBrandController = TextEditingController();
  final modelNumberController = TextEditingController();
  final serialNumberController = TextEditingController();
  final purchaseAmountController = TextEditingController();
  final hasWarrantyCoverage = true.obs;
  final warrantyMonths = 12.obs;
  final warrantyValidUpto = Rx<DateTime>(
    DateTime.now().add(const Duration(days: 365)),
  );
  final customerCareNumberController = TextEditingController();

  ApplianceItemFormState({
    String? id,
    String? initialName,
    String? initialCategory,
    String? initialBrand,
    String? initialModel,
    String? initialSerial,
    double? initialAmount,
    int initialWarrantyMonths = 12,
    DateTime? initialValidUpto,
    String? initialCareNumber,
    bool initialHasWarranty = true,
  }) : id = id ?? const Uuid().v4() {
    if (initialName != null) productNameController.text = initialName;
    if (initialCategory != null) selectedCategory.value = initialCategory;
    if (initialBrand != null) selectedBrand.value = initialBrand;
    if (initialModel != null) modelNumberController.text = initialModel;
    if (initialSerial != null) serialNumberController.text = initialSerial;
    if (initialAmount != null && initialAmount > 0) {
      purchaseAmountController.text = initialAmount.toStringAsFixed(0);
    }
    hasWarrantyCoverage.value = initialHasWarranty;
    warrantyMonths.value = initialWarrantyMonths;
    if (initialValidUpto != null) {
      warrantyValidUpto.value = initialValidUpto;
    }
    if (initialCareNumber != null) {
      customerCareNumberController.text = initialCareNumber;
    }
  }

  void updateWarrantyMonths(int months, DateTime purchaseDate) {
    warrantyMonths.value = months;
    if (months == 0) {
      hasWarrantyCoverage.value = false;
      warrantyValidUpto.value = purchaseDate;
    } else {
      hasWarrantyCoverage.value = true;
      warrantyValidUpto.value = purchaseDate.add(Duration(days: months * 30));
    }
  }

  void toggleWarrantyCoverage(bool hasWarranty, DateTime purchaseDate) {
    hasWarrantyCoverage.value = hasWarranty;
    if (!hasWarranty) {
      warrantyMonths.value = 0;
      warrantyValidUpto.value = purchaseDate;
    } else {
      if (warrantyMonths.value == 0) {
        warrantyMonths.value = 12;
      }
      warrantyValidUpto.value = purchaseDate.add(
        Duration(days: warrantyMonths.value * 30),
      );
    }
  }

  void onPurchaseDateChanged(DateTime newPurchaseDate) {
    if (hasWarrantyCoverage.value && warrantyMonths.value > 0) {
      warrantyValidUpto.value = newPurchaseDate.add(
        Duration(days: warrantyMonths.value * 30),
      );
    } else {
      warrantyValidUpto.value = newPurchaseDate;
    }
  }

  void dispose() {
    productNameController.dispose();
    customBrandController.dispose();
    modelNumberController.dispose();
    serialNumberController.dispose();
    purchaseAmountController.dispose();
    customerCareNumberController.dispose();
  }
}

class DocumentUploadController extends GetxController {
  final DocumentsDataset _documentsDataset;
  final FolderDataset _folderDataset;
  final SettingsDataset _settingsDataset;

  DocumentUploadController(
    this._documentsDataset,
    this._folderDataset,
    this._settingsDataset,
  );

  final isInitialLoading = true.obs;
  final isSubmitting = false.obs;
  final formErrorMessage = ''.obs;

  // Backward compatibility alias for any views reading isLoading
  RxBool get isLoading => isSubmitting;

  final categories = <CategoryModel>[].obs;
  final folders = <FolderModel>[].obs;

  // Compression State (Powered by King Technology Media Engine API)
  final isCompressing = false.obs;
  final compressionResult = Rxn<CompressionResult>();
  final useCompressed = false.obs; // Original Quality is default selected
  final compressionPreset = 'recommended'.obs; // 'recommended', 'extreme', 'high', 'low', 'lossless', 'custom'
  final compressionQuality = 75.obs;
  final lastCompressedQuality = 75.obs;

  bool get isQualityDirty =>
      compressionResult.value != null &&
      compressionQuality.value != lastCompressedQuality.value;

  final pdfCompressionLevel = 'recommended'.obs; // Synchronized legacy alias for views
  final pdfQuality = 72.obs;
  final pdfDpi = 150.obs; // 96, 120, 150, 200, 300
  final maxDimension = Rxn<int>();
  final targetSizeKb = Rxn<int>();
  final isGrayscale = false.obs;
  final stripMetadata = true.obs;
  final showAdvancedSettings = false.obs;
  final compressionProgress = 0.0.obs;
  final compressionProgressText = ''.obs;
  final compressionError = ''.obs;

  final targetSizeController = TextEditingController();
  final maxDimensionController = TextEditingController();

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

  // Appliance Warranty Specific Fields (Invoice Level)
  final billingNameController = TextEditingController();
  final storeVendorNameController = TextEditingController();
  final invoiceNumberController = TextEditingController();
  final purchaseAmountController = TextEditingController();
  final purchaseDate = Rx<DateTime>(DateTime.now());

  // Dynamic Multi-Product Items Repeater
  final applianceItems = <ApplianceItemFormState>[].obs;

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
    final type = dynamicPersonalDocTypes.firstWhereOrNull(
      (t) => t.name == selectedPersonalDocTypeName.value,
    );
    return type?.hasExpiry ?? false;
  }

  @override
  void onInit() {
    super.onInit();
    addApplianceItem();
    _initializeData();
  }

  Future<void> _initializeData() async {
    isInitialLoading.value = true;
    formErrorMessage.value = '';
    try {
      await Future.wait([
        loadCategoriesAndFolders(),
        loadMasterData(),
      ]);
    } catch (e, st) {
      AppLogger.error(
        'UPLOAD_CTRL',
        'Error during initial setup initialization: $e',
        error: e,
        stackTrace: st,
      );
      formErrorMessage.value = 'Error initializing configuration. Please refresh.';
    } finally {
      isInitialLoading.value = false;
    }
  }

  Future<void> loadMasterData() async {
    try {
      final cList = await _settingsDataset.getCities(activeOnly: true);
      if (cList.isNotEmpty) {
        dynamicCities.assignAll(cList.map((c) => c.name));
        selectedCity.value = cList.first.name;
      }

      final bList = await _settingsDataset.getBrands(activeOnly: true);
      if (bList.isNotEmpty) {
        dynamicBrands.assignAll(bList.map((b) => b.name));
        if (applianceItems.isNotEmpty &&
            (applianceItems.first.selectedBrand.value.isEmpty ||
                applianceItems.first.selectedBrand.value == 'Generic')) {
          applianceItems.first.selectedBrand.value = bList.first.name;
        }
      }

      final sList = await _settingsDataset.getApplianceSubcategories(
        activeOnly: true,
      );
      if (sList.isNotEmpty) {
        dynamicApplianceSubcategories.assignAll(sList.map((s) => s.name));
      }

      final pList = await _settingsDataset.getUtilityProviders(
        activeOnly: true,
      );
      if (pList.isNotEmpty) {
        dynamicUtilityTypes.assignAll(
          pList.map((p) => p.utilityType).toSet().toList(),
        );
      }

      final personList = await _settingsDataset.getPersons(
        activeOnly: true,
      );
      if (personList.isNotEmpty) {
        dynamicPersons.assignAll(personList);
        selectedPersonId.value = personList.first.id;
        selectedPersonName.value = personList.first.fullName;
      }

      final docTypeList = await _settingsDataset.getPersonalDocTypes(
        activeOnly: true,
      );
      if (docTypeList.isNotEmpty) {
        dynamicPersonalDocTypes.assignAll(docTypeList);
        selectedPersonalDocTypeId.value = docTypeList.first.id;
        selectedPersonalDocTypeName.value = docTypeList.first.name;
      }
    } catch (e, st) {
      AppLogger.error(
        'UPLOAD_CTRL',
        'Error loading master data: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> loadCategoriesAndFolders() async {
    AppLogger.debug(
      'UPLOAD_CTRL',
      'Loading categories and folders for upload form...',
    );
    try {
      final cats = await _documentsDataset.getAllCategories();
      categories.assignAll(cats);
      if (cats.isNotEmpty) {
        selectedCategoryId.value = cats.first.id;
        updateSubcategoriesForCategory(cats.first.code);
      }

      final flds = await _folderDataset.getFolders();
      folders.assignAll(flds);

      final paramFolderId = Get.parameters['folderId'];
      if (paramFolderId != null && flds.any((f) => f.id == paramFolderId)) {
        selectedFolderId.value = paramFolderId;
      }

      AppLogger.info(
        'UPLOAD_CTRL',
        'Categories (${cats.length}) & Folders (${flds.length}) loaded.',
      );
    } catch (e, st) {
      AppLogger.error(
        'UPLOAD_CTRL',
        'Error in loadCategoriesAndFolders: $e',
        error: e,
        stackTrace: st,
      );
      formErrorMessage.value = 'Failed to load document categories and folders.';
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
    final person = dynamicPersons.firstWhereOrNull(
      (p) => p.fullName == personName,
    );
    selectedPersonId.value = person?.id;
    _updateTitleForPersonalDoc();
  }

  void onPersonalDocTypeChanged(String? docTypeName) {
    if (docTypeName == null) return;
    selectedPersonalDocTypeName.value = docTypeName;
    final type = dynamicPersonalDocTypes.firstWhereOrNull(
      (t) => t.name == docTypeName,
    );
    selectedPersonalDocTypeId.value = type?.id;
    selectedSubcategory.value = docTypeName;
    _updateTitleForPersonalDoc();
  }

  void _updateTitleForPersonalDoc() {
    if (isPersonalDoc) {
      titleController.text =
          '${selectedPersonalDocTypeName.value} - ${selectedPersonName.value}';
    }
  }

  void updateSubcategoriesForCategory(String catCode) {
    if (catCode == 'utility_bills') {
      final list = dynamicUtilityTypes.isNotEmpty
          ? dynamicUtilityTypes
          : AppConstants.utilitySubcategories;
      selectedSubcategory.value = list.first;
      if (titleController.text.isEmpty ||
          titleController.text.contains(' - ')) {
        titleController.text = 'Electricity / Light Bill';
      }
    } else if (catCode == 'appliance_warranty') {
      final list = dynamicApplianceSubcategories.isNotEmpty
          ? dynamicApplianceSubcategories
          : AppConstants.applianceSubcategories;
      selectedSubcategory.value = list.first;
      if (titleController.text.isEmpty ||
          titleController.text.contains(' - ')) {
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

  void setUploadCompressionMode(bool compressed) {
    AppLogger.info(
      'UPLOAD_CTRL',
      '🔘 [OPTION CHANGED] User selected upload version: '
      '${compressed ? "COMPRESSED (OPTIMIZED VIA MEDIA ENGINE)" : "ORIGINAL QUALITY (NO COMPRESSION)"}',
    );
    useCompressed.value = compressed;
    if (compressed &&
        compressionResult.value == null &&
        !isCompressing.value &&
        selectedFile.value != null &&
        FileCompressor.isCompressible(selectedFile.value!.name)) {
      AppLogger.info(
        'UPLOAD_CTRL',
        '⚡ [TRIGGER COMPRESSION] Initiating API compression for selected file...',
      );
      compressSelectedFile();
    }
  }

  Future<void> compressSelectedFile() async {
    final file = selectedFile.value;
    if (file == null || file.bytes == null) {
      AppLogger.warning('UPLOAD_CTRL', '⚠️ [COMPRESS SKIP] Selected file or bytes are null');
      return;
    }
    if (!FileCompressor.isCompressible(file.name)) {
      AppLogger.info('UPLOAD_CTRL', 'ℹ️ [COMPRESS SKIP] File ${file.name} is not a PDF or image');
      compressionResult.value = null;
      compressionError.value = '';
      return;
    }

    isCompressing.value = true;
    compressionError.value = '';
    compressionProgress.value = 0.15;
    compressionProgressText.value =
        'Connecting to King Technology Media Engine...';

    final stopwatch = Stopwatch()..start();
    try {
      final isPdf = FileCompressor.isPdf(file.name);
      AppLogger.info(
        'UPLOAD_CTRL',
        '┌──────────────────────────────────────────────────────────────────\n'
        '│ ⚙️ [UPLOAD_CTRL] Dispatched to Media Engine API\n'
        '│ 📄 File: ${file.name}\n'
        '│ 📦 File Size: ${file.bytes!.length} bytes (${CompressionResult.formatFileSize(file.bytes!.length)})\n'
        '│ 🏷️ Type: ${isPdf ? "PDF Document" : "Image"}\n'
        '│ 🎛️ Target Quality: ${compressionQuality.value}%\n'
        '└──────────────────────────────────────────────────────────────────',
      );

      final result = await FileCompressor.compressFile(
        bytes: file.bytes!,
        fileName: file.name,
        quality: compressionQuality.value,
        onProgress: (progress, message) {
          compressionProgress.value = progress;
          compressionProgressText.value = message;
          AppLogger.debug('UPLOAD_CTRL', '⏳ [PROGRESS ${(progress * 100).toInt()}%] $message');
        },
      );

      lastCompressedQuality.value = compressionQuality.value;
      compressionProgress.value = 1.0;
      if (result != null && result.hasSizeReduction) {
        compressionProgressText.value =
            'Optimization complete! Saved ${result.savingsPercent.toStringAsFixed(1)}%';
        useCompressed.value = true;
        AppLogger.info(
          'UPLOAD_CTRL',
          '🎉 [COMPRESSION SUCCESS] Optimized in ${stopwatch.elapsedMilliseconds}ms. '
          'Original: ${result.originalSizeFormatted} -> Compressed: ${result.compressedSizeFormatted} '
          '(${result.savingsFormatted})',
        );
      } else {
        compressionProgressText.value =
            'File is already optimal. Original file retained.';
        AppLogger.info(
          'UPLOAD_CTRL',
          'ℹ️ [COMPRESSION OPTIMAL] File is already at minimal size in ${stopwatch.elapsedMilliseconds}ms. Original file will be used.',
        );
      }

      compressionResult.value = result;
    } catch (e, st) {
      AppLogger.error(
        'UPLOAD_CTRL',
        '❌ [UPLOAD_CTRL COMPRESS ERROR] Failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        error: e,
        stackTrace: st,
      );
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      compressionError.value = cleanMsg;
      compressionProgressText.value = 'API Compression issue. Original file will be used.';
    } finally {
      isCompressing.value = false;
    }
  }

  void setCompressionPreset(String level) {
    if (compressionPreset.value == level) return;
    AppLogger.info('UPLOAD_CTRL', '🎚️ [PRESET CHANGED] Compression preset set to "$level"');
    compressionPreset.value = level;
    pdfCompressionLevel.value = level;

    final isPdf = selectedFile.value != null && FileCompressor.isPdf(selectedFile.value!.name);
    if (isPdf) {
      switch (level) {
        case 'recommended':
          pdfQuality.value = 72;
          pdfDpi.value = 150;
          break;
        case 'extreme':
          pdfQuality.value = 45;
          pdfDpi.value = 96;
          break;
        case 'high':
          pdfQuality.value = 60;
          pdfDpi.value = 120;
          break;
        case 'low':
          pdfQuality.value = 85;
          pdfDpi.value = 200;
          break;
        case 'lossless':
          pdfQuality.value = 100;
          break;
      }
    } else {
      switch (level) {
        case 'recommended':
          compressionQuality.value = 75;
          maxDimension.value = 2400;
          maxDimensionController.text = '2400';
          break;
        case 'extreme':
          compressionQuality.value = 40;
          maxDimension.value = 1200;
          maxDimensionController.text = '1200';
          break;
        case 'high':
          compressionQuality.value = 55;
          maxDimension.value = 1800;
          maxDimensionController.text = '1800';
          break;
        case 'low':
          compressionQuality.value = 85;
          maxDimension.value = 3200;
          maxDimensionController.text = '3200';
          break;
        case 'lossless':
          compressionQuality.value = 100;
          maxDimension.value = null;
          maxDimensionController.clear();
          break;
      }
    }

    if (useCompressed.value) {
      compressSelectedFile();
    }
  }

  void setCompressionQuality(int quality) {
    if (compressionQuality.value == quality) return;
    AppLogger.info('UPLOAD_CTRL', '🎚️ [QUALITY CHANGED] Compression quality set to $quality%');
    compressionQuality.value = quality;
    pdfQuality.value = quality;
  }

  void setPdfQuality(int quality) {
    setCompressionQuality(quality);
  }

  void applyQualityAndRecompress(int quality) {
    setCompressionQuality(quality);
    compressSelectedFile();
  }

  void setPdfDpi(int dpi) {
    if (pdfDpi.value == dpi) return;
    AppLogger.info('UPLOAD_CTRL', '🎚️ [PDF DPI CHANGED] PDF DPI set to $dpi');
    pdfDpi.value = dpi;
    if (compressionPreset.value != 'custom') {
      compressionPreset.value = 'custom';
    }
    if (useCompressed.value) {
      compressSelectedFile();
    }
  }

  void setPdfCompressionLevel(String level) {
    setCompressionPreset(level);
  }

  void toggleGrayscale(bool val) {
    if (isGrayscale.value == val) return;
    AppLogger.info('UPLOAD_CTRL', '🎨 [GRAYSCALE CHANGED] Grayscale set to $val');
    isGrayscale.value = val;
    if (useCompressed.value) {
      compressSelectedFile();
    }
  }

  void toggleStripMetadata(bool val) {
    if (stripMetadata.value == val) return;
    AppLogger.info('UPLOAD_CTRL', '🧹 [STRIP METADATA CHANGED] Strip metadata set to $val');
    stripMetadata.value = val;
    if (useCompressed.value) {
      compressSelectedFile();
    }
  }

  void toggleAdvancedSettings() {
    showAdvancedSettings.value = !showAdvancedSettings.value;
  }

  void setTargetSizeKb(int? kb) {
    if (targetSizeKb.value == kb) return;
    targetSizeKb.value = kb;
    if (kb != null) {
      targetSizeController.text = kb.toString();
    } else {
      targetSizeController.clear();
    }
    if (useCompressed.value) {
      compressSelectedFile();
    }
  }

  void setMaxDimension(int? dim) {
    if (maxDimension.value == dim) return;
    maxDimension.value = dim;
    if (dim != null) {
      maxDimensionController.text = dim.toString();
    } else {
      maxDimensionController.clear();
    }
    if (useCompressed.value) {
      compressSelectedFile();
    }
  }

  Future<void> recompressFile() async {
    AppLogger.info(
      'UPLOAD_CTRL',
      '🔄 [RE-COMPRESS TRIGGERED] User requested 2nd/repeat compression via Media Engine API...',
    );
    useCompressed.value = true;
    await compressSelectedFile();
  }

  void onFileSelected(PlatformFile file) {
    useCompressed.value = false; // Always default to Original Quality on any file selection
    compressionPreset.value = 'recommended';
    pdfCompressionLevel.value = 'recommended';
    compressionQuality.value = 75;
    lastCompressedQuality.value = 75;
    pdfQuality.value = 72;
    pdfDpi.value = 150;
    maxDimension.value = null;
    targetSizeKb.value = null;
    targetSizeController.clear();
    maxDimensionController.clear();
    isGrayscale.value = false;
    stripMetadata.value = true;
    showAdvancedSettings.value = false;
    AppLogger.info(
      'UPLOAD_CTRL',
      '┌──────────────────────────────────────────────────────────────────\n'
      '│ 📁 [FILE SELECTED IN DROPZONE]\n'
      '│ 📄 Name: ${file.name}\n'
      '│ ⚖️ Size: ${file.size} bytes (${CompressionResult.formatFileSize(file.size)})\n'
      '│ 🔍 Compressible: ${FileCompressor.isCompressible(file.name)}\n'
      '│ 🔘 Current Mode: ORIGINAL (Defaulted on file select)\n'
      '└──────────────────────────────────────────────────────────────────',
    );
    selectedFile.value = file;
    compressionResult.value = null;
    compressionError.value = '';
    formErrorMessage.value = '';

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

    AppLogger.info(
      'UPLOAD_CTRL',
      'ℹ️ [COMPRESS SKIPPED] Defaulted to Original Quality mode; skipping compression API until user selects Compressed.',
    );
  }

  void addApplianceItem({String? name, String? brand, String? category}) {
    final defaultCat = category ??
        (dynamicApplianceSubcategories.isNotEmpty
            ? dynamicApplianceSubcategories.first
            : 'Ceiling / Table Fans');
    final defaultBrand = brand ??
        (dynamicBrands.isNotEmpty ? dynamicBrands.first : 'Havells');

    final item = ApplianceItemFormState(
      initialName: name,
      initialCategory: defaultCat,
      initialBrand: defaultBrand,
      initialValidUpto: purchaseDate.value.add(const Duration(days: 365)),
    );
    applianceItems.add(item);
  }

  void removeApplianceItem(int index) {
    if (applianceItems.length > 1 &&
        index >= 0 &&
        index < applianceItems.length) {
      final removed = applianceItems.removeAt(index);
      removed.dispose();
    }
  }

  void updateItemWarrantyMonths(int index, int months) {
    if (index >= 0 && index < applianceItems.length) {
      applianceItems[index].updateWarrantyMonths(months, purchaseDate.value);
    }
  }

  void toggleItemWarrantyCoverage(int index, bool hasWarranty) {
    if (index >= 0 && index < applianceItems.length) {
      applianceItems[index].toggleWarrantyCoverage(
        hasWarranty,
        purchaseDate.value,
      );
    }
  }

  void onPurchaseDateChanged(DateTime newDate) {
    purchaseDate.value = newDate;
    for (var item in applianceItems) {
      item.onPurchaseDateChanged(newDate);
    }
  }

  Future<void> submitUpload() async {
    formErrorMessage.value = '';
    final file = selectedFile.value;
    if (file == null) {
      formErrorMessage.value =
          'Please select or drag-and-drop a document file to upload.';
      return;
    }

    if (file.bytes == null) {
      formErrorMessage.value =
          'Could not read file binary data. Please try selecting the file again.';
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
        formErrorMessage.value = 'Please enter a descriptive document title.';
        return;
      }
    }

    isSubmitting.value = true;
    AppLogger.info(
      'UPLOAD_CTRL',
      'Starting secure document upload for: $title (${file.name})',
    );

    try {
      final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';

      // 1. Prepare Address Metadata (Only if city filter is enabled for this category)
      AddressModel? address;
      if (showCityFilter &&
          (selectedCity.value.isNotEmpty ||
              areaLocalityController.text.isNotEmpty)) {
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
          state: stateController.text.trim().isNotEmpty
              ? stateController.text.trim()
              : 'Gujarat',
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
          paymentDate: utilityPaymentStatus.value == 'paid'
              ? DateTime.now()
              : null,
        );
      }

      ApplianceWarrantyModel? applianceMeta;
      if (isApplianceWarranty) {
        final List<ApplianceItemModel> items = [];
        double computedTotal = 0.0;

        for (var item in applianceItems) {
          final iBrand = item.selectedBrand.value == 'Other' &&
                  item.customBrandController.text.isNotEmpty
              ? item.customBrandController.text.trim()
              : item.selectedBrand.value;
          final iAmount =
              double.tryParse(item.purchaseAmountController.text.trim()) ?? 0.0;
          computedTotal += iAmount;
          final iHasCov =
              item.hasWarrantyCoverage.value && item.warrantyMonths.value > 0;
          final iName = item.productNameController.text.trim().isNotEmpty
              ? item.productNameController.text.trim()
              : '$iBrand ${item.selectedCategory.value}';

          items.add(
            ApplianceItemModel(
              id: item.id,
              productName: iName,
              productCategory: item.selectedCategory.value,
              brand: iBrand,
              modelNumber: item.modelNumberController.text.trim().isNotEmpty
                  ? item.modelNumberController.text.trim()
                  : null,
              serialNumber: item.serialNumberController.text.trim().isNotEmpty
                  ? item.serialNumberController.text.trim()
                  : null,
              purchaseAmount: iAmount,
              warrantyPeriodMonths: iHasCov ? item.warrantyMonths.value : 0,
              warrantyValidUpto: iHasCov
                  ? item.warrantyValidUpto.value
                  : purchaseDate.value,
              customerCareNumber:
                  item.customerCareNumberController.text.trim().isNotEmpty
                  ? item.customerCareNumberController.text.trim()
                  : null,
              warrantyStatus: iHasCov ? 'active' : 'no_warranty',
            ),
          );
        }

        final explicitTotal =
            double.tryParse(purchaseAmountController.text.trim());
        final totalAmount =
            (explicitTotal != null && explicitTotal > 0)
                ? explicitTotal
                : computedTotal;

        applianceMeta = ApplianceWarrantyModel(
          items: items,
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
          purchaseAmount: totalAmount,
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
          issuingAuthority:
              personalIssuingAuthorityController.text.trim().isNotEmpty
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

      if (useCompressed.value && compressionResult.value != null && compressionResult.value!.hasSizeReduction) {
        uploadBytes = compressionResult.value!.compressedBytes;
        uploadFileName = compressionResult.value!.compressedFileName;
        uploadMimeType = compressionResult.value!.mimeType;
        AppLogger.info(
          'UPLOAD_CTRL',
          '┌──────────────────────────────────────────────────────────────────\n'
          '│ 🚀 [UPLOADING TO VAULT: COMPRESSED]\n'
          '│ 📄 File Name: $uploadFileName\n'
          '│ 📦 Compressed Size: ${uploadBytes.length} bytes (${CompressionResult.formatFileSize(uploadBytes.length)})\n'
          '│ ⚖️ Original Size: ${file.bytes!.length} bytes (${CompressionResult.formatFileSize(file.bytes!.length)})\n'
          '│ 🔥 Bandwidth Saved: ${compressionResult.value!.savingsFormatted}\n'
          '│ 🏷️ MIME Type: $uploadMimeType\n'
          '└──────────────────────────────────────────────────────────────────',
        );
      } else {
        AppLogger.info(
          'UPLOAD_CTRL',
          '┌──────────────────────────────────────────────────────────────────\n'
          '│ 🚀 [UPLOADING TO VAULT: ORIGINAL QUALITY]\n'
          '│ 📄 File Name: $uploadFileName\n'
          '│ 📦 Size: ${uploadBytes.length} bytes (${CompressionResult.formatFileSize(uploadBytes.length)})\n'
          '│ 🏷️ MIME Type: $uploadMimeType\n'
          '│ ℹ️ Compression: Skipped (Original Quality selected)\n'
          '└──────────────────────────────────────────────────────────────────',
        );
      }

      // 3. Create Document Record via DocumentsDataset
      final createdDoc = await _documentsDataset.createDocument(
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

      AppLogger.info(
        'UPLOAD_CTRL',
        'Document successfully created in Vault! ID: ${createdDoc.id}',
      );

      // Section 3.B: Navigate away first, then trigger standardized compact success snackbar
      if (isPersonalDoc) {
        Get.offNamed(AppRoutes.PERSONAL_DOCS);
      } else if (isUtilityBill) {
        Get.offNamed(AppRoutes.UTILITY_BILLS);
      } else if (isApplianceWarranty) {
        Get.offNamed(AppRoutes.APPLIANCES);
      } else {
        Get.offNamed(AppRoutes.DOCUMENTS);
      }

      AppSnackbar.showSuccess(
        'Upload Successful',
        'Document "${createdDoc.title}" stored securely in ${AppConstants.appName}.',
      );
    } catch (e, st) {
      AppLogger.error(
        'UPLOAD_CTRL',
        'Fatal error during document upload: $e',
        error: e,
        stackTrace: st,
      );
      // Section 3.B: Render inline error in form instead of floating snackbar
      formErrorMessage.value =
          'Upload failed: ${e.toString().replaceAll('Exception: ', '')}';
    } finally {
      isSubmitting.value = false;
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
    billingNameController.dispose();
    storeVendorNameController.dispose();
    invoiceNumberController.dispose();
    purchaseAmountController.dispose();
    for (var item in applianceItems) {
      item.dispose();
    }
    personalIdNumberController.dispose();
    personalIssuingAuthorityController.dispose();
    personalNotesController.dispose();
    targetSizeController.dispose();
    maxDimensionController.dispose();
    super.onClose();
  }
}
