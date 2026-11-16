import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_scan_result.dart';
import 'package:kt_prod_kt_docs/app/data/models/personal_document_models.dart';
import 'package:kt_prod_kt_docs/app/data/models/vehicle_document_models.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/file_compressor.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Background worker isolate function for heavy PDF parsing and text extraction.
/// Pure Dart execution offloaded from the main UI isolate on native platforms.
String _extractPdfTextWorker(Uint8List bytes) {
  try {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final int pageCount = document.pages.count;
    if (pageCount == 0) {
      document.dispose();
      return '';
    }

    final extractor = PdfTextExtractor(document);
    final StringBuffer buffer = StringBuffer();

    // Scan up to first 6 pages, plus the last page if document is long
    final Set<int> targetPages = <int>{};
    final int initialPages = pageCount > 6 ? 6 : pageCount;
    for (int i = 0; i < initialPages; i++) {
      targetPages.add(i);
    }
    if (pageCount > 6) {
      targetPages.add(pageCount - 1);
    }

    final sortedPages = targetPages.toList()..sort();
    for (final pageIndex in sortedPages) {
      final pageText = extractor.extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
      if (pageText.isNotEmpty) {
        buffer.writeln(pageText);
      }
    }

    document.dispose();
    return buffer.toString();
  } catch (_) {
    return '';
  }
}

/// Asynchronous, non-blocking PDF text extractor for Flutter Web.
/// Yields to the browser event loop between pages to prevent freezing the UI thread,
/// keeping 60 FPS animations, loaders, and user interactions fluid.
Future<String> _extractPdfTextAsync(
  Uint8List bytes, {
  void Function(double progress)? onProgress,
}) async {
  try {
    // Yield to the browser event loop before loading document
    await Future.delayed(Duration.zero);
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final int pageCount = document.pages.count;
    if (pageCount == 0) {
      document.dispose();
      return '';
    }

    final extractor = PdfTextExtractor(document);
    final StringBuffer buffer = StringBuffer();

    // Scan up to first 6 pages, plus the last page if document is long
    final Set<int> targetPages = <int>{};
    final int initialPages = pageCount > 6 ? 6 : pageCount;
    for (int i = 0; i < initialPages; i++) {
      targetPages.add(i);
    }
    if (pageCount > 6) {
      targetPages.add(pageCount - 1);
    }

    final sortedPages = targetPages.toList()..sort();
    final totalToScan = sortedPages.length;

    for (int idx = 0; idx < totalToScan; idx++) {
      final pageIndex = sortedPages[idx];
      // Yield to the event loop before each page extraction so Flutter can render frames, animations and loaders
      await Future.delayed(Duration.zero);
      final pageText = extractor.extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
      if (pageText.isNotEmpty) {
        buffer.writeln(pageText);
      }
      onProgress?.call((idx + 1) / totalToScan);
    }

    document.dispose();
    return buffer.toString();
  } catch (e) {
    AppLogger.error('SCANNER', 'Async PDF text extraction error: $e');
    return '';
  }
}

class DocumentScannerService {
  DocumentScannerService._();

  static const String catUtilityBills = 'utility_bills';
  static const String catApplianceWarranty = 'appliance_warranty';
  static const String catIdentityDocs = 'identity_docs';
  static const String catVehicleDocs = 'vehicle_docs';
  static const String catGeneral = 'general';

