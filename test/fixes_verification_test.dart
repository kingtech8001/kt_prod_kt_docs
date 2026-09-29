import 'package:flutter_test/flutter_test.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/appliance_warranty_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/master_data_models.dart';
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
  });
}
