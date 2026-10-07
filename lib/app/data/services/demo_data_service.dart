import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/dashboard_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/activity_log_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/address_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/category_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/dashboard_metrics_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/folder_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_metadata_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/services/auth_service.dart';

class DemoDataService {
  DemoDataService._();

  static bool get isDemoMode {
    if (!Get.isRegistered<AuthService>()) return false;
    return AuthService.to.isDemoMode.value;
  }

  // --- Master Categories ---
  static List<CategoryModel> getCategories() {
    return [
      CategoryModel(
        id: 'cat-utility',
        name: 'Utility Bills',
        code: 'utility_bills',
        icon: 'bolt',
        colorHex: '#F59E0B',
        description: 'Light, Gas, Water, Broadband bills & receipts',
        hasCityFilter: true,
        hasTitleField: false,
      ),
      CategoryModel(
        id: 'cat-appliance',
        name: 'Appliance & Asset Invoices',
        code: 'appliance_warranty',
        icon: 'shield',
        colorHex: '#10B981',
        description: 'Appliance warranty cards, product manuals & purchase invoices',
        hasCityFilter: true,
        hasTitleField: true,
      ),
      CategoryModel(
        id: 'cat-personal',
        name: 'Personal & Identity',
        code: 'identity_docs',
        icon: 'badge',
        colorHex: '#8B5CF6',
        description: 'Aadhaar, PAN, Passport, Driving License, Voter ID & KYC records',
        hasCityFilter: false,
        hasTitleField: true,
      ),
      CategoryModel(
        id: 'cat-vehicle',
        name: 'Vehicle Vault',
        code: 'vehicle_docs',
        icon: 'directions_car',
        colorHex: '#3B82F6',
        description: 'RC Book, Insurance, PUC, Fitness, Service bills & FASTag passes',
        hasCityFilter: false,
        hasTitleField: true,
      ),
    ];
  }

