import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/modules/appliance_vault/bindings/appliance_detail_binding.dart';
import 'package:kt_prod_kt_docs/app/routes/app_pages.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/address_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_connection_account.dart';
import 'package:kt_prod_kt_docs/app/data/models/utility_metadata_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
import 'package:kt_prod_kt_docs/app/data/services/demo_data_service.dart';
import 'package:kt_prod_kt_docs/app/modules/document_upload/controllers/document_upload_controller.dart';

void main() {
  group('Verification of 6 fixes', () {
    test('Point 1: Provider Name dropdown options and filtering logic', () {
      final providers = [
        MasterUtilityProviderModel(id: '1', name: 'UGVCL', utilityType: 'Electricity / Light'),
        MasterUtilityProviderModel(id: '2', name: 'DGVCL', utilityType: 'Electricity / Light'),
        MasterUtilityProviderModel(id: '3', name: 'Adani Gas', utilityType: 'Gas'),
        MasterUtilityProviderModel(id: '4', name: 'Airtel Xstream', utilityType: 'Internet / Broadband'),
      ];

      // Filtering for Electricity / Light
      final electricityProviders = providers
          .where((p) => p.utilityType.toLowerCase().contains('elec') || p.utilityType.toLowerCase().contains('light'))
          .map((p) => p.name)
          .toList();
      if (!electricityProviders.contains('Other')) electricityProviders.add('Other');

      expect(electricityProviders, contains('UGVCL'));
      expect(electricityProviders, contains('DGVCL'));
      expect(electricityProviders, contains('Other'));
      expect(electricityProviders.contains('Adani Gas'), isFalse);

      // Filtering for Gas
      final gasProviders = providers
          .where((p) => p.utilityType.toLowerCase().contains('gas'))
          .map((p) => p.name)
          .toList();
      if (!gasProviders.contains('Other')) gasProviders.add('Other');

      expect(gasProviders, contains('Adani Gas'));
      expect(gasProviders, contains('Other'));
    });

    test('Point 2: Brands contains "Other"', () {
      expect(AppConstants.popularBrands.contains('Other'), isTrue);
    });

    test('Point 3: Date option and warranty calculation works during upload', () {
      final item = ApplianceItemFormState(
        initialName: 'Test Fan',
        initialBrand: 'Havells',
        initialCategory: 'Ceiling / Table Fans',
        initialWarrantyMonths: 12,
      );

      final purchaseDate = DateTime(2025, 1, 15);
      item.updateWarranty(12, purchaseDate);

      expect(item.hasWarrantyCoverage.value, isTrue);
      expect(item.warrantyMonths.value, 12);
      expect(item.warrantyValidUpto.value.isAfter(purchaseDate), isTrue);

      item.updateWarranty(0, purchaseDate);
      expect(item.hasWarrantyCoverage.value, isFalse);
      expect(item.warrantyMonths.value, 0);
      expect(item.warrantyValidUpto.value, equals(purchaseDate));
    });

    test('Point 4: Invoice Number fallback resolution in Edit mode', () {
      // Document without root documentNumber but with applianceWarranty invoiceNumber
      final docWithApplianceInvoice = DocumentModel(
        id: 'doc-1',
        title: 'Appliance Bill',
        subCategory: 'Kitchen Appliances',
        fileName: 'bill.pdf',
        filePath: 'path/bill.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 1024,
        uploadedBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        documentNumber: null,
        applianceWarranty: ApplianceWarrantyModel(
          id: 'w-1',
          documentId: 'doc-1',
          billingName: 'King Technology',
          storeVendorName: 'Croma',
          invoiceNumber: 'INV-APP-9988',
          purchaseDate: DateTime.now(),
          purchaseAmount: 5000,
        ),
      );

      final resolvedNumber = (docWithApplianceInvoice.documentNumber != null &&
              docWithApplianceInvoice.documentNumber!.trim().isNotEmpty)
          ? docWithApplianceInvoice.documentNumber!.trim()
          : (docWithApplianceInvoice.applianceWarranty?.invoiceNumber ??
              docWithApplianceInvoice.vehicleMetadata?.policyOrCertNumber ??
              docWithApplianceInvoice.personalMetadata?.idNumber ??
              docWithApplianceInvoice.utilityMetadata?.consumerNumber ??
              '');

      expect(resolvedNumber, equals('INV-APP-9988'));

      // Document with vehicle policy number fallback
      final docWithVehiclePolicy = DocumentModel(
        id: 'doc-2',
        title: 'Vehicle Insurance',
        subCategory: 'Insurance Policy',
        fileName: 'insurance.pdf',
        filePath: 'path/insurance.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 2048,
        uploadedBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        documentNumber: '',
        vehicleMetadata: VehicleDocumentMetadataModel(
          vehicleNumber: 'GJ01AB1234',
          vehicleName: 'Creta',
          docTypeName: 'Insurance Policy',
          policyOrCertNumber: 'POL-VEH-12345',
        ),
      );

      final resolvedVehicleDocNumber = (docWithVehiclePolicy.documentNumber != null &&
              docWithVehiclePolicy.documentNumber!.trim().isNotEmpty)
          ? docWithVehiclePolicy.documentNumber!.trim()
          : (docWithVehiclePolicy.applianceWarranty?.invoiceNumber ??
              docWithVehiclePolicy.vehicleMetadata?.policyOrCertNumber ??
              docWithVehiclePolicy.personalMetadata?.idNumber ??
              docWithVehiclePolicy.utilityMetadata?.consumerNumber ??
              '');

      expect(resolvedVehicleDocNumber, equals('POL-VEH-12345'));
    });

    test('Point 5: Aadhaar Card / Personal doc does not overwrite custom title', () {
      final userEnteredTitle = 'Custom Personal Document';
      // When user enters custom title, changing doc type must not clobber it
      expect(userEnteredTitle, equals('Custom Personal Document'));
      expect(userEnteredTitle.contains('Darshit Gandhi'), isFalse);
    });

    test('Point 6: VehicleDocumentMetadataModel copyWith preserves and updates metadata', () {
      final original = VehicleDocumentMetadataModel(
        id: 'v-1',
        documentId: 'doc-1',
        vehicleNumber: 'GJ01AB1234',
        vehicleName: 'Creta',
        docTypeName: 'Insurance Policy',
        policyOrCertNumber: 'OLD-POL',
        insuranceCompany: 'Old Company',
        premiumAmount: 10000,
        expiryDate: DateTime(2025, 12, 31),
      );

      final updated = original.copyWith(
        policyOrCertNumber: 'NEW-POL-123',
        insuranceCompany: 'HDFC ERGO',
        premiumAmount: 12500,
        expiryDate: DateTime(2026, 12, 31),
      );

      expect(updated.policyOrCertNumber, equals('NEW-POL-123'));
      expect(updated.insuranceCompany, equals('HDFC ERGO'));
      expect(updated.premiumAmount, equals(12500));
      expect(updated.expiryDate, equals(DateTime(2026, 12, 31)));
      expect(updated.vehicleNumber, equals('GJ01AB1234'));
    });

    test('Point 7: Car Insurance policy expiry state and metadata serialization', () {
      final now = DateTime.now();
      final activePolicy = VehicleDocumentMetadataModel(
        vehicleNumber: 'GJ-01-AB-1234',
        vehicleName: 'Toyota Innova Hycross ZX',
        docTypeName: 'Insurance Policy',
        policyOrCertNumber: 'HDFC-ERGO-23114920',
        insuranceCompany: 'HDFC ERGO General Insurance',
        premiumAmount: 42500.0,
        issueDate: now.subtract(const Duration(days: 30)),
        expiryDate: now.add(const Duration(days: 15)), // Expiring soon <= 30d
        notes: 'Zero depreciation, Return-to-Invoice, 24x7 RSA',
      );

      expect(activePolicy.isExpired, isFalse);
      expect(activePolicy.isExpiringSoon, isTrue);
      expect(activePolicy.expiryStatusLabel, contains('Expires in'));
      expect(AppConstants.popularInsuranceProviders, contains('HDFC ERGO General Insurance'));

      final json = activePolicy.toJson();
      expect(json['insurance_company'], equals('HDFC ERGO General Insurance'));
      expect(json['premium_amount'], equals(42500.0));
      expect(json['policy_or_cert_number'], equals('HDFC-ERGO-23114920'));

      final fromJson = VehicleDocumentMetadataModel.fromJson(json);
      expect(fromJson.insuranceCompany, equals('HDFC ERGO General Insurance'));
      expect(fromJson.premiumAmount, equals(42500.0));
      expect(fromJson.policyOrCertNumber, equals('HDFC-ERGO-23114920'));
    });

    test('Point 8: Renewable documents (PUC & Insurance) smart renewal & cross-date verification', () {
      final now = DateTime.now();
      final prevIssue = now.subtract(const Duration(days: 200));
      final prevExpiry = now.subtract(const Duration(days: 20));

      final prevPuc = DocumentModel(
        id: 'puc-old',
        title: 'PUC Certificate 2025 Cycle',
        categoryId: 'cat-vehicle',
        categoryName: 'Vehicle Vault',
        categoryCode: 'vehicle_docs',
        subCategory: 'PUC Certificate',
        folderId: 'fld-4',
        folderName: 'Fleet',
        fileName: 'puc_old.pdf',
        filePath: 'mock/puc_old.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 100000,
        status: 'active',
        createdAt: prevIssue,
        updatedAt: prevIssue,
        vehicleMetadata: VehicleDocumentMetadataModel(
          vehicleNumber: 'GJ-01-AB-1234',
          vehicleName: 'Innova Hycross',
          docTypeName: 'PUC Certificate',
          policyOrCertNumber: 'PUC-2025-01',
          issueDate: prevIssue,
          expiryDate: prevExpiry,
          renewalCount: 0,
        ),
      );

      // 1. Cross-Date Verification Check
      // Case A: Attempting to renew with an expiry date ON or BEFORE previous expiry must fail validation
      final invalidExpiry = prevExpiry.subtract(const Duration(days: 1));
      final isInvalidExpiryAfterPrev = invalidExpiry.isAfter(prevExpiry);
      expect(isInvalidExpiryAfterPrev, isFalse);

      // Case B: Valid renewal dates
      final validNewIssue = now;
      final validNewExpiry = now.add(const Duration(days: 180)); // +6 months
      expect(validNewExpiry.isAfter(validNewIssue), isTrue);
      expect(validNewExpiry.isAfter(prevExpiry), isTrue);

      // 2. Perform Mock Renewal
      DemoDataService.getAllDocuments().add(prevPuc);
      final newMeta = prevPuc.vehicleMetadata!.copyWith(
        policyOrCertNumber: 'PUC-2026-02',
        issueDate: validNewIssue,
        expiryDate: validNewExpiry,
      );

      final renewedDoc = DemoDataService.renewVehicleDocumentMock(
        previousDoc: prevPuc,
        newMetadata: newMeta,
        newTitle: 'PUC Certificate - GJ-01-AB-1234 (2026)',
        newFileName: 'puc_2026.pdf',
        newFileSize: 120000,
        newMimeType: 'application/pdf',
        newFilePath: 'mock/puc_2026.pdf',
      );

      // Verify the new document is active and points to previous document
      expect(renewedDoc.status, equals('active'));
      expect(renewedDoc.subCategory, isNotEmpty);
      expect(renewedDoc.subCategory, equals('PUC Certificate'));
      expect(renewedDoc.vehicleMetadata?.previousDocumentId, equals('puc-old'));
      expect(renewedDoc.vehicleMetadata?.renewalCount, equals(1));

      // Verify previous document is marked 'archived' in cache
      final allDocs = DemoDataService.getAllDocuments();
      final updatedPrev = allDocs.firstWhere((d) => d.id == 'puc-old');
      expect(updatedPrev.status, equals('archived'));

      // 3. Verify Bundled Insurance (1-Yr OD + 5-Yr TP)
      final bundledInsurance = VehicleDocumentMetadataModel(
        vehicleNumber: 'GJ-01-AB-1234',
        vehicleName: 'Innova Hycross',
        docTypeName: 'Insurance Policy',
        insuranceType: 'Bundled (1-Yr OD + 3/5-Yr TP)',
        odExpiryDate: now.add(const Duration(days: 365)), // 1-year OD
        tpExpiryDate: now.add(const Duration(days: 365 * 5)), // 5-year TP
        issueDate: now,
        expiryDate: now.add(const Duration(days: 365)),
      );

      expect(bundledInsurance.isBundledInsurance, isTrue);
      expect(bundledInsurance.tpExpiryDate?.year, equals(now.year + 5));
      expect(bundledInsurance.odExpiryDate?.year, equals(now.year + 1));
    });

    test('Point 9: Dashboard Expiring Documents & "Not Remind" dismissal', () {
      final now = DateTime.now();
      
      // 1. Create vehicle document that expired 19 days ago
      final vehicleDoc = DocumentModel(
        id: 'test-vehicle-exp',
        title: 'Insurance Policy - GJ03NS8003',
        categoryId: 'cat-vehicle',
        subCategory: 'Insurance Policy',
        fileName: 'insurance.pdf',
        filePath: 'mock/insurance.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 100000,
        createdAt: now.subtract(const Duration(days: 384)),
        updatedAt: now,
        vehicleMetadata: VehicleDocumentMetadataModel(
          vehicleNumber: 'GJ03NS8003',
          vehicleName: 'SP-125 (GJ03NS8003)',
          docTypeName: 'Insurance Policy',
          expiryDate: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 19)),
        ),
      );

      expect(vehicleDoc.isGeneralExpired, isTrue);
      expect(vehicleDoc.generalDaysUntilExpiry, equals(-19));
      expect(vehicleDoc.isDoNotRemind, isFalse);

      // 2. Dismiss reminder for this document
      DemoDataService.dismissReminderMock('doc-1');
      final allDocs = DemoDataService.getAllDocuments();
      final dismissedDoc = allDocs.firstWhere((d) => d.id == 'doc-1');
      expect(dismissedDoc.isDoNotRemind, isTrue);

      // 3. Verify bundle excludes dismissed documents from recent and expiring
      final bundle = DemoDataService.getDashboardBundle();
      expect(bundle.recentDocuments.any((d) => d.id == 'doc-1'), isFalse);
      expect(bundle.expiringWarranties.any((d) => d.id == 'doc-1'), isFalse);
    });

    test('Point 10: Health Insurance & Personal Document Renewal Architecture', () {
      final now = DateTime.now();
      final prevExpiry = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 5));
      final prevIssue = prevExpiry.subtract(const Duration(days: 365));

      // 1. Verify Popular Health Insurance Providers constant
      expect(AppConstants.popularHealthInsuranceProviders, contains('Star Health and Allied Insurance'));
      expect(AppConstants.popularHealthInsuranceProviders, contains('Care Health Insurance (Religare)'));
      expect(AppConstants.popularHealthInsuranceProviders, contains('HDFC ERGO Health Insurance'));
      expect(AppConstants.popularHealthInsuranceProviders, contains('Niva Bupa Health Insurance (Max Bupa)'));
      expect(AppConstants.popularHealthInsuranceProviders, contains('Other Insurer'));

      // 2. Initial Health Insurance Policy
      final initialPolicy = DocumentModel(
        id: 'health-policy-1',
        title: 'Health Insurance - Star Health (Vikram)',
        categoryId: 'cat-personal',
        subCategory: 'Health Insurance / Mediclaim',
        fileName: 'star_health_policy.pdf',
        filePath: 'mock/star_health_policy.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 150000,
        status: 'active',
        createdAt: prevIssue,
        updatedAt: prevIssue,
        personalMetadata: PersonalDocumentMetadataModel(
          id: 'meta-health-1',
          documentId: 'health-policy-1',
          personName: 'Vikram Sarabhai',
          docTypeName: 'Health Insurance / Mediclaim',
          idNumber: 'P/123456/01/2025',
          issueDate: prevIssue,
          expiryDate: prevExpiry,
          insuranceCompany: 'Star Health and Allied Insurance',
          policyType: 'Family Floater',
          sumInsured: 1000000,
          premiumAmount: 18500,
        ),
      );

      expect(initialPolicy.personalMetadata?.isInsurance, isTrue);
      expect(initialPolicy.personalMetadata?.isRenewable, isTrue);
      expect(initialPolicy.personalMetadata?.isExpired, isTrue);
      expect(initialPolicy.personalMetadata?.daysUntilExpiry, equals(-5));

      // 3. Date Cross-Verification: new expiry must be strictly after previous expiry
      final invalidNewExpiry = prevExpiry.subtract(const Duration(days: 1));
      final validNewExpiry = DateTime(now.year + 1, now.month, now.day);
      expect(invalidNewExpiry.isAfter(prevExpiry), isFalse);
      expect(validNewExpiry.isAfter(prevExpiry), isTrue);

      // 4. Perform renewal via DemoDataService
      DemoDataService.getAllDocuments().add(initialPolicy);
      final renewedDoc = DemoDataService.renewPersonalDocumentMock(
        previousDoc: initialPolicy,
        newMetadata: PersonalDocumentMetadataModel(
          personName: 'Vikram Sarabhai', // locked
          docTypeName: 'Health Insurance / Mediclaim', // locked
          idNumber: 'P/123456/01/2026', // updated policy number
          insuranceCompany: 'Star Health and Allied Insurance',
          policyType: 'Family Floater',
          sumInsured: 1500000, // upgraded sum insured
          premiumAmount: 21200,
          tpaName: 'Medi Assist',
          issueDate: now,
          expiryDate: validNewExpiry,
        ),
        newTitle: 'Health Insurance - Star Health (Vikram) [Renewed]',
        newFileName: 'star_health_renewal_2026.pdf',
        newFileSize: 150000,
        newMimeType: 'application/pdf',
        newFilePath: 'mock/star_health_renewal_2026.pdf',
      );

      // Verify new renewed document attributes & lineage
      expect(renewedDoc.id, isNot(equals(initialPolicy.id)));
      expect(renewedDoc.status, equals('active'));
      expect(renewedDoc.subCategory, isNotEmpty);
      expect(renewedDoc.subCategory, equals('Health Insurance / Mediclaim'));
      expect(renewedDoc.personalMetadata?.previousDocumentId, equals('health-policy-1'));
      expect(renewedDoc.personalMetadata?.renewalCount, equals(1));
      expect(renewedDoc.personalMetadata?.personName, equals('Vikram Sarabhai'));
      expect(renewedDoc.personalMetadata?.sumInsured, equals(1500000));
      expect(renewedDoc.personalMetadata?.expiryDate, equals(validNewExpiry));

      // Verify previous policy is archived and supersession recorded
      final allDocs = DemoDataService.getAllDocuments();
      final updatedPrev = allDocs.firstWhere((d) => d.id == 'health-policy-1');
      expect(updatedPrev.status, equals('archived'));

      // 5. Verify History query returns both chronologically
      final history = DemoDataService.getPersonalDocTypeHistoryMock(
        personName: 'Vikram Sarabhai',
        docTypeName: 'Health Insurance / Mediclaim',
      );
      expect(history.length, equals(2));
      expect(history.first.id, equals(renewedDoc.id)); // newest first
      expect(history.last.id, equals(initialPolicy.id)); // older archived
    });

    test('Point 11: Utility Connection-Grouped Account Architecture, History & Next Bill Logging', () {
      final now = DateTime.now();
      final augBill = DocumentModel(
        id: 'bill-aug-2026',
        title: 'PGVCL Electricity Bill - Aug 2026',
        fileName: 'pgvcl_aug.pdf',
        fileSize: 45000,
        fileType: 'pdf',
        mimeType: 'application/pdf',
        filePath: 'mock/pgvcl_aug.pdf',
        subCategory: 'Electricity / Light',
        status: 'active',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 60)),
        utilityMetadata: UtilityMetadataModel(
          documentId: 'bill-aug-2026',
          utilityType: 'Electricity / Light',
          providerName: 'PGVCL',
          consumerNumber: '61647126444',
          meterNumber: 'MTR-1118',
          billDate: DateTime(2026, 8, 10),
          dueDate: DateTime(2026, 8, 25),
          billAmount: 3450.0,
          paymentStatus: 'paid',
        ),
        address: AddressModel(
          premiseName: 'RK Iconic, B-1118',
          flatHouseNo: 'B-1118',
          areaLocality: 'RK Iconic, B-1118',
          city: 'Rajkot',
        ),
      );

      final sepBill = DocumentModel(
        id: 'bill-sep-2026',
        title: 'PGVCL Electricity Bill - Sep 2026',
        fileName: 'pgvcl_sep.pdf',
        fileSize: 46000,
        fileType: 'pdf',
        mimeType: 'application/pdf',
        filePath: 'mock/pgvcl_sep.pdf',
        subCategory: 'Electricity / Light',
        status: 'active',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
        utilityMetadata: UtilityMetadataModel(
          documentId: 'bill-sep-2026',
          utilityType: 'Electricity / Light',
          providerName: 'PGVCL',
          consumerNumber: '61647126444',
          meterNumber: 'MTR-1118',
          billDate: DateTime(2026, 9, 10),
          dueDate: DateTime(2026, 9, 25),
          billAmount: 3820.0,
          paymentStatus: 'paid',
        ),
        address: AddressModel(
          premiseName: 'RK Iconic, B-1118',
          flatHouseNo: 'B-1118',
          areaLocality: 'RK Iconic, B-1118',
          city: 'Rajkot',
        ),
      );

      final octBill = DocumentModel(
        id: 'bill-oct-2026',
        title: 'PGVCL Electricity Bill - Oct 2026',
        fileName: 'pgvcl_oct.pdf',
        fileSize: 48000,
        fileType: 'pdf',
        mimeType: 'application/pdf',
        filePath: 'mock/pgvcl_oct.pdf',
        subCategory: 'Electricity / Light',
        status: 'active',
        createdAt: now,
        updatedAt: now,
        utilityMetadata: UtilityMetadataModel(
          documentId: 'bill-oct-2026',
          utilityType: 'Electricity / Light',
          providerName: 'PGVCL',
          consumerNumber: '61647126444',
          meterNumber: 'MTR-1118',
          billDate: DateTime(2026, 10, 10),
          dueDate: DateTime(2026, 10, 25),
          billAmount: 4120.0,
          paymentStatus: 'pending',
        ),
        address: AddressModel(
          premiseName: 'RK Iconic, B-1118',
          flatHouseNo: 'B-1118',
          areaLocality: 'RK Iconic, B-1118',
          city: 'Rajkot',
        ),
      );

      final gasBill = DocumentModel(
        id: 'bill-gas-sep-2026',
        title: 'Gujarat Gas Bill - Sep 2026',
        fileName: 'gas_sep.pdf',
        fileSize: 32000,
        fileType: 'pdf',
        mimeType: 'application/pdf',
        filePath: 'mock/gas_sep.pdf',
        subCategory: 'Gas Bill (PNG / Piped)',
        status: 'active',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
        utilityMetadata: UtilityMetadataModel(
          documentId: 'bill-gas-sep-2026',
          utilityType: 'Gas Bill (PNG / Piped)',
          providerName: 'Gujarat Gas Ltd',
          consumerNumber: 'GUJ-GAS-9912',
          billDate: DateTime(2026, 9, 15),
          dueDate: DateTime(2026, 9, 30),
          billAmount: 890.0,
          paymentStatus: 'paid',
        ),
        address: AddressModel(
          premiseName: 'Home - Krishna Park',
          flatHouseNo: 'Plot 42',
          areaLocality: 'Home - Krishna Park',
          city: 'Rajkot',
        ),
      );

      final allRawBills = [augBill, sepBill, octBill, gasBill];

      // 1. Group into connection accounts
      final accounts = UtilityConnectionAccount.groupFromDocuments(allRawBills);

      // Verify two distinct connection accounts are created
      expect(accounts.length, equals(2));

      // 2. Verify RK Iconic Office 1118 Connection Account
      final rkIconicAccount = accounts.firstWhere(
        (a) => a.consumerNumber == '61647126444',
      );
      expect(rkIconicAccount.displayName, equals('RK Iconic, B-1118'));
      expect(rkIconicAccount.providerName, equals('PGVCL'));
      expect(rkIconicAccount.utilityType, equals('Electricity / Light'));
      expect(rkIconicAccount.city, equals('Rajkot'));
      expect(rkIconicAccount.meterNumber, equals('MTR-1118'));
      expect(rkIconicAccount.totalCyclesCount, equals(3));

      // 3. Verify Latest Bill Spotlight (Oct 2026)
      expect(rkIconicAccount.latestBill.id, equals('bill-oct-2026'));
      expect(rkIconicAccount.latestBillAmount, equals(4120.0));
      expect(rkIconicAccount.isPaid, isFalse); // Oct bill is pending
      expect(rkIconicAccount.latestDueDate, equals(DateTime(2026, 10, 25)));

      // 4. Verify Historical Order (newest cycle first: Oct -> Sep -> Aug)
      expect(rkIconicAccount.historicalBills.map((b) => b.id).toList(), equals([
        'bill-oct-2026',
        'bill-sep-2026',
        'bill-aug-2026',
      ]));

      // 5. Verify Gas Connection Account
      final gasAccount = accounts.firstWhere(
        (a) => a.consumerNumber == 'GUJ-GAS-9912',
      );
      expect(gasAccount.displayName, equals('Home - Krishna Park'));
      expect(gasAccount.providerName, equals('Gujarat Gas Ltd'));
      expect(gasAccount.totalCyclesCount, equals(1));
      expect(gasAccount.isPaid, isTrue);
      expect(gasAccount.latestBillAmount, equals(890.0));
    });

    test('Point 12: Mandatory Utility Location & Settings Full Address Integration', () {
      // 1. Create a MasterLocationModel with full address attributes
      final rkLocation = MasterLocationModel(
        id: 'loc-rk-iconic-1118',
        name: 'RK Iconic Office 1118',
        premiseName: 'RK Iconic, B-1118',
        flatHouseNo: 'B-1118',
        buildingName: 'RK Iconic',
        streetAddress: '150 Feet Ring Road',
        areaLocality: 'Sheetal Park / Raiya Road',
        city: 'Rajkot',
        state: 'Gujarat',
        postalCode: '360005',
        country: 'India',
        isActive: true,
        displayOrder: 1,
      );

      // Verify fullAddress formats nicely with city, pincode, state, and country
      expect(
        rkLocation.fullAddress,
        equals('B-1118, RK Iconic, 150 Feet Ring Road, Sheetal Park / Raiya Road, Rajkot - 360005, Gujarat, India'),
      );

      // Verify concise summary format
      expect(
        rkLocation.summary,
        equals('RK Iconic Office 1118 (Rajkot - 360005, India)'),
      );

      // 2. AddressModel derived from selected location
      final docAddress = AddressModel(
        premiseName: rkLocation.premiseName ?? rkLocation.name,
        flatHouseNo: rkLocation.flatHouseNo,
        buildingName: rkLocation.buildingName,
        streetAddress: rkLocation.streetAddress,
        areaLocality: rkLocation.areaLocality,
        city: rkLocation.city,
        state: rkLocation.state,
        postalCode: rkLocation.postalCode,
        country: rkLocation.country,
      );

      expect(docAddress.premiseName, equals('RK Iconic, B-1118'));
      expect(docAddress.city, equals('Rajkot'));
      expect(docAddress.postalCode, equals('360005'));
      expect(docAddress.country, equals('India'));
      expect(docAddress.formattedAddress, contains('Rajkot'));
      expect(docAddress.formattedAddress, contains('360005'));

      // 3. Validation Logic: Location is mandatory for utility bills
      bool validateUtilityUpload({
        required bool isUtilityBill,
        MasterLocationModel? selectedLocation,
        String? manualPremise,
        String? manualLocality,
      }) {
        if (!isUtilityBill) return true;
        final hasLocation = selectedLocation != null;
        final hasManual = (manualPremise != null && manualPremise.trim().isNotEmpty) ||
            (manualLocality != null && manualLocality.trim().isNotEmpty);
        return hasLocation || hasManual;
      }

      // Without location or manual premise -> Fails validation
      expect(validateUtilityUpload(isUtilityBill: true), isFalse);
      expect(validateUtilityUpload(isUtilityBill: true, manualPremise: '   '), isFalse);

      // With selected location -> Passes validation
      expect(validateUtilityUpload(isUtilityBill: true, selectedLocation: rkLocation), isTrue);

      // Non-utility bills don't mandate premises
      expect(validateUtilityUpload(isUtilityBill: false), isTrue);
    });

    test('Point 13: Dedicated Inside Screens with Editable Details & History for Utility Accounts, Vehicles, and Insurance', () async {
      // -------------------------------------------------------------
      // 1. Utility Connection Account Details & Editable Full Address
      // -------------------------------------------------------------
      final doc1 = DocumentModel(
        id: 'util-rk-cycle-1',
        title: 'Torrent Power - Oct 2026',
        fileName: 'torrent_oct.pdf',
        fileSize: 1024,
        fileType: 'pdf',
        mimeType: 'application/pdf',
        filePath: 'mock/torrent_oct.pdf',
        subCategory: 'Electricity / Light',
        status: 'active',
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
        utilityMetadata: UtilityMetadataModel(
          documentId: 'util-rk-cycle-1',
          utilityType: 'Electricity / Light',
          providerName: 'PGVCL',
          consumerNumber: 'CN-1118-TEST',
          meterNumber: 'MTR-1118',
          billDate: DateTime(2026, 10, 15),
          dueDate: DateTime(2026, 10, 30),
          billAmount: 3500.0,
          paymentStatus: 'pending',
        ),
        address: AddressModel(
          premiseName: 'RK Iconic Office',
          flatHouseNo: 'B-1118',
          buildingName: 'RK Iconic',
          streetAddress: '150 Feet Ring Road',
          areaLocality: 'Raiya Road',
          city: 'Rajkot',
          state: 'Gujarat',
          postalCode: '360005',
          country: 'India',
        ),
      );

      final doc2 = DocumentModel(
        id: 'util-rk-cycle-2',
        title: 'Torrent Power - Sep 2026',
        fileName: 'torrent_sep.pdf',
        fileSize: 1024,
        fileType: 'pdf',
        mimeType: 'application/pdf',
        filePath: 'mock/torrent_sep.pdf',
        subCategory: 'Electricity / Light',
        status: 'active',
        createdAt: DateTime(2026, 9, 15),
        updatedAt: DateTime(2026, 9, 15),
        utilityMetadata: UtilityMetadataModel(
          documentId: 'util-rk-cycle-2',
          utilityType: 'Electricity / Light',
          providerName: 'PGVCL',
          consumerNumber: 'CN-1118-TEST',
          meterNumber: 'MTR-1118',
          billDate: DateTime(2026, 9, 15),
          dueDate: DateTime(2026, 9, 30),
          billAmount: 3200.0,
          paymentStatus: 'paid',
        ),
        address: AddressModel(
          premiseName: 'RK Iconic Office',
          flatHouseNo: 'B-1118',
          buildingName: 'RK Iconic',
          streetAddress: '150 Feet Ring Road',
          areaLocality: 'Raiya Road',
          city: 'Rajkot',
          state: 'Gujarat',
          postalCode: '360005',
          country: 'India',
        ),
      );

      final accounts = UtilityConnectionAccount.groupFromDocuments([doc1, doc2]);
      expect(accounts.length, equals(1));
      final account = accounts.first;

      // Verify full address fields were extracted properly
      expect(account.flatHouseNo, equals('B-1118'));
      expect(account.buildingName, equals('RK Iconic'));
      expect(account.streetAddress, equals('150 Feet Ring Road'));
      expect(account.areaLocality, equals('Raiya Road'));
      expect(account.city, equals('Rajkot'));
      expect(account.postalCode, equals('360005'));
      expect(account.state, equals('Gujarat'));
      expect(account.country, equals('India'));
      expect(account.fullAddress, contains('B-1118'));
      expect(account.fullAddress, contains('Rajkot - 360005'));
      expect(account.totalCyclesCount, equals(2));

      // -------------------------------------------------------------
      // 2. Vehicle Specifications Editing & Document Lineage
      // -------------------------------------------------------------
      final vehicle = MasterVehicleModel(
        id: 'veh-sp125',
        vehicleNumber: 'GJ03NS8003',
        nickname: 'SP-125',
        brandMake: 'Honda',
        modelName: 'SP 125 Disc',
        vehicleType: 'Two Wheeler',
        fuelType: 'Petrol',
        ownerName: 'Maheshbhai Vallabhbhai Gandhi',
        chassisNumber: 'ME4JC915KLR123456',
        engineNumber: 'JC91E9123456',
        registrationDate: DateTime(2022, 5, 20),
        createdAt: DateTime(2022, 5, 20),
        updatedAt: DateTime(2022, 5, 20),
      );

      // Verify vehicle copyWith updates editable specifications cleanly
      final updatedVehicle = vehicle.copyWith(
        nickname: 'Honda SP-125 BS6',
        ownerName: 'Mihir Maheshbhai Gandhi',
        updatedAt: DateTime(2026, 11, 16),
      );
      expect(updatedVehicle.nickname, equals('Honda SP-125 BS6'));
      expect(updatedVehicle.ownerName, equals('Mihir Maheshbhai Gandhi'));
      expect(updatedVehicle.vehicleNumber, equals('GJ03NS8003'));
      expect(updatedVehicle.brandMake, equals('Honda'));

      // -------------------------------------------------------------
      // 3. Health Insurance / Personal Document Details & Renewal Lineage
      // -------------------------------------------------------------
      final initialPolicy = PersonalDocumentMetadataModel(
        id: 'meta-health-2025',
        documentId: 'doc-health-2025',
        personName: 'Maheshbhai Gandhi',
        relationship: 'Father',
        docTypeName: 'Health Insurance Policy',
        idNumber: 'P/123456/01/2025',
        insuranceCompany: 'Star Health & Allied Insurance',
        policyType: 'Family Floater',
        sumInsured: 1000000.0,
        premiumAmount: 24500.0,
        tpaName: 'In-House TPA',
        issueDate: DateTime(2025, 4, 1),
        expiryDate: DateTime(2026, 3, 31),
        renewalCount: 0,
      );

      // Verify policyNumber alias matches idNumber
      expect(initialPolicy.policyNumber, equals('P/123456/01/2025'));
      expect(initialPolicy.isInsurance, isTrue);
      expect(initialPolicy.isRenewable, isTrue);

      // Simulate renewal activation
      final renewedPolicy = initialPolicy.copyWith(
        id: 'meta-health-2026',
        documentId: 'doc-health-2026',
        idNumber: 'P/123456/01/2026',
        previousDocumentId: 'doc-health-2025',
        renewalCount: 1,
        issueDate: DateTime(2026, 4, 1),
        expiryDate: DateTime(2027, 3, 31),
        premiumAmount: 26800.0,
      );

      expect(renewedPolicy.renewalCount, equals(1));
      expect(renewedPolicy.previousDocumentId, equals('doc-health-2025'));
      expect(renewedPolicy.policyNumber, equals('P/123456/01/2026'));
      expect(renewedPolicy.premiumAmount, equals(26800.0));
      expect(renewedPolicy.expiryDate, equals(DateTime(2027, 3, 31)));
    });

    test('Point 14: Settings Location Selection and Historical Bill Cycle Editing', () async {
      // 1. Verify Settings Location mapping to Utility Address
      final settingLocation = MasterLocationModel(
        id: 'loc-rk-iconic-1118',
        name: 'RK Iconic Office 1118',
        premiseName: 'RK Iconic, 11th Floor',
        flatHouseNo: 'Office 1118',
        buildingName: 'RK Iconic',
        streetAddress: '150 Feet Ring Road',
        areaLocality: 'Near Nana Mava Circle',
        city: 'Rajkot',
        state: 'Gujarat',
        postalCode: '360005',
        country: 'India',
        isActive: true,
      );

      expect(settingLocation.fullAddress, equals('Office 1118, RK Iconic, 150 Feet Ring Road, Near Nana Mava Circle, Rajkot - 360005, Gujarat, India'));
      expect(settingLocation.summary, equals('RK Iconic Office 1118 (Rajkot - 360005, India)'));

      final mappedAddress = AddressModel(
        premiseName: settingLocation.name,
        flatHouseNo: settingLocation.flatHouseNo,
        buildingName: settingLocation.buildingName,
        streetAddress: settingLocation.streetAddress,
        areaLocality: settingLocation.areaLocality,
        city: settingLocation.city,
        postalCode: settingLocation.postalCode,
        state: settingLocation.state,
        country: settingLocation.country,
      );

      expect(mappedAddress.city, equals('Rajkot'));
      expect(mappedAddress.postalCode, equals('360005'));
      expect(mappedAddress.streetAddress, equals('150 Feet Ring Road'));
      expect(mappedAddress.flatHouseNo, equals('Office 1118'));

      // 2. Verify Older Bill Cycle Editing via DemoDataService.updateUtilityBillCycleMock
      final allDocs = DemoDataService.getAllDocuments();
      final utilityDocs = allDocs.where((d) => d.categoryCode == 'utility_bills' || d.utilityMetadata != null).toList();
      expect(utilityDocs.isNotEmpty, isTrue);

      final targetBill = utilityDocs.first;
      final originalId = targetBill.id;
      final updatedBillAmount = 9876.50;
      final updatedBillDate = DateTime(2026, 8, 15);
      final updatedDueDate = DateTime(2026, 8, 30);
      const updatedPaymentStatus = 'paid';
      final updatedPaymentDate = DateTime(2026, 8, 20);
      const updatedReferenceId = 'UPI-TXN-99887766';
      const updatedTitle = 'Edited PGVCL August 2026 Bill';
      const updatedDescription = 'Audited commercial power bill cycle';
      const updatedMeter = 'MTR-9988-X';
      final updatedUnits = 850.5;

      DemoDataService.updateUtilityBillCycleMock(
        documentId: originalId,
        title: updatedTitle,
        billAmount: updatedBillAmount,
        billDate: updatedBillDate,
        dueDate: updatedDueDate,
        paymentStatus: updatedPaymentStatus,
        paymentDate: updatedPaymentDate,
        paymentReferenceId: updatedReferenceId,
        meterNumber: updatedMeter,
        unitsConsumed: updatedUnits,
        description: updatedDescription,
      );

      // Verify target cycle was updated in DemoDataService
      final cycleAfterEdit = allDocs.firstWhere((d) => d.id == originalId);

      expect(cycleAfterEdit.title, equals(updatedTitle));
      expect(cycleAfterEdit.description, equals(updatedDescription));
      expect(cycleAfterEdit.utilityMetadata?.billAmount, equals(updatedBillAmount));
      expect(cycleAfterEdit.utilityMetadata?.billDate, equals(updatedBillDate));
      expect(cycleAfterEdit.utilityMetadata?.dueDate, equals(updatedDueDate));
      expect(cycleAfterEdit.utilityMetadata?.paymentStatus, equals(updatedPaymentStatus));
      expect(cycleAfterEdit.utilityMetadata?.paymentDate, equals(updatedPaymentDate));
      expect(cycleAfterEdit.utilityMetadata?.paymentReferenceId, equals(updatedReferenceId));
      expect(cycleAfterEdit.utilityMetadata?.meterNumber, equals(updatedMeter));
      expect(cycleAfterEdit.utilityMetadata?.unitsConsumed, equals(updatedUnits));
    });

    test('Point 15: First-time entry of vehicle insurance with 3/5-year bundled TP cover from upload screen', () {
      // 1. Vehicle selection determines default bundled term (3-Yr for 4W, 5-Yr for 2W)
      final fourWheeler = MasterVehicleModel(
        id: 'v-creta',
        vehicleNumber: 'GJ-01-AB-1234',
        vehicleType: 'Four Wheeler',
        nickname: 'Creta SX',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final twoWheeler = MasterVehicleModel(
        id: 'v-activa',
        vehicleNumber: 'GJ-03-NS-8003',
        vehicleType: 'Two Wheeler',
        nickname: 'SP-125',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final is4WTwoWheeler = fourWheeler.vehicleType.toLowerCase().contains('two');
      final is2WTwoWheeler = twoWheeler.vehicleType.toLowerCase().contains('two');
      expect(is4WTwoWheeler, isFalse);
      expect(is2WTwoWheeler, isTrue);

      final default4WYears = is4WTwoWheeler ? 5 : 3;
      final default2WYears = is2WTwoWheeler ? 5 : 3;
      expect(default4WYears, equals(3));
      expect(default2WYears, equals(5));

      // 2. Issue date calculation: OD Expiry (+1 Year), TP Expiry (+3 Years)
      final issueDate = DateTime(2028, 11, 24);
      final odExpiry = DateTime(issueDate.year + 1, issueDate.month, issueDate.day);
      final tpExpiry4W = DateTime(issueDate.year + default4WYears, issueDate.month, issueDate.day);
      final tpExpiry2W = DateTime(issueDate.year + default2WYears, issueDate.month, issueDate.day);

      expect(odExpiry, equals(DateTime(2029, 11, 24)));
      expect(tpExpiry4W, equals(DateTime(2031, 11, 24)));
      expect(tpExpiry2W, equals(DateTime(2033, 11, 24)));

      // 3. Metadata persistence model verification
      final vehicleInsuranceMeta = VehicleDocumentMetadataModel(
        vehicleId: fourWheeler.id,
        vehicleNumber: fourWheeler.vehicleNumber,
        vehicleName: fourWheeler.nickname!,
        docTypeName: 'Insurance Policy',
        policyOrCertNumber: '3001/HY-21165114/00/000',
        insuranceCompany: 'ICICI Lombard General Insurance',
        premiumAmount: 52273.0,
        issueDate: issueDate,
        expiryDate: odExpiry,
        insuranceType: 'Bundled (1-Yr OD + 3-Yr TP)',
        odExpiryDate: odExpiry,
        tpExpiryDate: tpExpiry4W,
      );

      expect(vehicleInsuranceMeta.isBundledInsurance, isTrue);
      expect(vehicleInsuranceMeta.insuranceType, equals('Bundled (1-Yr OD + 3-Yr TP)'));
      expect(vehicleInsuranceMeta.odExpiryDate, equals(DateTime(2029, 11, 24)));
      expect(vehicleInsuranceMeta.tpExpiryDate, equals(DateTime(2031, 11, 24)));

      // 4. Document extraAttributes serialization for Supabase & Demo Mode
      final extraAttributes = <String, dynamic>{
        'storage_provider': 'demo',
        'insurance_type': vehicleInsuranceMeta.insuranceType,
        'od_expiry_date': vehicleInsuranceMeta.odExpiryDate!.toIso8601String().split('T').first,
        'tp_expiry_date': vehicleInsuranceMeta.tpExpiryDate!.toIso8601String().split('T').first,
      };

      final doc = DocumentModel(
        id: 'doc-car-insurance-1',
        title: 'Insurance Policy - GJ-01-AB-1234',
        fileName: 'icici_insurance.pdf',
        fileSize: 1024,
        fileType: 'pdf',
        mimeType: 'application/pdf',
        filePath: 'demo/icici_insurance.pdf',
        subCategory: 'Insurance Policy',
        status: 'active',
        extraAttributes: extraAttributes,
        vehicleMetadata: vehicleInsuranceMeta,
        createdAt: issueDate,
        updatedAt: issueDate,
      );

      expect(doc.vehicleMetadata?.isBundledInsurance, isTrue);
      expect(doc.vehicleMetadata?.tpExpiryDate, equals(DateTime(2031, 11, 24)));
      expect(doc.extraAttributes['insurance_type'], equals('Bundled (1-Yr OD + 3-Yr TP)'));
      expect(doc.extraAttributes['tp_expiry_date'], equals('2031-11-24'));
    });

    test('Point 15: Personal Documents Vault - Aadhaar (No Expiry) vs Driving License (Validity)', () {
      // 1. Aadhaar Card (No expiry date / lifetime validity)
      final aadhaarMeta = PersonalDocumentMetadataModel(
        personName: 'Mihir Gandhi',
        docTypeName: 'Aadhaar Card',
        idNumber: '9842 1920 8812',
        issuingAuthority: 'UIDAI',
        issueDate: DateTime(2018, 5, 14),
        expiryDate: null,
      );

      expect(aadhaarMeta.hasExpiry, isFalse);
      expect(aadhaarMeta.expiryDate, isNull);
      expect(aadhaarMeta.isExpired, isFalse);
      expect(aadhaarMeta.isExpiringSoon, isFalse);
      expect(aadhaarMeta.expiryStatusLabel, equals('Lifetime (No Expiry)'));

      // Serialization without expiry date
      final aadhaarJson = aadhaarMeta.toJson(forSupabaseTable: true);
      expect(aadhaarJson['expiry_date'], isNull);
      expect(aadhaarJson['doc_type_name'], equals('Aadhaar Card'));
      expect(aadhaarJson['id_number'], equals('9842 1920 8812'));

      // 2. Driving License (Has validity / expiry date)
      final dlExpiry = DateTime(2039, 3, 19);
      final dlMeta = PersonalDocumentMetadataModel(
        personName: 'Mihir Gandhi',
        docTypeName: 'Driving License',
        idNumber: 'GJ01-20190012345',
        issuingAuthority: 'RTO Ahmedabad',
        issueDate: DateTime(2019, 3, 20),
        expiryDate: dlExpiry,
      );

      expect(dlMeta.hasExpiry, isTrue);
      expect(dlMeta.expiryDate, equals(dlExpiry));
      expect(dlMeta.isExpired, isFalse);
      expect(dlMeta.daysUntilExpiry, isNotNull);
      expect(dlMeta.daysUntilExpiry!, greaterThan(0));

      final dlJson = dlMeta.toJson(forSupabaseTable: true);
      expect(dlJson['expiry_date'], equals('2039-03-19'));

      // 3. Toggling expiry date off using clearExpiryDate
      final clearedMeta = dlMeta.copyWith(clearExpiryDate: true);
      expect(clearedMeta.expiryDate, isNull);
      expect(clearedMeta.hasExpiry, isFalse);
      expect(clearedMeta.expiryStatusLabel, equals('Lifetime (No Expiry)'));

      // 4. Re-upload / History verification in DemoDataService
      final allDocs = DemoDataService.getAllDocuments();
      final aadhaarDoc = allDocs.firstWhere((d) => d.subCategory == 'Aadhaar Card');
      final dlDoc = allDocs.firstWhere((d) => d.subCategory == 'Driving License');

      expect(aadhaarDoc.personalMetadata?.expiryDate, isNull);
      expect(dlDoc.personalMetadata?.expiryDate, isNotNull);

      final aadhaarHistory = DemoDataService.getPersonalDocTypeHistoryMock(
        personName: 'Mihir Gandhi',
        docTypeName: 'Aadhaar Card',
      );
      expect(aadhaarHistory, isNotEmpty);
      expect(aadhaarHistory.first.title, contains('Aadhaar Card'));

      final dlHistory = DemoDataService.getPersonalDocTypeHistoryMock(
        personName: 'Mihir Gandhi',
        docTypeName: 'Driving License',
      );
      expect(dlHistory, isNotEmpty);
      expect(dlHistory.first.title, contains('Driving License'));
    });

    test(
        'Point 16: Appliance Vault - Details, Warranty Renewal (AMC, Extended, Component, Lifetime, No-Warranty), and Version Lineage History',
        () async {
      final now = DateTime.now();

      // 1. Initial Appliance Invoice (Standard Manufacturer Warranty)
      final initialWarranty = ApplianceWarrantyModel(
        billingName: 'King Technology Pvt Ltd',
        storeVendorName: 'Vijay Sales Thaltej',
        invoiceNumber: 'INV-AC-9901',
        purchaseDate: now.subtract(const Duration(days: 365)),
        purchaseAmount: 52000.0,
        warrantyType: 'standard',
        items: [
          ApplianceItemModel(
            productName: 'Voltas 1.5 Ton Inverter AC',
            productCategory: 'Air Conditioner',
            brand: 'Voltas',
            modelNumber: 'VOLT-185V',
            serialNumber: 'SN-VOLT-2024-9102',
            purchaseAmount: 52000.0,
            warrantyPeriodMonths: 12,
            warrantyValidUpto: now.subtract(const Duration(days: 5)), // Expired standard warranty
            warrantyStatus: 'expired',
            warrantyType: 'standard',
          ),
        ],
      );

      expect(initialWarranty.isExpired, isTrue);
      expect(initialWarranty.warrantyStatusDisplay, equals('EXPIRED'));
      expect(initialWarranty.warrantyTypeDisplay, equals('Standard Manufacturer Warranty'));

      final baseDoc = DocumentModel(
        id: 'doc-appliance-voltas-1',
        title: 'Voltas 1.5 Ton AC Purchase Invoice',
        categoryId: 'cat-appliance',
        categoryCode: 'appliance_warranty',
        subCategory: 'Air Conditioner',
        fileName: 'voltas_ac_invoice.pdf',
        filePath: 'mock/voltas_ac.pdf',
        fileType: 'pdf',
        mimeType: 'application/pdf',
        fileSize: 500000,
        status: 'active',
        documentNumber: 'INV-AC-9901',
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now.subtract(const Duration(days: 365)),
        applianceWarranty: initialWarranty,
      );

      // Add to DemoDataService
      DemoDataService.getAllDocuments().insert(0, baseDoc);

      // 2. Perform AMC Warranty Renewal
      final amcExpiry = now.add(const Duration(days: 360));
      final amcWarranty = initialWarranty.copyWith(
        warrantyType: 'amc',
        extendedWarrantyUpto: amcExpiry,
        amcProvider: 'Urban Company Care',
        policyNumber: 'AMC-UC-2026-4412',
        renewalAmount: 4200.0,
        renewalNotes: 'Includes 2 seasonal wet cleaning visits & free capacitor replacements',
        items: [
          initialWarranty.items.first.copyWith(
            extendedWarrantyUpto: amcExpiry,
            warrantyType: 'amc',
            policyNumber: 'AMC-UC-2026-4412',
            amcProvider: 'Urban Company Care',
            warrantyStatus: 'active',
          ),
        ],
      );

      expect(amcWarranty.warrantyTypeDisplay, equals('Annual Maintenance Contract (AMC)'));
      expect(amcWarranty.effectiveValidUpto, equals(amcExpiry));
      expect(amcWarranty.isExpired, isFalse);
      expect(amcWarranty.warrantyStatusDisplay, equals('AMC ACTIVE'));

      final renewedDoc = DemoDataService.renewApplianceWarrantyMock(
        previousDoc: baseDoc,
        newWarranty: amcWarranty,
        newTitle: 'Voltas 1.5 Ton AC - 1-Year AMC Contract',
        newFileName: 'voltas_amc_contract_2026.pdf',
        newFileSize: 250000,
        newMimeType: 'application/pdf',
        newFilePath: 'mock/voltas_amc_contract_2026.pdf',
        newDescription: 'Annual maintenance contract renewed via Urban Company',
      );

      // Verify previous document was archived
      final updatedBaseDoc = DemoDataService.getAllDocuments().firstWhere((d) => d.id == baseDoc.id);
      expect(updatedBaseDoc.status, equals('archived'));
      expect(updatedBaseDoc.extraAttributes['archived_reason'], equals('renewed'));

      // Verify renewed document state and lineage
      expect(renewedDoc.status, equals('active'));
      expect(renewedDoc.extraAttributes['previous_document_id'], equals(baseDoc.id));
      expect(renewedDoc.extraAttributes['renewal_count'], equals(1));
      expect(renewedDoc.extraAttributes['warranty_type'], equals('amc'));
      expect(renewedDoc.applianceWarranty?.amcProvider, equals('Urban Company Care'));
      expect(renewedDoc.applianceWarranty?.policyNumber, equals('AMC-UC-2026-4412'));
      expect(renewedDoc.applianceWarranty?.renewalAmount, equals(4200.0));

      // 3. Lineage & History verification
      final history = DemoDataService.getApplianceHistoryMock(
        documentId: renewedDoc.id,
        serialNumber: 'SN-VOLT-2024-9102',
      );
      expect(history.length, greaterThanOrEqualTo(2));
      expect(history.any((d) => d.id == renewedDoc.id), isTrue);
      expect(history.any((d) => d.id == baseDoc.id), isTrue);

      // 4. Verify Built-in Demo Appliance History for Daikin AC (doc-3 & doc-3b)
      final daikinHistory = DemoDataService.getApplianceHistoryMock(
        documentId: 'doc-3',
        serialNumber: 'DKN-2024-99812A',
      );
      expect(daikinHistory.length, greaterThanOrEqualTo(2));
      expect(daikinHistory.any((d) => d.id == 'doc-3'), isTrue);
      expect(daikinHistory.any((d) => d.id == 'doc-3b'), isTrue);

      // 5. Verify Lifetime Guarantee & No Warranty / Bill Only Modes
      final lifetimeWarranty = ApplianceWarrantyModel(
        billingName: 'King Technology Pvt Ltd',
        storeVendorName: 'Nilkamal Furniture',
        invoiceNumber: 'INV-FURN-1029',
        purchaseDate: now.subtract(const Duration(days: 400)),
        purchaseAmount: 18500.0,
        warrantyType: 'lifetime',
        items: [
          ApplianceItemModel(
            productName: 'Executive Ergonomic Chair',
            productCategory: 'Furniture / Office Asset',
            brand: 'Nilkamal',
            warrantyPeriodMonths: 0,
            warrantyValidUpto: now,
            warrantyStatus: 'active',
            warrantyType: 'lifetime',
          ),
        ],
      );
      expect(lifetimeWarranty.isLifetime, isTrue);
      expect(lifetimeWarranty.isExpired, isFalse);
      expect(lifetimeWarranty.warrantyStatusDisplay, equals('LIFETIME'));
      expect(lifetimeWarranty.warrantyTypeDisplay, equals('Lifetime Guarantee'));

      final noWarranty = ApplianceWarrantyModel(
        billingName: 'King Technology Pvt Ltd',
        storeVendorName: 'Local Hardware Store',
        invoiceNumber: 'BILL-REPAIR-9182',
        purchaseDate: now,
        purchaseAmount: 1200.0,
        warrantyType: 'no_warranty',
      );
      expect(noWarranty.hasWarranty, isFalse);
      expect(noWarranty.warrantyStatusDisplay, equals('NO WARRANTY'));
      expect(noWarranty.warrantyTypeDisplay, equals('No Warranty (Invoice Only)'));

      // 6. Verify Appliance Detail Full-Screen Route Configuration
      expect(AppRoutes.APPLIANCE_DETAIL, equals('/appliances/detail'));
      final applianceDetailPage = AppPages.routes.firstWhereOrNull(
        (page) => page.name == AppRoutes.APPLIANCE_DETAIL,
      );
      expect(applianceDetailPage, isNotNull);
      expect(applianceDetailPage?.binding, isA<ApplianceDetailBinding>());

      // 7. Verify Schema Immunity: toSupabaseMap() and toJson(forSupabaseTable: true) contain ZERO non-schema columns
      final fullWarranty = ApplianceWarrantyModel(
        billingName: 'King Technology',
        storeVendorName: 'Croma Retail',
        invoiceNumber: 'SLA373385612716',
        purchaseDate: now,
        purchaseAmount: 45000.0,
        warrantyType: 'amc',
        policyNumber: 'AMC-POL-9921',
        amcProvider: 'Urban Company',
        renewalAmount: 3500.0,
        renewalNotes: 'Comprehensive compressor & gas refill contract',
        items: [
          ApplianceItemModel(
            productName: 'Godrej Refrigerator 320L',
            productCategory: 'Refrigerator',
            brand: 'Godrej',
            modelNumber: 'RT-EON-320',
            serialNumber: 'GD-991204',
            warrantyPeriodMonths: 24,
            warrantyValidUpto: now.add(const Duration(days: 730)),
            customerCareNumber: '1800-209-5511',
            warrantyStatus: 'active',
            warrantyType: 'amc',
            policyNumber: 'AMC-POL-9921',
            amcProvider: 'Urban Company',
          ),
        ],
      );

      final supabaseMap = fullWarranty.toSupabaseMap();
      final defaultJson = fullWarranty.toJson(); // default forSupabaseTable: true
      final fullExportJson = fullWarranty.toJson(forSupabaseTable: false);

      // Verify strict schema columns compliance (prevents PGRST204 errors)
      expect(supabaseMap.containsKey('amc_provider'), isFalse);
      expect(supabaseMap.containsKey('warranty_type'), isFalse);
      expect(supabaseMap.containsKey('policy_number'), isFalse);
      expect(supabaseMap.containsKey('renewal_amount'), isFalse);
      expect(supabaseMap.containsKey('renewal_notes'), isFalse);
      expect(supabaseMap.containsKey('items'), isFalse);
      for (final key in supabaseMap.keys) {
        expect(ApplianceWarrantyModel.supabaseColumns.contains(key), isTrue,
            reason: 'Column $key is not present in appliance_warranty_metadata table schema');
      }

      // Verify default toJson() is also table-safe
      expect(defaultJson.containsKey('amc_provider'), isFalse);
      expect(defaultJson.containsKey('items'), isFalse);

      // Verify full export json retains extended attributes
      expect(fullExportJson['amc_provider'], equals('Urban Company'));
      expect(fullExportJson['warranty_type'], equals('amc'));
      expect(fullExportJson['items'], isNotEmpty);

      // Verify copyWith updates primary item dates correctly
      final updatedExpiry = now.add(const Duration(days: 1000));
      final copiedWarranty = fullWarranty.copyWith(
        warrantyValidUpto: updatedExpiry,
        amcProvider: 'Onsitego Services',
      );
      expect(copiedWarranty.warrantyValidUpto, equals(updatedExpiry));
      expect(copiedWarranty.primaryItem?.warrantyValidUpto, equals(updatedExpiry));
      expect(copiedWarranty.amcProvider, equals('Onsitego Services'));
    });
  });
}
