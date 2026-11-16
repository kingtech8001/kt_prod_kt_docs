import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/services/document_scanner_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('DocumentScannerService Automation & Extraction Tests', () {
    test('Correctly classifies and extracts fields from Utility Bill filename & hints', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      final result = await DocumentScannerService.scanDocument(
        bytes: dummyBytes,
        fileName: 'UGVCL_Electricity_Bill_Ahmedabad_CN1029384.pdf',
        knownCities: ['Ahmedabad', 'Surat'],
      );

      expect(result.detectedCategoryCode, DocumentScannerService.catUtilityBills);
      expect(result.detectedSubcategory, 'Light / Electricity Bill');
      expect(result.city, 'Ahmedabad');
      expect(result.utilityFields['providerName'], contains('UGVCL'));
    });

    test('Correctly classifies and extracts fields from Vehicle Insurance Policy', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      final result = await DocumentScannerService.scanDocument(
        bytes: dummyBytes,
        fileName: 'HDFC_ERGO_Car_Insurance_Policy_GJ-01-AB-1234.pdf',
        knownCities: ['Ahmedabad'],
        knownVehicles: [
          MasterVehicleModel(
            id: 'veh-1',
            vehicleNumber: 'GJ-01-AB-1234',
            nickname: 'Hyundai Creta',
            vehicleType: 'Four Wheeler',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      expect(result.detectedCategoryCode, DocumentScannerService.catVehicleDocs);
      expect(result.detectedSubcategory, 'Insurance Policy');
      expect(result.vehicleFields['insuranceCompany'], 'HDFC ERGO General Insurance');
      expect(result.vehicleFields['vehicleNumber'], contains('GJ-01-AB-1234'));
      expect(result.vehicleFields['vehicleId'], 'veh-1');
    });

    test('Correctly classifies and extracts fields from Aadhaar Card / Identity Doc', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      final result = await DocumentScannerService.scanDocument(
        bytes: dummyBytes,
        fileName: 'Aadhaar_Card_UIDAI_Mihir_Gandhi.pdf',
        knownPersons: [
          MasterPersonModel(
            id: 'person-1',
            fullName: 'Mihir Gandhi',
            relationship: 'Self',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      expect(result.detectedCategoryCode, DocumentScannerService.catIdentityDocs);
      expect(result.detectedSubcategory, 'Aadhaar Card');
      expect(result.personalFields['personName'], 'Mihir Gandhi');
      expect(result.personalFields['personId'], 'person-1');
    });

    test('Correctly classifies and extracts fields from Appliance Tax Invoice', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      final result = await DocumentScannerService.scanDocument(
        bytes: dummyBytes,
        fileName: 'Havells_Ceiling_Fan_Tax_Invoice_Croma.pdf',
      );

      expect(result.detectedCategoryCode, DocumentScannerService.catApplianceWarranty);
      expect(result.detectedSubcategory, 'Ceiling / Table Fans');
      expect(result.applianceFields['storeVendorName'], contains('Croma'));
      expect(result.title, contains('Havells'));
    });

    test('Extracts embedded text directly from digital PDF bytes and parses fields', () async {
      final pdfDoc = PdfDocument();
      final page = pdfDoc.pages.add();
      page.graphics.drawString(
        'UGVCL - Uttar Gujarat Vij Company Limited\n'
        'Consumer No: CN-9876543210\n'
        'Meter No: MTR-554433\n'
        'Bill Amount: Rs. 4,850.00\n'
        'City: Ahmedabad\n'
        'Pin Code: 380054\n',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
      );
      final pdfBytes = Uint8List.fromList(pdfDoc.saveSync());
      pdfDoc.dispose();

      final result = await DocumentScannerService.scanDocument(
        bytes: pdfBytes,
        fileName: 'scanned_doc.pdf',
        knownCities: ['Ahmedabad', 'Surat'],
      );

      expect(result.detectedCategoryCode, DocumentScannerService.catUtilityBills);
      expect(result.detectedSubcategory, 'Light / Electricity Bill');
      expect(result.amount, 4850.00);
      expect(result.city, 'Ahmedabad');
      expect(result.postalCode, '380054');
      expect(result.documentNumber, 'CN-9876543210');
      expect(result.utilityFields['meterNumber'], 'MTR-554433');
    });

    test('Accurately identifies Go Digit Two-Wheeler Insurance Policy and avoids PUC/RC mismatch', () async {
      final pdfDoc = PdfDocument();
      final page1 = pdfDoc.pages.add();
      page1.graphics.drawString(
        'Go Digit General Insurance Ltd.\n'
        'Digit Two-Wheeler Insurance\n'
        'Schedule/Receipt\n'
        'UIN No.: IRDAN158RPMT0045V01202425\n'
        'Name: MAHESHBHAI VALLABHBHAI GANDHI\n'
        'Vehicle Registration No. GJ03NS8003\n'
        'Address: OM TENAMENT NO 29 GUNJAN VATIKA SOC, Rajkot-360005\n'
        'YOUR POLICY DETAILS\n'
        'Policy No. D303647144 / 18102026\n'
        'Policy Issue Date 18-Oct-2026\n'
        'Period of Policy for Own Damage Cover From 27-Oct-2026 To 26-Oct-2027\n'
        'Make: HONDA   Model: SP 125/OBD2 DISC BSVI\n'
        'Vehicle IDV: 80087\n'
        'Final Premium: 1476.50\n'
        'Net Premium: 1251.27\n'
        'PUC Declaration: The Policy has been issued subject to valid Pollution Under Control Certificate\n',
        PdfStandardFont(PdfFontFamily.helvetica, 10),
      );
      final pdfBytes = Uint8List.fromList(pdfDoc.saveSync());
      pdfDoc.dispose();

      final result = await DocumentScannerService.scanDocument(
        bytes: pdfBytes,
        fileName: 'DG_202031YRAG_SCHEDULESC_D303647144_D303647144_1794666891704.pdf',
        knownCities: ['Rajkot', 'Ahmedabad'],
      );

      // Must NOT be detected as PUC Certificate or RC Book!
      expect(result.detectedCategoryCode, DocumentScannerService.catVehicleDocs);
      expect(result.detectedSubcategory, 'Insurance Policy');
      expect(result.vehicleFields['insuranceCompany'], 'Go Digit General Insurance');
      expect(result.vehicleFields['vehicleNumber'], 'GJ03NS8003');
      // Must NOT be 'DETAILS'
      expect(result.documentNumber, contains('D303647144'));
      expect(result.amount, 1476.50);
      expect(result.city, 'Rajkot');
      expect(result.postalCode, '360005');
    });
  });
}