  // --- Master Folders ---
  static List<FolderModel> getFolders() {
    final now = DateTime.now();
    return [
      FolderModel(
        id: 'fld-1',
        name: 'Ahmedabad Headquarters',
        description: 'Utility bills and corporate warranties for Ahmedabad HQ',
        color: '#3B82F6',
        documentCount: 18,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      FolderModel(
        id: 'fld-2',
        name: 'Family Identity & KYC',
        description: 'Personal documents, IDs, and passports',
        color: '#8B5CF6',
        documentCount: 8,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      FolderModel(
        id: 'fld-3',
        name: 'Home Appliances & Warranty',
        description: 'Air conditioners, refrigerators, washing machines and electronics',
        color: '#10B981',
        documentCount: 12,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      FolderModel(
        id: 'fld-4',
        name: 'Fleet & Vehicle Docs',
        description: 'Vehicle RC books, insurance policies and toll passes',
        color: '#F59E0B',
        documentCount: 6,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
    ];
  }

  // --- Master Cities ---
  static List<MasterCityModel> getCities() {
    return [
      MasterCityModel(id: 'c-1', name: 'Ahmedabad', state: 'Gujarat'),
      MasterCityModel(id: 'c-2', name: 'Surat', state: 'Gujarat'),
      MasterCityModel(id: 'c-3', name: 'Vadodara', state: 'Gujarat'),
      MasterCityModel(id: 'c-4', name: 'Rajkot', state: 'Gujarat'),
      MasterCityModel(id: 'c-5', name: 'Gandhinagar', state: 'Gujarat'),
      MasterCityModel(id: 'c-6', name: 'Mumbai', state: 'Maharashtra'),
      MasterCityModel(id: 'c-7', name: 'Pune', state: 'Maharashtra'),
      MasterCityModel(id: 'c-8', name: 'Bangalore', state: 'Karnataka'),
      MasterCityModel(id: 'c-9', name: 'Delhi NCR', state: 'Delhi'),
    ];
  }

  // --- Master Brands ---
  static List<MasterBrandModel> getBrands() {
    return [
      MasterBrandModel(id: 'b-1', name: 'Samsung'),
      MasterBrandModel(id: 'b-2', name: 'LG'),
      MasterBrandModel(id: 'b-3', name: 'Daikin'),
      MasterBrandModel(id: 'b-4', name: 'Voltas'),
      MasterBrandModel(id: 'b-5', name: 'Havells'),
      MasterBrandModel(id: 'b-6', name: 'Crompton'),
      MasterBrandModel(id: 'b-7', name: 'Philips'),
      MasterBrandModel(id: 'b-8', name: 'Apple'),
      MasterBrandModel(id: 'b-9', name: 'Sony'),
      MasterBrandModel(id: 'b-10', name: 'Dell'),
      MasterBrandModel(id: 'b-11', name: 'HP'),
      MasterBrandModel(id: 'b-12', name: 'Generic'),
    ];
  }

  // --- Master Appliance Subcategories ---
  static List<MasterApplianceSubcategoryModel> getApplianceSubcategories() {
    return [
      MasterApplianceSubcategoryModel(id: 'as-1', name: 'Air Conditioner', defaultWarrantyMonths: 24),
      MasterApplianceSubcategoryModel(id: 'as-2', name: 'Refrigerator', defaultWarrantyMonths: 36),
      MasterApplianceSubcategoryModel(id: 'as-3', name: 'Washing Machine', defaultWarrantyMonths: 24),
      MasterApplianceSubcategoryModel(id: 'as-4', name: 'Ceiling Fan', defaultWarrantyMonths: 24),
      MasterApplianceSubcategoryModel(id: 'as-5', name: 'Geyser / Water Heater', defaultWarrantyMonths: 24),
      MasterApplianceSubcategoryModel(id: 'as-6', name: 'Laptop / Computer', defaultWarrantyMonths: 12),
      MasterApplianceSubcategoryModel(id: 'as-7', name: 'Television / Smart TV', defaultWarrantyMonths: 12),
    ];
  }

  // --- Master Utility Providers ---
  static List<MasterUtilityProviderModel> getUtilityProviders() {
    return [
      MasterUtilityProviderModel(id: 'up-1', name: 'Torrent Power', utilityType: 'Electricity / Light'),
      MasterUtilityProviderModel(id: 'up-2', name: 'UGVCL (Uttar Gujarat Vij Company)', utilityType: 'Electricity / Light'),
      MasterUtilityProviderModel(id: 'up-3', name: 'Adani Electricity', utilityType: 'Electricity / Light'),
      MasterUtilityProviderModel(id: 'up-4', name: 'Tata Power', utilityType: 'Electricity / Light'),
      MasterUtilityProviderModel(id: 'up-5', name: 'Gujarat Gas', utilityType: 'Piped Natural Gas (PNG)'),
      MasterUtilityProviderModel(id: 'up-6', name: 'Adani Total Gas', utilityType: 'Piped Natural Gas (PNG)'),
      MasterUtilityProviderModel(id: 'up-7', name: 'Ahmedabad Municipal Corporation (AMC)', utilityType: 'Water Tax / Municipal Bills'),
      MasterUtilityProviderModel(id: 'up-8', name: 'JioFiber / AirFiber', utilityType: 'Broadband / Internet'),
      MasterUtilityProviderModel(id: 'up-9', name: 'Airtel Xstream Fiber', utilityType: 'Broadband / Internet'),
    ];
  }

  // --- Master Persons ---
  static List<MasterPersonModel> getPersons() {
    final now = DateTime.now();
    return [
      MasterPersonModel(
        id: 'p-1',
        fullName: 'Mihir Gandhi',
        relationship: 'Self',
        phoneNumber: '+91 98765 43210',
        email: 'mihir@kingtechnology.com',
        createdAt: now.subtract(const Duration(days: 100)),
        updatedAt: now,
      ),
      MasterPersonModel(
        id: 'p-2',
        fullName: 'Darshit Gandhi',
        relationship: 'Brother',
        phoneNumber: '+91 98765 43211',
        email: 'darshit@kingtechnology.com',
        createdAt: now.subtract(const Duration(days: 100)),
        updatedAt: now,
      ),
      MasterPersonModel(
        id: 'p-3',
        fullName: 'Rajesh Gandhi',
        relationship: 'Father',
        phoneNumber: '+91 98765 43212',
        createdAt: now.subtract(const Duration(days: 100)),
        updatedAt: now,
      ),
      MasterPersonModel(
        id: 'p-4',
        fullName: 'Geeta Gandhi',
        relationship: 'Mother',
        createdAt: now.subtract(const Duration(days: 100)),
        updatedAt: now,
      ),
    ];
  }

  // --- Master Personal Doc Types ---
  static List<MasterPersonalDocTypeModel> getPersonalDocTypes() {
    final now = DateTime.now();
    return [
      MasterPersonalDocTypeModel(id: 'dt-1', name: 'Aadhaar Card', code: 'aadhaar_card', hasExpiry: false, createdAt: now),
      MasterPersonalDocTypeModel(id: 'dt-2', name: 'PAN Card', code: 'pan_card', hasExpiry: false, createdAt: now),
      MasterPersonalDocTypeModel(id: 'dt-3', name: 'Passport', code: 'passport', hasExpiry: true, createdAt: now),
      MasterPersonalDocTypeModel(id: 'dt-4', name: 'Driving License', code: 'driving_license', hasExpiry: true, createdAt: now),
      MasterPersonalDocTypeModel(id: 'dt-5', name: 'Chutni Card (Voter ID)', code: 'voter_id', hasExpiry: false, createdAt: now),
    ];
  }

  // --- Master Vehicles ---
  static List<MasterVehicleModel> getVehicles() {
    final now = DateTime.now();
    return [
      MasterVehicleModel(
        id: 'v-1',
        vehicleNumber: 'GJ-01-AB-1234',
        nickname: 'Office Innova Hycross',
        brandMake: 'Toyota',
        modelName: 'Innova Hycross ZX',
        vehicleType: 'Four Wheeler',
        fuelType: 'Hybrid Petrol',
        ownerName: 'King Technology Pvt Ltd',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      MasterVehicleModel(
        id: 'v-2',
        vehicleNumber: 'GJ-01-CD-5678',
        nickname: 'Hyundai Creta SX(O)',
        brandMake: 'Hyundai',
        modelName: 'Creta SX(O)',
        vehicleType: 'Four Wheeler',
        fuelType: 'Petrol',
        ownerName: 'Mihir Gandhi',
        createdAt: now.subtract(const Duration(days: 80)),
        updatedAt: now,
      ),
      MasterVehicleModel(
        id: 'v-3',
        vehicleNumber: 'GJ-27-EF-9012',
        nickname: 'Tata Nexon EV Max',
        brandMake: 'Tata',
        modelName: 'Nexon EV Empowered',
        vehicleType: 'Electric Vehicle',
        fuelType: 'Electric',
        ownerName: 'King Technology Pvt Ltd',
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now,
      ),
    ];
  }

  // --- Master Vehicle Doc Types ---
  static List<MasterVehicleDocTypeModel> getVehicleDocTypes() {
    final now = DateTime.now();
    return [
      MasterVehicleDocTypeModel(id: 'vdt-1', name: 'RC Book (Registration Certificate)', code: 'rc_book', hasExpiry: false, createdAt: now),
      MasterVehicleDocTypeModel(id: 'vdt-2', name: 'Insurance Policy', code: 'insurance', hasExpiry: true, createdAt: now),
      MasterVehicleDocTypeModel(id: 'vdt-3', name: 'PUC Certificate', code: 'puc', hasExpiry: true, createdAt: now),
      MasterVehicleDocTypeModel(id: 'vdt-4', name: 'Fastag / Toll Pass', code: 'fastag', hasExpiry: true, createdAt: now),
      MasterVehicleDocTypeModel(id: 'vdt-5', name: 'Service & Maintenance Bill', code: 'service_bill', hasExpiry: false, createdAt: now),
    ];
  }

  // --- Mock Documents ---
  static List<DocumentModel>? _cachedMockDocuments;

  static List<DocumentModel> getAllDocuments() {
    if (_cachedMockDocuments != null) return _cachedMockDocuments!;
    final now = DateTime.now();
    _cachedMockDocuments = [
      // 0. Google Drive Document
      DocumentModel(
        id: 'doc-gdrive-1',
        title: 'Office Lease Agreement & Floor Plan (Google Drive)',
        description: 'Corporate commercial property lease contract stored in Google Drive',
        categoryId: 'cat-utility',
        categoryName: 'Corporate Vault',
        categoryCode: 'corporate_docs',
        subCategory: 'Contracts & Agreements',
        folderId: 'fld-1',
        folderName: 'Ahmedabad Headquarters',
        fileName: 'Lease_Agreement_FloorPlan.pdf',
        filePath: 'https://drive.google.com/file/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OIvE2up08/view',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 524288,
        documentNumber: 'KT-GDRIVE-2026-01',
        status: 'active',
        isFavorite: true,
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        address: AddressModel(
          premiseName: 'King Technology Tower',
          flatHouseNo: 'Level 4',
          buildingName: 'Titanium Square',
          areaLocality: 'SG Highway',
          city: 'Ahmedabad',
          state: 'Gujarat',
          postalCode: '380054',
        ),
      ),
      // 1. Utility Bill - Torrent Power
      DocumentModel(
        id: 'doc-1',
        title: 'Torrent Power Bill - Oct 2026',
        description: 'Electricity bill for Corporate Office, SG Highway Ahmedabad',
        categoryId: 'cat-utility',
        categoryName: 'Utility Bills',
        categoryCode: 'utility_bills',
        subCategory: 'Electricity / Light',
        folderId: 'fld-1',
        folderName: 'Ahmedabad Headquarters',
        fileName: 'Torrent_Power_Oct2026.pdf',
        filePath: 'mock/torrent_power_oct2026.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 412500,
        documentNumber: 'TP-AHM-98421',
        status: 'active',
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        address: AddressModel(
          premiseName: 'King Technology Tower',
          flatHouseNo: 'Level 4',
          buildingName: 'Titanium Square',
          areaLocality: 'SG Highway, Thaltej',
          city: 'Ahmedabad',
          state: 'Gujarat',
          postalCode: '380054',
        ),
        utilityMetadata: UtilityMetadataModel(
          utilityType: 'Electricity / Light',
          providerName: 'Torrent Power',
          consumerNumber: 'TP-100294821',
          meterNumber: 'MTR-884920',
          billAmount: 14850.00,
          billDate: now.subtract(const Duration(days: 5)),
          dueDate: now.add(const Duration(days: 10)),
          paymentStatus: 'pending',
        ),
      ),

      // 2. Utility Bill - Gujarat Gas
      DocumentModel(
        id: 'doc-2',
        title: 'Gujarat Gas PNG Bill - Sep 2026',
        description: 'Piped Gas bill for Corporate Pantry & Cafeteria',
        categoryId: 'cat-utility',
        categoryName: 'Utility Bills',
        categoryCode: 'utility_bills',
        subCategory: 'Piped Natural Gas (PNG)',
        folderId: 'fld-1',
        folderName: 'Ahmedabad Headquarters',
        fileName: 'Gujarat_Gas_Sep2026.pdf',
        filePath: 'mock/gujarat_gas_sep2026.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 285000,
        documentNumber: 'GG-3948201',
        status: 'active',
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 12)),
        address: AddressModel(
          premiseName: 'King Technology Tower',
          areaLocality: 'SG Highway',
          city: 'Ahmedabad',
          state: 'Gujarat',
          postalCode: '380054',
        ),
        utilityMetadata: UtilityMetadataModel(
          utilityType: 'Piped Natural Gas (PNG)',
          providerName: 'Gujarat Gas',
          consumerNumber: 'GG-77492019',
          billAmount: 2450.00,
          billDate: now.subtract(const Duration(days: 15)),
          dueDate: now.add(const Duration(days: 4)),
          paymentStatus: 'pending',
        ),
      ),

      // 3. Appliance Warranty - Daikin Air Conditioner
      DocumentModel(
        id: 'doc-3',
        title: 'Daikin 2.0 Ton Inverter AC Invoice & Warranty',
        description: 'Server Room high-efficiency AC with 5-year comprehensive PCB & compressor warranty',
        categoryId: 'cat-appliance',
        categoryName: 'Appliance & Asset Invoices',
        categoryCode: 'appliance_warranty',
        subCategory: 'Air Conditioner',
        folderId: 'fld-3',
        folderName: 'Home Appliances & Warranty',
        fileName: 'Daikin_AC_Invoice.pdf',
        filePath: 'mock/daikin_ac.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 1048576,
        documentNumber: 'INV-DAIKIN-88912',
        status: 'active',
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 45)),
        applianceWarranty: ApplianceWarrantyModel(
          billingName: 'King Technology Pvt Ltd',
          storeVendorName: 'Vijay Sales Thaltej',
          invoiceNumber: 'INV-DAIKIN-88912',
          purchaseDate: now.subtract(const Duration(days: 45)),
          purchaseAmount: 58900.00,
          items: [
            ApplianceItemModel(
              id: 'item-ac-1',
              productName: 'Daikin 2.0 Ton 5 Star Inverter AC',
              productCategory: 'Air Conditioner',
              brand: 'Daikin',
              modelNumber: 'FTKM60TV',
              serialNumber: 'DKN-2024-99812A',
              purchaseAmount: 58900.00,
              warrantyPeriodMonths: 24,
              warrantyValidUpto: now.add(const Duration(days: 20)), // Expiring soon in demo
              warrantyStatus: 'active',
              customerCareNumber: '1800 102 9300',
            ),
          ],
        ),
      ),

      // 4. Appliance Warranty - Samsung Double Door Refrigerator
      DocumentModel(
        id: 'doc-4',
        title: 'Samsung 415L Double Door Refrigerator Invoice',
        description: 'Office Cafeteria Frost Free Inverter Refrigerator with digital display',
        categoryId: 'cat-appliance',
        categoryName: 'Appliance & Asset Invoices',
        categoryCode: 'appliance_warranty',
        subCategory: 'Refrigerator',
        folderId: 'fld-3',
        folderName: 'Home Appliances & Warranty',
        fileName: 'Samsung_Fridge_Invoice.pdf',
        filePath: 'mock/samsung_fridge.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 892000,
        documentNumber: 'INV-SAM-44912',
        status: 'active',
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 120)),
        applianceWarranty: ApplianceWarrantyModel(
          billingName: 'King Technology Pvt Ltd',
          storeVendorName: 'Croma SG Highway',
          invoiceNumber: 'INV-SAM-44912',
          purchaseDate: now.subtract(const Duration(days: 120)),
          purchaseAmount: 46500.00,
          items: [
            ApplianceItemModel(
              id: 'item-ref-1',
              productName: 'Samsung 415L Convertible 5in1 Refrigerator',
              productCategory: 'Refrigerator',
              brand: 'Samsung',
              modelNumber: 'RT45K6258S8',
              serialNumber: 'SAM-RF-8829104',
              purchaseAmount: 46500.00,
              warrantyPeriodMonths: 36,
              warrantyValidUpto: now.add(const Duration(days: 900)),
              warrantyStatus: 'active',
              customerCareNumber: '1800 40 7267864',
            ),
          ],
        ),
      ),

      // 5. Personal Identity - Aadhaar Card
      DocumentModel(
        id: 'doc-5',
        title: 'Aadhaar Card - Mihir Gandhi',
        description: 'Official Government of India Aadhaar identity card with UIDAI QR verification',
        categoryId: 'cat-personal',
        categoryName: 'Personal & Identity',
        categoryCode: 'identity_docs',
        subCategory: 'Aadhaar Card',
        folderId: 'fld-2',
        folderName: 'Family Identity & KYC',
        fileName: 'Aadhaar_Mihir_Gandhi.pdf',
        filePath: 'mock/aadhaar_mihir.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 520000,
        documentNumber: '9842-1920-8812',
        status: 'active',
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now.subtract(const Duration(days: 200)),
        personalMetadata: PersonalDocumentMetadataModel(
          personId: 'p-1',
          personName: 'Mihir Gandhi',
          docTypeId: 'dt-1',
          docTypeName: 'Aadhaar Card',
          idNumber: '9842 1920 8812',
          issuingAuthority: 'UIDAI',
          issueDate: DateTime(2018, 5, 14),
          notes: 'Masked Aadhaar copy uploaded with biometric lock active',
        ),
      ),

      // 6. Personal Identity - Passport
      DocumentModel(
        id: 'doc-6',
        title: 'Passport - Mihir Gandhi',
        description: 'Republic of India 36-page international passport',
        categoryId: 'cat-personal',
        categoryName: 'Personal & Identity',
        categoryCode: 'identity_docs',
        subCategory: 'Passport',
        folderId: 'fld-2',
        folderName: 'Family Identity & KYC',
        fileName: 'Passport_Mihir_Gandhi.pdf',
        filePath: 'mock/passport_mihir.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 1240000,
        documentNumber: 'Z8920148',
        status: 'active',
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 150)),
        personalMetadata: PersonalDocumentMetadataModel(
          personId: 'p-1',
          personName: 'Mihir Gandhi',
          docTypeId: 'dt-3',
          docTypeName: 'Passport',
          idNumber: 'Z8920148',
          issuingAuthority: 'Regional Passport Office Ahmedabad',
          issueDate: DateTime(2020, 8, 10),
          expiryDate: DateTime(2030, 8, 9),
          notes: 'Valid for international business and visa applications',
        ),
      ),

      // 7. Vehicle Vault - RC Book
      DocumentModel(
        id: 'doc-7',
        title: 'RC Book - Toyota Innova Hycross (GJ-01-AB-1234)',
        description: 'Original Certificate of Registration issued by RTO Ahmedabad Subhash Bridge',
        categoryId: 'cat-vehicle',
        categoryName: 'Vehicle Vault',
        categoryCode: 'vehicle_docs',
        subCategory: 'RC Book (Registration Certificate)',
        folderId: 'fld-4',
        folderName: 'Fleet & Vehicle Docs',
        fileName: 'RC_GJ01AB1234.pdf',
        filePath: 'mock/rc_gj01ab1234.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 760000,
        documentNumber: 'GJ01-2024-RC-99812',
        status: 'active',
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 90)),
        vehicleMetadata: VehicleDocumentMetadataModel(
          vehicleId: 'v-1',
          vehicleNumber: 'GJ-01-AB-1234',
          vehicleName: 'Toyota Innova Hycross ZX (Office Innova Hycross)',
          docTypeId: 'vdt-1',
          docTypeName: 'RC Book (Registration Certificate)',
          policyOrCertNumber: 'GJ01-2024-RC-99812',
          issueDate: DateTime(2024, 1, 15),
          notes: 'Commercial/Private registration with Hypothecation clear',
        ),
      ),

      // 8. Vehicle Vault - Comprehensive Insurance Policy
      DocumentModel(
        id: 'doc-8',
        title: 'HDFC ERGO Zero-Dep Insurance Policy - GJ-01-AB-1234',
        description: 'Comprehensive 1+3 year bumper-to-bumper zero depreciation policy with RSA & engine protect',
        categoryId: 'cat-vehicle',
        categoryName: 'Vehicle Vault',
        categoryCode: 'vehicle_docs',
        subCategory: 'Insurance Policy',
        folderId: 'fld-4',
        folderName: 'Fleet & Vehicle Docs',
        fileName: 'HDFC_Insurance_GJ01AB1234.pdf',
        filePath: 'mock/insurance_gj01ab1234.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 1850000,
        documentNumber: 'HDFC-ERGO-23114920',
        status: 'active',
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
        vehicleMetadata: VehicleDocumentMetadataModel(
          vehicleId: 'v-1',
          vehicleNumber: 'GJ-01-AB-1234',
          vehicleName: 'Toyota Innova Hycross ZX',
          docTypeId: 'vdt-2',
          docTypeName: 'Insurance Policy',
          policyOrCertNumber: 'HDFC-ERGO-23114920',
          insuranceCompany: 'HDFC ERGO General Insurance',
          premiumAmount: 42500.00,
          issueDate: DateTime(2026, 1, 15),
          expiryDate: DateTime(2027, 1, 14),
          notes: 'Includes 24x7 Roadside Assistance and Return-to-Invoice add-on cover',
        ),
      ),
    ];
    return _cachedMockDocuments!;
  }

  // --- Dashboard Bundle ---
  static DashboardBundleModel getDashboardBundle() {
    final docs = getAllDocuments();
    final expiring = docs
        .where((d) => d.categoryCode == 'appliance_warranty')
        .toList();
    final pending = docs
        .where((d) => d.categoryCode == 'utility_bills' && d.utilityMetadata?.paymentStatus == 'pending')
        .toList();

    return DashboardBundleModel(
      metrics: DashboardMetricsModel(
        totalDocuments: 42,
        totalStorageBytes: 1288490188, // ~1.2 GB
        trashCount: 3,
        trashSizeBytes: 14500000,
      ),
      recentDocuments: docs,
      expiringWarranties: expiring,
      pendingUtilityBills: pending,
    );
  }

  // --- Activity Logs ---
  static List<ActivityLogModel> getActivityLogs() {
    final now = DateTime.now();
    return [
      ActivityLogModel(
        id: 'log-1',
        action: 'uploaded',
        userName: 'Mihir Gandhi',
        userEmail: 'mihir@kingtech.com',
        documentTitle: 'Torrent Power Bill - Oct 2026',
        details: {'category': 'Utility Bills', 'file_size': '412 KB', 'role': 'admin'},
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      ActivityLogModel(
        id: 'log-2',
        action: 'viewed',
        userName: 'Darshit Gandhi',
        userEmail: 'darshit@kingtech.com',
        documentTitle: 'Daikin 2.0 Ton Inverter AC Invoice & Warranty',
        details: {'format': 'PDF Viewer', 'role': 'editor'},
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      ActivityLogModel(
        id: 'log-3',
        action: 'updated',
        userName: 'Mihir Gandhi',
        userEmail: 'mihir@kingtech.com',
        documentTitle: 'HDFC ERGO Zero-Dep Insurance Policy - GJ-01-AB-1234',
        details: {'field': 'Expiry Date updated', 'role': 'admin'},
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ActivityLogModel(
        id: 'log-4',
        action: 'downloaded',
        userName: 'Admin System',
        userEmail: 'admin@kingtech.com',
        documentTitle: 'Aadhaar Card - Mihir Gandhi',
        details: {'action': 'Secure temporary link generated', 'role': 'admin'},
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Updates an existing mock document in memory.
  static void updateDocumentMock({
    required String documentId,
    required String title,
    String? description,
    String? documentNumber,
    ApplianceWarrantyModel? applianceWarranty,
    VehicleDocumentMetadataModel? vehicleMetadata,
    String? newFileName,
    int? newFileSize,
    String? newMimeType,
    String? attachmentUrl,
  }) {
    final docs = getAllDocuments();
    final idx = docs.indexWhere((d) => d.id == documentId);
    if (idx != -1) {
      final old = docs[idx];
      docs[idx] = old.copyWith(
        title: title,
        description: description,
        documentNumber: documentNumber,
        applianceWarranty: applianceWarranty,
        vehicleMetadata: vehicleMetadata,
        fileName: newFileName ?? (attachmentUrl != null ? 'Google Drive Document' : old.fileName),
        fileSize: newFileSize ?? old.fileSize,
        mimeType: newMimeType ?? (attachmentUrl != null ? 'application/vnd.google-apps.document' : old.mimeType),
        filePath: attachmentUrl ?? old.filePath,
      );
    }
  }
}