  /// Scans file bytes, extracts text, classifies document type, and parses structured fields.
  static Future<DocumentScanResult> scanDocument({
    required Uint8List bytes,
    required String fileName,
    List<String> knownCities = const [],
    List<MasterPersonModel> knownPersons = const [],
    List<MasterVehicleModel> knownVehicles = const [],
    void Function(double progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('SCANNER', 'Starting document scan for "$fileName" (${bytes.length} bytes)');

    String rawText = '';
    final isPdf = FileCompressor.isPdf(fileName);

    if (isPdf) {
      if (kIsWeb) {
        // Flutter Web runs on a single JS thread. To prevent UI freezing,
        // extract text asynchronously page-by-page and yield to the event loop.
        rawText = await _extractPdfTextAsync(bytes, onProgress: onProgress);
        AppLogger.debug('SCANNER', 'Extracted ${rawText.length} characters from PDF (web async): "$fileName"');
      } else {
        try {
          // Offload heavy PDF parsing to background isolate via compute on native
          rawText = await compute(_extractPdfTextWorker, bytes);
          AppLogger.debug('SCANNER', 'Extracted ${rawText.length} characters from PDF: "$fileName"');
        } catch (e) {
          // Fallback to inline async extraction if compute fails
          rawText = await _extractPdfTextAsync(bytes, onProgress: onProgress);
          AppLogger.debug('SCANNER', 'Extracted ${rawText.length} characters (inline fallback): "$fileName"');
        }
      }
    }

    // If PDF text extraction yielded very little or it's an image, combine with filename tokens
    // Normalize underscores to spaces so token boundaries and name matches work across filenames
    final textToAnalyze = '${fileName.replaceAll('_', ' ')}\n$rawText';

    final result = _classifyAndExtract(
      fileName: fileName,
      rawText: rawText,
      fullText: textToAnalyze,
      knownCities: knownCities,
      knownPersons: knownPersons,
      knownVehicles: knownVehicles,
    );

    AppLogger.info(
      'SCANNER',
      'Completed document scan in ${stopwatch.elapsedMilliseconds}ms. '
      'Detected Category: ${result.detectedCategoryName} (${result.detectedCategoryCode}), '
      'Subcategory: ${result.detectedSubcategory}, Filled Fields: ${result.filledFieldsCount}',
    );

    return result;
  }

  static DocumentScanResult _classifyAndExtract({
    required String fileName,
    required String rawText,
    required String fullText,
    required List<String> knownCities,
    required List<MasterPersonModel> knownPersons,
    required List<MasterVehicleModel> knownVehicles,
  }) {
    final lower = fullText.toLowerCase();

    // 1. Scoring categories based on keyword frequency and patterns
    int utilityScore = 0;
    int applianceScore = 0;
    int identityScore = 0;
    int vehicleScore = 0;

    // Utility scoring indicators
    if (lower.contains('electricity') || lower.contains('light bill') || lower.contains('discom')) utilityScore += 5;
    if (lower.contains('ugvcl') || lower.contains('dgvcl') || lower.contains('pgvcl') || lower.contains('mgvcl')) utilityScore += 8;
    if (lower.contains('torrent power') || lower.contains('adani electricity') || lower.contains('tata power')) utilityScore += 8;
    if (lower.contains('gujarat gas') || lower.contains('adani gas') || lower.contains('adani total gas') || lower.contains('mngl') || lower.contains('mgl') || lower.contains('igl')) utilityScore += 8;
    if (lower.contains('piped natural gas') || lower.contains('png bill') || lower.contains('lpg')) utilityScore += 7;
    if (lower.contains('consumer no') || lower.contains('consumer number') || lower.contains('meter no') || lower.contains('meter number')) utilityScore += 6;
    if (lower.contains('kwh') || lower.contains('units consumed') || lower.contains('bill due date')) utilityScore += 5;
    if (lower.contains('property tax') || lower.contains('amc tax') || lower.contains('house tax') || lower.contains('tenement no')) utilityScore += 8;
    if (lower.contains('water bill') || lower.contains('drainage cess')) utilityScore += 8;
    if (lower.contains('airtel broadband') || lower.contains('jio fiber') || lower.contains('act fibernet') || lower.contains('tata play fiber')) utilityScore += 7;

    // Vehicle scoring indicators
    if (lower.contains('registration certificate') || lower.contains('form 23') || lower.contains('rc book')) vehicleScore += 10;
    if (lower.contains('chassis no') || lower.contains('chassis number') || lower.contains('engine no') || lower.contains('engine number')) vehicleScore += 7;
    if (lower.contains('hdfc ergo') || lower.contains('icici lombard') || lower.contains('bajaj allianz') || lower.contains('tata aig') || lower.contains('go digit') || lower.contains('acko general')) vehicleScore += 8;
    if (lower.contains('motor policy') || lower.contains('two wheeler package') || lower.contains('private car package') || lower.contains('vehicle insurance')) vehicleScore += 9;
    if (lower.contains('puc certificate') || lower.contains('pollution under control') || lower.contains('emission test certificate')) vehicleScore += 10;
    if (lower.contains('fastag') || lower.contains('netc') || lower.contains('toll plaza') || lower.contains('toll pass')) vehicleScore += 10;
    if (lower.contains('service center') || lower.contains('odometer') || lower.contains('engine oil change') || lower.contains('periodic maintenance')) vehicleScore += 7;
    if (RegExp(r'\b[A-Z]{2}[ -]?[0-9]{1,2}[ -]?[A-Z]{1,3}[ -]?[0-9]{4}\b', caseSensitive: false).hasMatch(fullText)) vehicleScore += 5;

    // Identity scoring indicators
    if (lower.contains('unique identification authority of india') || lower.contains('uidai') || lower.contains('aadhaar') || lower.contains('my aadhaar')) identityScore += 10;
    if (RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b').hasMatch(fullText)) identityScore += 8;
    if (lower.contains('income tax department') || lower.contains('permanent account number') || lower.contains('pan card')) identityScore += 10;
    if (RegExp(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b').hasMatch(fullText)) identityScore += 8;
    if (lower.contains('driving licence') || lower.contains('driving license') || lower.contains('motor vehicles act') || lower.contains('transport department')) identityScore += 10;
    if (lower.contains('election commission of india') || lower.contains('voter id') || lower.contains('elector photo')) identityScore += 10;
    if (lower.contains('passport') || lower.contains('republic of india') || lower.contains('ministry of external affairs')) identityScore += 8;

    // Appliance / Warranty scoring indicators
    if (lower.contains('tax invoice') || lower.contains('retail invoice') || lower.contains('cash memo')) applianceScore += 4;
    if (lower.contains('croma') || lower.contains('reliance digital') || lower.contains('vijay sales') || lower.contains('poorvika') || lower.contains('amazon seller') || lower.contains('flipkart')) applianceScore += 7;
    if (lower.contains('warranty card') || lower.contains('warranty certificate') || lower.contains('warranty validity') || lower.contains('guarantee period')) applianceScore += 8;
    if (lower.contains('serial no') || lower.contains('serial number') || lower.contains('sl no') || lower.contains('model no') || lower.contains('model number')) applianceScore += 5;
    if (lower.contains('havells') || lower.contains('samsung') || lower.contains('lg electronics') || lower.contains('daikin') || lower.contains('voltas') || lower.contains('blue star') || lower.contains('crompton') || lower.contains('whirlpool') || lower.contains('ifb') || lower.contains('racold') || lower.contains('ao smith')) applianceScore += 7;
    if (lower.contains('ceiling fan') || lower.contains('air conditioner') || lower.contains('washing machine') || lower.contains('refrigerator') || lower.contains('water heater') || lower.contains('geyser') || lower.contains('laptop')) applianceScore += 6;

    // Common Extracted Values
    final amounts = _extractAmounts(fullText);
    final primaryAmount = amounts.isNotEmpty ? amounts.first : null;
    final dates = _extractDates(fullText);
    final primaryDate = dates.isNotEmpty ? dates.first : null;
    final secondaryDate = dates.length > 1 ? dates[1] : null;

    final detectedCity = _extractCity(fullText, knownCities);
    final postalCode = _extractPostalCode(fullText);
    final areaLocality = _extractArea(fullText);

    // Determine winning category
    String catCode = catGeneral;
    String catName = 'General Document';
    String subCat = 'General Record';
    double confidence = 0.5;

    final maxScore = [utilityScore, applianceScore, identityScore, vehicleScore].reduce((a, b) => a > b ? a : b);

    if (maxScore >= 4) {
      if (maxScore == identityScore) {
        catCode = catIdentityDocs;
        catName = 'Personal & Identity Documents';
        confidence = (identityScore / 15.0).clamp(0.65, 0.98);
        return _buildIdentityResult(
          fullText: fullText,
          lower: lower,
          confidence: confidence,
          catCode: catCode,
          catName: catName,
          rawText: rawText,
          knownPersons: knownPersons,
          detectedCity: detectedCity,
          postalCode: postalCode,
          dates: dates,
        );
      } else if (maxScore == vehicleScore) {
        catCode = catVehicleDocs;
        catName = 'Vehicle Vault & Fleet Documents';
        confidence = (vehicleScore / 15.0).clamp(0.65, 0.98);
        return _buildVehicleResult(
          fullText: fullText,
          lower: lower,
          confidence: confidence,
          catCode: catCode,
          catName: catName,
          rawText: rawText,
          knownVehicles: knownVehicles,
          detectedCity: detectedCity,
          postalCode: postalCode,
          amounts: amounts,
          dates: dates,
        );
      } else if (maxScore == utilityScore) {
        catCode = catUtilityBills;
        catName = 'Utility Bills';
        confidence = (utilityScore / 15.0).clamp(0.65, 0.98);
        return _buildUtilityResult(
          fullText: fullText,
          lower: lower,
          confidence: confidence,
          catCode: catCode,
          catName: catName,
          rawText: rawText,
          detectedCity: detectedCity,
          postalCode: postalCode,
          areaLocality: areaLocality,
          amounts: amounts,
          dates: dates,
        );
      } else if (maxScore == applianceScore) {
        catCode = catApplianceWarranty;
        catName = 'Appliance Invoices & Warranty';
        confidence = (applianceScore / 15.0).clamp(0.65, 0.98);
        return _buildApplianceResult(
          fullText: fullText,
          lower: lower,
          confidence: confidence,
          catCode: catCode,
          catName: catName,
          rawText: rawText,
          detectedCity: detectedCity,
          postalCode: postalCode,
          amounts: amounts,
          dates: dates,
        );
      }
    }

    // Fallback General Result
    String cleanTitle = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').replaceAll('_', ' ').replaceAll('-', ' ');
    return DocumentScanResult(
      detectedCategoryCode: catCode,
      detectedCategoryName: catName,
      detectedSubcategory: subCat,
      confidence: confidence,
      title: cleanTitle,
      amount: primaryAmount,
      primaryDate: primaryDate,
      secondaryDate: secondaryDate,
      city: detectedCity,
      postalCode: postalCode,
      areaLocality: areaLocality,
      rawText: rawText,
    );
  }

  // -------------------------------------------------------------
  // Category-Specific Parsers
  // -------------------------------------------------------------

  static DocumentScanResult _buildUtilityResult({
    required String fullText,
    required String lower,
    required double confidence,
    required String catCode,
    required String catName,
    required String rawText,
    required String? detectedCity,
    required String? postalCode,
    required String? areaLocality,
    required List<double> amounts,
    required List<DateTime> dates,
  }) {
    String subcategory = 'Light / Electricity Bill';
    String providerName = '';

    if (lower.contains('ugvcl')) {
      providerName = 'UGVCL (Uttar Gujarat Vij)';
      subcategory = 'Light / Electricity Bill';
    } else if (lower.contains('torrent power')) {
      providerName = 'Torrent Power';
      subcategory = 'Light / Electricity Bill';
    } else if (lower.contains('dgvcl')) {
      providerName = 'DGVCL (Dakshin Gujarat Vij)';
      subcategory = 'Light / Electricity Bill';
    } else if (lower.contains('pgvcl')) {
      providerName = 'PGVCL (Paschim Gujarat Vij)';
      subcategory = 'Light / Electricity Bill';
    } else if (lower.contains('mgvcl')) {
      providerName = 'MGVCL (Madhya Gujarat Vij)';
      subcategory = 'Light / Electricity Bill';
    } else if (lower.contains('adani electricity')) {
      providerName = 'Adani Electricity';
      subcategory = 'Light / Electricity Bill';
    } else if (lower.contains('gujarat gas')) {
      providerName = 'Gujarat Gas Limited';
      subcategory = 'Gas Bill (PNG / Piped)';
    } else if (lower.contains('adani gas') || lower.contains('adani total gas')) {
      providerName = 'Adani Total Gas';
      subcategory = 'Gas Bill (PNG / Piped)';
    } else if (lower.contains('mngl') || lower.contains('maharashtra natural gas')) {
      providerName = 'MNGL (Maharashtra Natural Gas)';
      subcategory = 'Gas Bill (PNG / Piped)';
    } else if (lower.contains('mgl') || lower.contains('mahanagar gas')) {
      providerName = 'Mahanagar Gas (MGL)';
      subcategory = 'Gas Bill (PNG / Piped)';
    } else if (lower.contains('property tax') || lower.contains('amc tax') || lower.contains('house tax')) {
      subcategory = 'Property Tax / House Tax';
      providerName = lower.contains('amc') || lower.contains('ahmedabad')
          ? 'Ahmedabad Municipal Corporation'
          : 'Municipal Corporation';
    } else if (lower.contains('water bill') || lower.contains('drainage')) {
      subcategory = 'Water & Drainage Bill';
      providerName = 'Municipal Corporation';
    } else if (lower.contains('airtel')) {
      subcategory = 'Internet / Broadband Bill';
      providerName = 'Airtel Broadband / Xstream';
    } else if (lower.contains('jio fiber') || lower.contains('jiofiber')) {
      subcategory = 'Internet / Broadband Bill';
      providerName = 'JioFiber';
    } else if (lower.contains('act fibernet')) {
      subcategory = 'Internet / Broadband Bill';
      providerName = 'ACT Fibernet';
    } else if (lower.contains('lpg') || lower.contains('cylinder')) {
      subcategory = 'Gas Cylinder (LPG)';
      providerName = lower.contains('indane')
          ? 'Indane Gas'
          : (lower.contains('bharat') ? 'Bharat Gas' : 'HP Gas');
    }

    final consumerNumber = _extractRegex(
      fullText,
      [
        r'Consumer\s*(?:No|Number|ID|#)?[:\s\.-]*([A-Z0-9\/-]{5,25})',
        r'Connection\s*(?:No|Number|ID)?[:\s\.-]*([A-Z0-9\/-]{5,25})',
        r'Account\s*(?:No|Number)?[:\s\.-]*([A-Z0-9\/-]{5,25})',
        r'Customer\s*(?:No|Number|ID)?[:\s\.-]*([A-Z0-9\/-]{5,25})',
        r'Tenement\s*(?:No|Number)?[:\s\.-]*([A-Z0-9\/-]{5,25})',
      ],
    );

    final meterNumber = _extractRegex(
      fullText,
      [
        r'Meter\s*(?:No|Number|ID|#)?[:\s\.-]*([A-Z0-9\/-]{5,20})',
      ],
    );

    final billAmount = amounts.isNotEmpty ? amounts.first : null;
    final billDate = dates.isNotEmpty ? dates.first : null;
    final dueDate = dates.length > 1 ? dates[1] : billDate?.add(const Duration(days: 15));

    final docTitle = providerName.isNotEmpty
        ? '$providerName - $subcategory'
        : 'Utility Bill - $subcategory';

    return DocumentScanResult(
      detectedCategoryCode: catCode,
      detectedCategoryName: catName,
      detectedSubcategory: subcategory,
      confidence: confidence,
      title: docTitle,
      documentNumber: consumerNumber,
      amount: billAmount,
      primaryDate: billDate,
      secondaryDate: dueDate,
      city: detectedCity,
      postalCode: postalCode,
      areaLocality: areaLocality,
      utilityFields: {
        'providerName': providerName,
        'consumerNumber': consumerNumber,
        'meterNumber': meterNumber,
        'billAmount': billAmount,
        'billDate': billDate,
        'dueDate': dueDate,
      },
      rawText: rawText,
    );
  }

  static DocumentScanResult _buildIdentityResult({
    required String fullText,
    required String lower,
    required double confidence,
    required String catCode,
    required String catName,
    required String rawText,
    required List<MasterPersonModel> knownPersons,
    required String? detectedCity,
    required String? postalCode,
    required List<DateTime> dates,
  }) {
    String subcategory = 'Aadhaar Card';
    String? idNumber;
    String authority = 'Government of India';

    if (lower.contains('aadhaar') || lower.contains('uidai') || lower.contains('unique identification')) {
      subcategory = 'Aadhaar Card';
      authority = 'Unique Identification Authority of India (UIDAI)';
      final match = RegExp(r'\b(\d{4}\s\d{4}\s\d{4})\b').firstMatch(fullText);
      idNumber = match?.group(1);
    } else if (lower.contains('permanent account number') || lower.contains('pan card') || lower.contains('income tax department')) {
      subcategory = 'PAN Card';
      authority = 'Income Tax Department, Government of India';
      final match = RegExp(r'\b([A-Z]{5}[0-9]{4}[A-Z])\b').firstMatch(fullText);
      idNumber = match?.group(1);
    } else if (lower.contains('driving licence') || lower.contains('driving license')) {
      subcategory = 'Driving License';
      authority = 'Transport Department';
      final match = RegExp(r'\b([A-Z]{2}[0-9]{2}\s?[0-9]{11})\b').firstMatch(fullText);
      idNumber = match?.group(1);
    } else if (lower.contains('passport')) {
      subcategory = 'Passport';
      authority = 'Ministry of External Affairs, India';
      final match = RegExp(r'\b([A-Z][0-9]{7})\b').firstMatch(fullText);
      idNumber = match?.group(1);
    } else if (lower.contains('election') || lower.contains('voter')) {
      subcategory = 'Voter ID (Election Card)';
      authority = 'Election Commission of India';
      final match = RegExp(r'\b([A-Z]{3}[0-9]{7})\b').firstMatch(fullText);
      idNumber = match?.group(1);
    }

    // Match person against known dynamic persons
    String? matchedPersonName;
    String? matchedPersonId;
    for (var person in knownPersons) {
      if (lower.contains(person.fullName.toLowerCase())) {
        matchedPersonName = person.fullName;
        matchedPersonId = person.id;
        break;
      }
    }

    final issueDate = dates.isNotEmpty ? dates.first : null;
    final expiryDate = dates.length > 1 ? dates[1] : null;

    final docTitle = matchedPersonName != null
        ? '$subcategory - $matchedPersonName'
        : subcategory;

    return DocumentScanResult(
      detectedCategoryCode: catCode,
      detectedCategoryName: catName,
      detectedSubcategory: subcategory,
      confidence: confidence,
      title: docTitle,
      documentNumber: idNumber,
      primaryDate: issueDate,
      secondaryDate: expiryDate,
      city: detectedCity,
      postalCode: postalCode,
      personalFields: {
        'personId': matchedPersonId,
        'personName': matchedPersonName,
        'docTypeName': subcategory,
        'idNumber': idNumber,
        'issueDate': issueDate,
        'expiryDate': expiryDate,
        'issuingAuthority': authority,
      },
      rawText: rawText,
    );
  }

  static DocumentScanResult _buildVehicleResult({
    required String fullText,
    required String lower,
    required double confidence,
    required String catCode,
    required String catName,
    required String rawText,
    required List<MasterVehicleModel> knownVehicles,
    required String? detectedCity,
    required String? postalCode,
    required List<double> amounts,
    required List<DateTime> dates,
  }) {
    String subcategory = 'Insurance Policy';
    String? insuranceCompany;
    String? vehicleNumber;
    String? policyNumber;

    // Detect Insurance Company
    if (lower.contains('hdfc ergo')) {
      insuranceCompany = 'HDFC ERGO General Insurance';
    } else if (lower.contains('icici lombard')) {
      insuranceCompany = 'ICICI Lombard General Insurance';
    } else if (lower.contains('bajaj allianz')) {
      insuranceCompany = 'Bajaj Allianz General Insurance';
    } else if (lower.contains('tata aig')) {
      insuranceCompany = 'Tata AIG General Insurance';
    } else if (lower.contains('go digit') ||
        lower.contains('digit insurance') ||
        lower.contains('digit two-wheeler') ||
        lower.contains('godigit')) {
      insuranceCompany = 'Go Digit General Insurance';
    } else if (lower.contains('acko')) {
      insuranceCompany = 'Acko General Insurance';
    } else if (lower.contains('new india assurance')) {
      insuranceCompany = 'New India Assurance';
    } else if (lower.contains('sbi general')) {
      insuranceCompany = 'SBI General Insurance';
    }

    // Vehicle Number extraction (e.g. GJ03NS8003, GJ-03-NS-8003)
    final vehiclePlateMatch = RegExp(
      r'\b([A-Z]{2}[ -]?[0-9]{1,2}[ -]?[A-Z]{1,3}[ -]?[0-9]{4})\b',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (vehiclePlateMatch != null) {
      vehicleNumber = vehiclePlateMatch
          .group(1)!
          .toUpperCase()
          .replaceAll(' ', '')
          .replaceAll('--', '-');
    }

    // Check against known vehicles
    MasterVehicleModel? matchedVehicle;
    if (vehicleNumber != null) {
      final cleanVeh = vehicleNumber.replaceAll('-', '').replaceAll(' ', '');
      for (final v in knownVehicles) {
        if (v.vehicleNumber.replaceAll('-', '').replaceAll(' ', '').toUpperCase() == cleanVeh) {
          matchedVehicle = v;
          vehicleNumber = v.vehicleNumber;
          break;
        }
      }
    }

    // Subcategory classification
    final isInsurance = lower.contains('insurance') ||
        lower.contains('policy') ||
        lower.contains('schedule/receipt') ||
        lower.contains('own damage') ||
        lower.contains('third party') ||
        lower.contains('idv') ||
        lower.contains('uin no') ||
        lower.contains('irda') ||
        lower.contains('digit') ||
        lower.contains('premium') ||
        insuranceCompany != null;

    if (isInsurance) {
      subcategory = 'Insurance Policy';
    } else if (lower.contains('puc certificate') ||
        (lower.contains('pollution under control') && lower.contains('certificate')) ||
        lower.contains('emission test certificate')) {
      subcategory = 'PUC Certificate';
    } else if (lower.contains('registration certificate') ||
        lower.contains('rc book') ||
        lower.contains('form 23') ||
        lower.contains('certificate of registration')) {
      subcategory = 'RC Book (Registration Certificate)';
    } else if (lower.contains('fastag') ||
        lower.contains('toll pass') ||
        lower.contains('netc')) {
      subcategory = 'Fastag / Toll Pass';
    } else if (lower.contains('service center') ||
        lower.contains('workshop') ||
        lower.contains('periodic maintenance') ||
        lower.contains('odometer reading')) {
      subcategory = 'Service & Maintenance Bill';
    } else {
      subcategory = 'Insurance Policy';
    }

    // Policy Number extraction (MUST contain digits and not be keywords like DETAILS)
    final policyMatches = RegExp(
      r'Policy\s*(?:No|Number|#)?\.?[:\s\.-]*([A-Z0-9][A-Z0-9\/-]{4,25}(?:\s*\/\s*[A-Z0-9]+)?)',
      caseSensitive: false,
    ).allMatches(fullText);

    const blacklistedWords = {
      'DETAILS', 'PERIOD', 'SCHEDULE', 'HOLDER', 'TYPE',
      'COVER', 'STATUS', 'RECEIPT', 'WORDINGS', 'DOCUMENT', 'SUMMARY', 'ISSUE'
    };

    for (final m in policyMatches) {
      final candidate = m.group(1)?.trim();
      if (candidate != null &&
          candidate.isNotEmpty &&
          RegExp(r'\d').hasMatch(candidate) &&
          !blacklistedWords.contains(candidate.toUpperCase())) {
        policyNumber = candidate;
        break;
      }
    }

    if (policyNumber == null) {
      final certMatches = RegExp(
        r'Certificate\s*(?:No|Number|#)?\.?[:\s\.-]*([A-Z0-9][A-Z0-9\/-]{4,25})',
        caseSensitive: false,
      ).allMatches(fullText);

      for (final m in certMatches) {
        final candidate = m.group(1)?.trim();
        if (candidate != null &&
            candidate.isNotEmpty &&
            RegExp(r'\d').hasMatch(candidate) &&
            !blacklistedWords.contains(candidate.toUpperCase())) {
          policyNumber = candidate;
          break;
        }
      }
    }

    // Premium Amount extraction (Prioritize Final / Net / Gross Premium over IDV)
    double? detectedPremium;
    final premiumRegex = RegExp(
      r"(?:Final Premium|Gross Premium|Total Premium|Net Premium|Total OD Premium|Own Damage Premium)[:\s]*₹?\s*\(?[`']?\)?\s*([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)",
      caseSensitive: false,
    ).firstMatch(fullText);

    if (premiumRegex != null) {
      final raw = premiumRegex.group(1)?.replaceAll(',', '').trim();
      if (raw != null) detectedPremium = double.tryParse(raw);
    }

    final premiumAmount = detectedPremium ?? (amounts.isNotEmpty ? amounts.first : null);

    // Period / Dates extraction
    DateTime? issueDate;
    DateTime? expiryDate;

    final fromDateMatch = RegExp(
      r'(?:From|Period of Policy.*?From|Policy Issue Date)[:\s]*(\d{1,2}[-\/\.][A-Za-z0-9]+[-\/\.]\d{4})',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (fromDateMatch != null) {
      final raw = fromDateMatch.group(1);
      if (raw != null) {
        issueDate = _tryParseDateString(raw);
      }
    }

    final toDateMatch = RegExp(
      r'(?:To|Policy Expiry Date|Valid Upto)[:\s]*(\d{1,2}[-\/\.][A-Za-z0-9]+[-\/\.]\d{4})',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (toDateMatch != null) {
      final raw = toDateMatch.group(1);
      if (raw != null) {
        expiryDate = _tryParseDateString(raw);
      }
    }

    issueDate ??= dates.isNotEmpty ? dates.first : null;
    expiryDate ??= dates.length > 1
        ? dates[1]
        : issueDate?.add(const Duration(days: 365));

    final docTitle = vehicleNumber != null
        ? '$subcategory - $vehicleNumber'
        : subcategory;

    return DocumentScanResult(
      detectedCategoryCode: catCode,
      detectedCategoryName: catName,
      detectedSubcategory: subcategory,
      confidence: confidence,
      title: docTitle,
      documentNumber: policyNumber,
      amount: premiumAmount,
      primaryDate: issueDate,
      secondaryDate: expiryDate,
      city: detectedCity,
      postalCode: postalCode,
      vehicleFields: {
        'vehicleId': matchedVehicle?.id.isNotEmpty == true ? matchedVehicle?.id : null,
        'vehicleNumber': vehicleNumber ?? matchedVehicle?.vehicleNumber,
        'vehicleName': matchedVehicle?.displayName,
        'docTypeName': subcategory,
        'policyOrCertNumber': policyNumber,
        'insuranceCompany': insuranceCompany,
        'premiumAmount': premiumAmount,
        'issueDate': issueDate,
        'expiryDate': expiryDate,
      },
      rawText: rawText,
    );
  }

  static DateTime? _tryParseDateString(String text) {
    final clean = text.trim();
    final formats = [
      'dd-MMM-yyyy',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'dd MMM yyyy',
      'd-MMM-yyyy',
      'd/M/yyyy',
    ];
    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parseLoose(clean);
      } catch (_) {}
    }
    return null;
  }

  static DocumentScanResult _buildApplianceResult({
    required String fullText,
    required String lower,
    required double confidence,
    required String catCode,
    required String catName,
    required String rawText,
    required String? detectedCity,
    required String? postalCode,
    required List<double> amounts,
    required List<DateTime> dates,
  }) {
    String subcategory = 'Ceiling / Table Fans';
    String? detectedBrand;
    String? storeVendorName;

    // Detect Store / Vendor
    if (lower.contains('croma')) {
      storeVendorName = 'Croma (Infiniti Retail)';
    } else if (lower.contains('reliance digital')) {
      storeVendorName = 'Reliance Digital';
    } else if (lower.contains('vijay sales')) {
      storeVendorName = 'Vijay Sales';
    } else if (lower.contains('amazon')) {
      storeVendorName = 'Amazon India (Authorized Seller)';
    } else if (lower.contains('flipkart')) {
      storeVendorName = 'Flipkart Internet';
    }

    // Detect Brand
    final brands = [
      'Havells', 'Samsung', 'LG', 'Voltas', 'Daikin', 'Blue Star', 'Crompton',
      'Whirlpool', 'IFB', 'Philips', 'Sony', 'Apple', 'Dell', 'HP', 'Lenovo',
      'Racold', 'AO Smith', 'Bajaj', 'Orient', 'Usha'
    ];
    for (var b in brands) {
      if (lower.contains(b.toLowerCase())) {
        detectedBrand = b;
        break;
      }
    }

    // Detect Appliance Subcategory
    if (lower.contains('fan') || lower.contains('ceiling fan')) {
      subcategory = 'Ceiling / Table Fans';
    } else if (lower.contains('air conditioner') || lower.contains(' ac ') || lower.contains('split ac')) {
      subcategory = 'Air Conditioners (AC)';
    } else if (lower.contains('washing machine') || lower.contains('dryer')) {
      subcategory = 'Washing Machines';
    } else if (lower.contains('refrigerator') || lower.contains('fridge')) {
      subcategory = 'Refrigerators';
    } else if (lower.contains('geyser') || lower.contains('water heater')) {
      subcategory = 'Geysers / Water Heaters';
    } else if (lower.contains('laptop') || lower.contains('computer') || lower.contains('notebook')) {
      subcategory = 'Laptops & Computers';
    } else if (lower.contains('television') || lower.contains(' tv ') || lower.contains('led tv')) {
      subcategory = 'Televisions (TV)';
    } else if (lower.contains('microwave') || lower.contains('oven')) {
      subcategory = 'Microwave & Kitchen Appliances';
    }

    final invoiceNumber = _extractRegex(
      fullText,
      [
        r'Invoice\s*(?:No|Number|#)?[:\s\.-]*([A-Z0-9\/-]{5,25})',
        r'Bill\s*(?:No|Number|#)?[:\s\.-]*([A-Z0-9\/-]{5,25})',
      ],
    );

    final serialNumber = _extractRegex(
      fullText,
      [
        r'Serial\s*(?:No|Number|ID|#)?[:\s\.-]*([A-Z0-9]{6,25})',
        r'S\/N[:\s\.-]*([A-Z0-9]{6,25})',
      ],
    );

    final modelNumber = _extractRegex(
      fullText,
      [
        r'Model\s*(?:No|Number|#)?[:\s\.-]*([A-Z0-9\/-]{4,20})',
      ],
    );

    final purchaseAmount = amounts.isNotEmpty ? amounts.first : null;
    final purchaseDate = dates.isNotEmpty ? dates.first : null;
    final warrantyValidUpto = purchaseDate != null
        ? purchaseDate.add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 365));

    final docTitle = detectedBrand != null
        ? '$detectedBrand $subcategory Invoice'
        : 'Invoice - $subcategory';

    return DocumentScanResult(
      detectedCategoryCode: catCode,
      detectedCategoryName: catName,
      detectedSubcategory: subcategory,
      confidence: confidence,
      title: docTitle,
      documentNumber: invoiceNumber,
      amount: purchaseAmount,
      primaryDate: purchaseDate,
      secondaryDate: warrantyValidUpto,
      city: detectedCity,
      postalCode: postalCode,
      applianceFields: {
        'storeVendorName': storeVendorName,
        'invoiceNumber': invoiceNumber,
        'purchaseAmount': purchaseAmount,
        'purchaseDate': purchaseDate,
        'items': [
          {
            'productName': docTitle,
            'category': subcategory,
            'brand': detectedBrand ?? 'Havells',
            'modelNumber': modelNumber,
            'serialNumber': serialNumber,
            'purchaseAmount': purchaseAmount,
            'warrantyMonths': 12,
            'warrantyValidUpto': warrantyValidUpto,
          }
        ],
      },
      rawText: rawText,
    );
  }

  // -------------------------------------------------------------
  // Value Extraction Helpers
  // -------------------------------------------------------------

  static List<double> _extractAmounts(String text) {
    final amounts = <double>[];
    final patterns = [
      r'(?:Total|Amount|Payable|Net|Due|Paid|Rs\.?|₹|INR)[:\s]*₹?\s*([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)',
      r'₹\s*([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)',
      r'Rs\.?\s*([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)',
    ];

    for (var pattern in patterns) {
      final matches = RegExp(pattern, caseSensitive: false).allMatches(text);
      for (var m in matches) {
        final raw = m.group(1)?.replaceAll(',', '').trim();
        if (raw != null) {
          final val = double.tryParse(raw);
          if (val != null && val > 0 && !amounts.contains(val)) {
            amounts.add(val);
          }
        }
      }
    }
    return amounts;
  }

  static List<DateTime> _extractDates(String text) {
    final dates = <DateTime>[];
    final patterns = [
      r'\b(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{4})\b', // DD/MM/YYYY
      r'\b(\d{4})[\/\.-](\d{1,2})[\/\.-](\d{1,2})\b', // YYYY/MM/DD
      r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s,]+(\d{4})\b', // DD MMM YYYY
    ];

    // DD/MM/YYYY
    final ddmmyyyy = RegExp(patterns[0]).allMatches(text);
    for (var m in ddmmyyyy) {
      final day = int.tryParse(m.group(1) ?? '');
      final month = int.tryParse(m.group(2) ?? '');
      final year = int.tryParse(m.group(3) ?? '');
      if (day != null && month != null && year != null && year >= 1990 && year <= 2040 && month <= 12 && day <= 31) {
        try {
          final dt = DateTime(year, month, day);
          if (!dates.contains(dt)) dates.add(dt);
        } catch (_) {}
      }
    }

    // YYYY/MM/DD
    final yyyymmdd = RegExp(patterns[1]).allMatches(text);
    for (var m in yyyymmdd) {
      final year = int.tryParse(m.group(1) ?? '');
      final month = int.tryParse(m.group(2) ?? '');
      final day = int.tryParse(m.group(3) ?? '');
      if (day != null && month != null && year != null && year >= 1990 && year <= 2040 && month <= 12 && day <= 31) {
        try {
          final dt = DateTime(year, month, day);
          if (!dates.contains(dt)) dates.add(dt);
        } catch (_) {}
      }
    }

    // DD MMM YYYY
    final ddMmmYyyy = RegExp(patterns[2], caseSensitive: false).allMatches(text);
    for (var m in ddMmmYyyy) {
      final day = int.tryParse(m.group(1) ?? '');
      final monStr = m.group(2) ?? '';
      final year = int.tryParse(m.group(3) ?? '');
      if (day != null && year != null && year >= 1990 && year <= 2040) {
        try {
          final parsed = DateFormat('dd MMM yyyy').parseLoose('$day $monStr $year');
          if (!dates.contains(parsed)) dates.add(parsed);
        } catch (_) {}
      }
    }

    return dates;
  }

  static String? _extractCity(String text, List<String> knownCities) {
    final lower = text.toLowerCase();
    for (var city in knownCities) {
      if (city.toLowerCase() != 'all cities' && lower.contains(city.toLowerCase())) {
        return city;
      }
    }

    final defaultCities = [
      'Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Gandhinagar',
      'Bhavnagar', 'Jamnagar', 'Mumbai', 'Pune', 'Delhi', 'Bengaluru', 'Hyderabad'
    ];
    for (var city in defaultCities) {
      if (lower.contains(city.toLowerCase())) {
        return city;
      }
    }
    return null;
  }

  static String? _extractPostalCode(String text) {
    // 1. Explicit Postal/PIN prefix (high confidence)
    final explicitMatch = RegExp(
      r'(?:PIN|Pincode|Pin Code|Postal Code|Postal|Zip|Zipcode)[:\s-]*([1-9][0-9]{5})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (explicitMatch != null) return explicitMatch.group(1);

    // 2. Fallback to standard 6-digit Indian PIN code format
    final match = RegExp(r'\b([1-9][0-9]{5})\b').firstMatch(text);
    return match?.group(1);
  }

  static String? _extractArea(String text) {
    final match = RegExp(
      r'(?:Area|Locality|Society|Road|Cross Road|Nagar|Colony)[:\s]*([A-Za-z0-9\s,-]{4,25})',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1)?.trim();
  }

  static String? _extractRegex(String text, List<String> regexList) {
    for (var r in regexList) {
      final match = RegExp(r, caseSensitive: false).firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final val = match.group(1)?.trim();
        if (val != null && val.isNotEmpty) return val;
      }
    }
    return null;
  }
}
