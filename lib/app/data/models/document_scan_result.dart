class DocumentScanResult {
  final String detectedCategoryCode; // 'utility_bills', 'appliance_warranty', 'identity_docs', 'vehicle_docs', 'general'
  final String detectedCategoryName;
  final String detectedSubcategory;
  final double confidence; // 0.0 to 1.0

  // Common Extracted Fields
  final String? title;
  final String? documentNumber;
  final double? amount;
  final DateTime? primaryDate; // Bill date, purchase date, issue date
  final DateTime? secondaryDate; // Due date, warranty valid upto, expiry date

  // Address Details
  final String? city;
  final String? state;
  final String? postalCode;
  final String? areaLocality;
  final String? fullAddress;

  // Domain Specific Extracted Fields
  final Map<String, dynamic> utilityFields;
  final Map<String, dynamic> applianceFields;
  final Map<String, dynamic> personalFields;
  final Map<String, dynamic> vehicleFields;

  // Extracted Raw Text
  final String rawText;

  const DocumentScanResult({
    required this.detectedCategoryCode,
    required this.detectedCategoryName,
    required this.detectedSubcategory,
    this.confidence = 0.8,
    this.title,
    this.documentNumber,
    this.amount,
    this.primaryDate,
    this.secondaryDate,
    this.city,
    this.state,
    this.postalCode,
    this.areaLocality,
    this.fullAddress,
    this.utilityFields = const {},
    this.applianceFields = const {},
    this.personalFields = const {},
    this.vehicleFields = const {},
    required this.rawText,
  });

  bool get hasContent => rawText.trim().isNotEmpty;

  int get filledFieldsCount {
    int count = 0;
    if (title != null && title!.isNotEmpty) count++;
    if (documentNumber != null && documentNumber!.isNotEmpty) count++;
    if (amount != null && amount! > 0) count++;
    if (primaryDate != null) count++;
    if (secondaryDate != null) count++;
    if (city != null && city!.isNotEmpty) count++;
    if (postalCode != null && postalCode!.isNotEmpty) count++;
    count += utilityFields.length;
    count += applianceFields.length;
    count += personalFields.length;
    count += vehicleFields.length;
    return count;
  }
}
