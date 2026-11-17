import 'package:uuid/uuid.dart';

class ApplianceItemModel {
  final String id;
  final String productName;
  final String productCategory;
  final String brand;
  final String? modelNumber;
  final String? serialNumber;
  final double purchaseAmount;
  final int warrantyPeriodMonths;
  final DateTime warrantyValidUpto;
  final DateTime? extendedWarrantyUpto;
  final String? customerCareNumber;
  final String warrantyStatus; // 'active', 'expiring_soon', 'expired', 'no_warranty'
  final String? warrantyType; // 'standard', 'extended', 'amc', 'component', 'lifetime', 'no_warranty'
  final String? policyNumber;
  final String? amcProvider;

  ApplianceItemModel({
    String? id,
    required this.productName,
    required this.productCategory,
    required this.brand,
    this.modelNumber,
    this.serialNumber,
    this.purchaseAmount = 0.0,
    required this.warrantyPeriodMonths,
    required this.warrantyValidUpto,
    this.extendedWarrantyUpto,
    this.customerCareNumber,
    this.warrantyStatus = 'active',
    this.warrantyType = 'standard',
    this.policyNumber,
    this.amcProvider,
  }) : id = id ?? const Uuid().v4();

  DateTime get effectiveValidUpto => extendedWarrantyUpto ?? warrantyValidUpto;

  bool get isLifetime => warrantyType == 'lifetime';

  bool get hasWarranty =>
      isLifetime || (warrantyPeriodMonths > 0 && warrantyStatus != 'no_warranty' && warrantyType != 'no_warranty');

  bool get isExpired {
    if (!hasWarranty || isLifetime) return false;
    return effectiveValidUpto.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (!hasWarranty || isLifetime) return false;
    final now = DateTime.now();
    final diff = effectiveValidUpto.difference(now).inDays;
    return diff >= 0 && diff <= 30;
  }

  int get remainingDays {
    if (isLifetime) return 9999;
    if (!hasWarranty) return 0;
    final now = DateTime.now();
    return effectiveValidUpto.difference(now).inDays;
  }

  int get daysUntilExpiry => remainingDays;

  String get warrantyStatusDisplay {
    if (isLifetime) return 'LIFETIME';
    if (!hasWarranty || warrantyStatus == 'no_warranty' || warrantyType == 'no_warranty') {
      return 'NO WARRANTY';
    }
    if (warrantyType == 'amc') {
      if (isExpired) return 'AMC EXPIRED';
      if (isExpiringSoon) return 'AMC EXPIRING';
      return 'AMC ACTIVE';
    }
    if (warrantyType == 'extended' || extendedWarrantyUpto != null) {
      if (isExpired) return 'EXT EXPIRED';
      if (isExpiringSoon) return 'EXT EXPIRING';
      return 'EXT ACTIVE';
    }
    if (warrantyType == 'component') {
      if (isExpired) return 'PART EXPIRED';
      if (isExpiringSoon) return 'PART EXPIRING';
      return 'PART ACTIVE';
    }
    if (isExpired) return 'EXPIRED';
    if (isExpiringSoon) return 'EXPIRING SOON';
    return 'ACTIVE';
  }

  ApplianceItemModel copyWith({
    String? id,
    String? productName,
    String? productCategory,
    String? brand,
    String? modelNumber,
    String? serialNumber,
    double? purchaseAmount,
    int? warrantyPeriodMonths,
    DateTime? warrantyValidUpto,
    DateTime? extendedWarrantyUpto,
    String? customerCareNumber,
    String? warrantyStatus,
    String? warrantyType,
    String? policyNumber,
    String? amcProvider,
  }) {
    return ApplianceItemModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productCategory: productCategory ?? this.productCategory,
      brand: brand ?? this.brand,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseAmount: purchaseAmount ?? this.purchaseAmount,
      warrantyPeriodMonths: warrantyPeriodMonths ?? this.warrantyPeriodMonths,
      warrantyValidUpto: warrantyValidUpto ?? this.warrantyValidUpto,
      extendedWarrantyUpto: extendedWarrantyUpto ?? this.extendedWarrantyUpto,
      customerCareNumber: customerCareNumber ?? this.customerCareNumber,
      warrantyStatus: warrantyStatus ?? this.warrantyStatus,
      warrantyType: warrantyType ?? this.warrantyType,
      policyNumber: policyNumber ?? this.policyNumber,
      amcProvider: amcProvider ?? this.amcProvider,
    );
  }

  factory ApplianceItemModel.fromJson(Map<String, dynamic> json) {
    final validUpto = json['warranty_valid_upto'] != null
        ? DateTime.parse(json['warranty_valid_upto'] as String)
        : DateTime.now();
    final extUpto = json['extended_warranty_upto'] != null
        ? DateTime.parse(json['extended_warranty_upto'] as String)
        : null;
    final periodMonths =
        (json['warranty_period_months'] as num?)?.toInt() ?? 12;
    final wType = json['warranty_type'] as String? ?? 'standard';

    final effectiveDate = extUpto ?? validUpto;
    String computedStatus = 'active';
    if (json['warranty_status'] == 'no_warranty' || periodMonths == 0 || wType == 'no_warranty') {
      computedStatus = 'no_warranty';
    } else if (wType == 'lifetime') {
      computedStatus = 'active';
    } else if (effectiveDate.isBefore(DateTime.now())) {
      computedStatus = 'expired';
    } else if (effectiveDate.difference(DateTime.now()).inDays <= 30) {
      computedStatus = 'expiring_soon';
    }

    return ApplianceItemModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      productName: json['product_name'] as String? ?? 'Appliance Product',
      productCategory: json['product_category'] as String? ?? 'Appliances',
      brand: json['brand'] as String? ?? 'Generic',
      modelNumber: json['model_number'] as String?,
      serialNumber: json['serial_number'] as String?,
      purchaseAmount: (json['purchase_amount'] as num?)?.toDouble() ?? 0.0,
      warrantyPeriodMonths: periodMonths,
      warrantyValidUpto: validUpto,
      extendedWarrantyUpto: extUpto,
      customerCareNumber: json['customer_care_number'] as String?,
      warrantyStatus: json['warranty_status'] as String? ?? computedStatus,
      warrantyType: wType,
      policyNumber: json['policy_number'] as String?,
      amcProvider: json['amc_provider'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'product_category': productCategory,
      'brand': brand,
      'model_number': modelNumber,
      'serial_number': serialNumber,
      'purchase_amount': purchaseAmount,
      'warranty_period_months': warrantyPeriodMonths,
      'warranty_valid_upto': warrantyValidUpto.toIso8601String().split('T').first,
      'extended_warranty_upto': extendedWarrantyUpto?.toIso8601String().split('T').first,
      'customer_care_number': customerCareNumber,
      'warranty_status': warrantyStatus,
      'warranty_type': warrantyType,
      'policy_number': policyNumber,
      'amc_provider': amcProvider,
    };
  }
}

class ApplianceWarrantyModel {
  final String? id;
  final String? documentId;
  final List<ApplianceItemModel> items;
  final String billingName;
  final String storeVendorName;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final double purchaseAmount;
  final String warrantyType; // 'standard', 'extended', 'amc', 'component', 'lifetime', 'no_warranty'
  final String? policyNumber;
  final String? amcProvider;
  final double? renewalAmount;
  final String? renewalNotes;
  final String? previousDocumentId;
  final int renewalCount;

  // Fallback storage for legacy single-item fields
  final String? _legacyProductName;
  final String? _legacyProductCategory;
  final String? _legacyBrand;
  final String? _legacyModelNumber;
  final String? _legacySerialNumber;
  final int? _legacyWarrantyPeriodMonths;
  final DateTime? _legacyWarrantyValidUpto;
  final DateTime? _legacyExtendedWarrantyUpto;
  final String? _legacyCustomerCareNumber;
  final String? _legacyWarrantyStatus;

  ApplianceWarrantyModel({
    this.id,
    this.documentId,
    List<ApplianceItemModel>? items,
    required this.billingName,
    required this.storeVendorName,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.purchaseAmount,
    this.warrantyType = 'standard',
    this.policyNumber,
    this.amcProvider,
    this.renewalAmount,
    this.renewalNotes,
    this.previousDocumentId,
    this.renewalCount = 0,
    // Optional legacy arguments for backwards compatibility
    String? productName,
    String? productCategory,
    String? brand,
    String? modelNumber,
    String? serialNumber,
    int? warrantyPeriodMonths,
    DateTime? warrantyValidUpto,
    DateTime? extendedWarrantyUpto,
    String? customerCareNumber,
    String? warrantyStatus,
  })  : _legacyProductName = productName,
        _legacyProductCategory = productCategory,
        _legacyBrand = brand,
        _legacyModelNumber = modelNumber,
        _legacySerialNumber = serialNumber,
        _legacyWarrantyPeriodMonths = warrantyPeriodMonths,
        _legacyWarrantyValidUpto = warrantyValidUpto,
        _legacyExtendedWarrantyUpto = extendedWarrantyUpto,
        _legacyCustomerCareNumber = customerCareNumber,
        _legacyWarrantyStatus = warrantyStatus,
        items = (items != null && items.isNotEmpty)
            ? items
            : (productName != null
                ? [
                    ApplianceItemModel(
                      productName: productName,
                      productCategory: productCategory ?? 'Appliances',
                      brand: brand ?? 'Generic',
                      modelNumber: modelNumber,
                      serialNumber: serialNumber,
                      purchaseAmount: purchaseAmount,
                      warrantyPeriodMonths: warrantyPeriodMonths ?? 12,
                      warrantyValidUpto: warrantyValidUpto ?? DateTime.now(),
                      extendedWarrantyUpto: extendedWarrantyUpto,
                      customerCareNumber: customerCareNumber,
                      warrantyStatus: warrantyStatus ?? 'active',
                      warrantyType: warrantyType,
                      policyNumber: policyNumber,
                      amcProvider: amcProvider,
                    ),
                  ]
                : []);

  // Primary item getters for backwards compatibility
  ApplianceItemModel? get primaryItem =>
      items.isNotEmpty ? items.first : null;

  String get productName =>
      primaryItem?.productName ?? _legacyProductName ?? 'Appliance';

  String get productCategory =>
      primaryItem?.productCategory ?? _legacyProductCategory ?? 'Appliances';

  String get brand =>
      primaryItem?.brand ?? _legacyBrand ?? 'Generic';

  String? get modelNumber =>
      primaryItem?.modelNumber ?? _legacyModelNumber;

  String? get serialNumber =>
      primaryItem?.serialNumber ?? _legacySerialNumber;

  int get warrantyPeriodMonths =>
      primaryItem?.warrantyPeriodMonths ?? _legacyWarrantyPeriodMonths ?? 12;

  DateTime get warrantyValidUpto =>
      primaryItem?.warrantyValidUpto ?? _legacyWarrantyValidUpto ?? DateTime.now();

  DateTime? get extendedWarrantyUpto =>
      primaryItem?.extendedWarrantyUpto ?? _legacyExtendedWarrantyUpto;

  DateTime get effectiveValidUpto =>
      extendedWarrantyUpto ?? warrantyValidUpto;

  String? get customerCareNumber =>
      primaryItem?.customerCareNumber ?? _legacyCustomerCareNumber;

  String get warrantyStatus =>
      primaryItem?.warrantyStatus ?? _legacyWarrantyStatus ?? 'active';

  bool get isLifetime => warrantyType == 'lifetime' || (primaryItem?.isLifetime == true);

  bool get hasWarranty =>
      isLifetime || items.any((i) => i.hasWarranty);

  bool get isExpired =>
      !isLifetime && items.isNotEmpty && items.every((i) => i.isExpired);

  bool get isExpiringSoon =>
      !isLifetime && items.any((i) => i.isExpiringSoon);

  int get remainingDays =>
      isLifetime ? 9999 : (primaryItem?.remainingDays ?? 0);

  int get daysUntilExpiry => remainingDays;

  int get itemsCount => items.length;

  bool get hasMultipleItems => items.length > 1;

  List<String> get allBrands =>
      items.map((i) => i.brand).toSet().toList();

  String get brandsSummary {
    final bList = allBrands;
    if (bList.isEmpty) return brand;
    if (bList.length == 1) return bList.first;
    return '${bList.first} + ${bList.length - 1} more';
  }

  String get warrantyTypeDisplay {
    switch (warrantyType) {
      case 'amc':
        return 'Annual Maintenance Contract (AMC)';
      case 'extended':
        return 'Brand Extended Warranty';
      case 'component':
        return 'Component Warranty (Compressor/Motor)';
      case 'lifetime':
        return 'Lifetime Guarantee';
      case 'no_warranty':
        return 'No Warranty (Invoice Only)';
      default:
        return 'Standard Manufacturer Warranty';
    }
  }

  String get warrantyStatusDisplay {
    if (isLifetime) return 'LIFETIME';
    if (!hasWarranty || warrantyStatus == 'no_warranty' || warrantyType == 'no_warranty') {
      return 'NO WARRANTY';
    }
    if (warrantyType == 'amc') {
      if (isExpired) return 'AMC EXPIRED';
      if (isExpiringSoon) return 'AMC EXPIRING';
      return 'AMC ACTIVE';
    }
    if (warrantyType == 'extended' || extendedWarrantyUpto != null) {
      if (isExpired) return 'EXT EXPIRED';
      if (isExpiringSoon) return 'EXT EXPIRING';
      return 'EXT ACTIVE';
    }
    if (warrantyType == 'component') {
      if (isExpired) return 'PART EXPIRED';
      if (isExpiringSoon) return 'PART EXPIRING';
      return 'PART ACTIVE';
    }
    if (isExpired) return 'EXPIRED';
    if (isExpiringSoon) return 'EXPIRING SOON';
    return 'ACTIVE';
  }

  ApplianceWarrantyModel copyWith({
    String? id,
    String? documentId,
    List<ApplianceItemModel>? items,
    String? billingName,
    String? storeVendorName,
    String? invoiceNumber,
    DateTime? purchaseDate,
    double? purchaseAmount,
    String? warrantyType,
    String? policyNumber,
    String? amcProvider,
    double? renewalAmount,
    String? renewalNotes,
    String? previousDocumentId,
    int? renewalCount,
    int? warrantyPeriodMonths,
    DateTime? warrantyValidUpto,
    DateTime? extendedWarrantyUpto,
    String? customerCareNumber,
    String? warrantyStatus,
  }) {
    List<ApplianceItemModel>? resolvedItems = items;
    if (resolvedItems == null && this.items.isNotEmpty) {
      final first = this.items.first;
      final updatedFirst = first.copyWith(
        warrantyValidUpto: warrantyValidUpto ?? first.warrantyValidUpto,
        extendedWarrantyUpto: extendedWarrantyUpto ?? first.extendedWarrantyUpto,
        customerCareNumber: customerCareNumber ?? first.customerCareNumber,
        warrantyStatus: warrantyStatus ?? first.warrantyStatus,
        warrantyType: warrantyType ?? first.warrantyType,
        policyNumber: policyNumber ?? first.policyNumber,
        amcProvider: amcProvider ?? first.amcProvider,
      );
      resolvedItems = [updatedFirst, ...this.items.skip(1)];
    }

    return ApplianceWarrantyModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      items: resolvedItems ?? this.items,
      billingName: billingName ?? this.billingName,
      storeVendorName: storeVendorName ?? this.storeVendorName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseAmount: purchaseAmount ?? this.purchaseAmount,
      warrantyType: warrantyType ?? this.warrantyType,
      policyNumber: policyNumber ?? this.policyNumber,
      amcProvider: amcProvider ?? this.amcProvider,
      renewalAmount: renewalAmount ?? this.renewalAmount,
      renewalNotes: renewalNotes ?? this.renewalNotes,
      previousDocumentId: previousDocumentId ?? this.previousDocumentId,
      renewalCount: renewalCount ?? this.renewalCount,
      warrantyPeriodMonths: warrantyPeriodMonths ?? this.warrantyPeriodMonths,
      warrantyValidUpto: warrantyValidUpto ?? this.warrantyValidUpto,
      extendedWarrantyUpto: extendedWarrantyUpto ?? this.extendedWarrantyUpto,
      customerCareNumber: customerCareNumber ?? this.customerCareNumber,
      warrantyStatus: warrantyStatus ?? this.warrantyStatus,
    );
  }

  factory ApplianceWarrantyModel.fromJson(Map<String, dynamic> json) {
    final validUpto = json['warranty_valid_upto'] != null
        ? DateTime.parse(json['warranty_valid_upto'] as String)
        : DateTime.now();
    final extUpto = json['extended_warranty_upto'] != null
        ? DateTime.parse(json['extended_warranty_upto'] as String)
        : null;
    final periodMonths =
        (json['warranty_period_months'] as num?)?.toInt() ?? 12;
    final wType = json['warranty_type'] as String? ?? 'standard';

    final effectiveDate = extUpto ?? validUpto;
    String computedStatus = 'active';
    if (json['warranty_status'] == 'no_warranty' || periodMonths == 0 || wType == 'no_warranty') {
      computedStatus = 'no_warranty';
    } else if (wType == 'lifetime') {
      computedStatus = 'active';
    } else if (effectiveDate.isBefore(DateTime.now())) {
      computedStatus = 'expired';
    } else if (effectiveDate.difference(DateTime.now()).inDays <= 30) {
      computedStatus = 'expiring_soon';
    }

    // Parse items array if present
    List<ApplianceItemModel> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((itemJson) =>
              ApplianceItemModel.fromJson(Map<String, dynamic>.from(itemJson as Map)))
          .toList();
    }

    final model = ApplianceWarrantyModel(
      id: json['id'] as String?,
      documentId: json['document_id'] as String?,
      items: parsedItems.isNotEmpty ? parsedItems : null,
      productName: json['product_name'] as String? ?? 'Appliance',
      productCategory: json['product_category'] as String? ?? 'Appliances',
      brand: json['brand'] as String? ?? 'Generic',
      modelNumber: json['model_number'] as String?,
      serialNumber: json['serial_number'] as String?,
      billingName: json['billing_name'] as String? ?? '',
      storeVendorName: json['store_vendor_name'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : DateTime.now(),
      purchaseAmount: (json['purchase_amount'] as num?)?.toDouble() ?? 0.0,
      warrantyPeriodMonths: periodMonths,
      warrantyValidUpto: validUpto,
      extendedWarrantyUpto: extUpto,
      customerCareNumber: json['customer_care_number'] as String?,
      warrantyStatus: json['warranty_status'] as String? ?? computedStatus,
      warrantyType: wType,
      policyNumber: json['policy_number'] as String?,
      amcProvider: json['amc_provider'] as String?,
      renewalAmount: (json['renewal_amount'] as num?)?.toDouble(),
      renewalNotes: json['renewal_notes'] as String?,
      previousDocumentId: json['previous_document_id'] as String?,
      renewalCount: (json['renewal_count'] as num?)?.toInt() ?? 0,
    );

    return model;
  }

  static const Set<String> supabaseColumns = {
    'id',
    'document_id',
    'product_name',
    'product_category',
    'brand',
    'model_number',
    'serial_number',
    'billing_name',
    'store_vendor_name',
    'invoice_number',
    'purchase_date',
    'purchase_amount',
    'warranty_period_months',
    'warranty_valid_upto',
    'extended_warranty_upto',
    'customer_care_number',
    'warranty_status',
  };

  Map<String, dynamic> toSupabaseMap() {
    final firstItem = primaryItem;
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      'product_name': firstItem?.productName ?? productName,
      'product_category': firstItem?.productCategory ?? productCategory,
      'brand': hasMultipleItems ? brandsSummary : (firstItem?.brand ?? brand),
      'model_number': firstItem?.modelNumber ?? modelNumber,
      'serial_number': firstItem?.serialNumber ?? serialNumber,
      'billing_name': billingName,
      'store_vendor_name': storeVendorName,
      'invoice_number': invoiceNumber,
      'purchase_date': purchaseDate.toIso8601String().split('T').first,
      'purchase_amount': purchaseAmount,
      'warranty_period_months': firstItem?.warrantyPeriodMonths ?? warrantyPeriodMonths,
      'warranty_valid_upto': (firstItem?.warrantyValidUpto ?? warrantyValidUpto).toIso8601String().split('T').first,
      'extended_warranty_upto': (firstItem?.extendedWarrantyUpto ?? extendedWarrantyUpto)?.toIso8601String().split('T').first,
      'customer_care_number': firstItem?.customerCareNumber ?? customerCareNumber,
      'warranty_status': firstItem?.warrantyStatus ?? warrantyStatus,
    };
    return map;
  }

  Map<String, dynamic> toJson({bool forSupabaseTable = true}) {
    final map = toSupabaseMap();
    if (!forSupabaseTable) {
      map['items'] = items.map((item) => item.toJson()).toList();
      map['warranty_type'] = warrantyType;
      map['policy_number'] = policyNumber;
      map['amc_provider'] = amcProvider;
      map['renewal_amount'] = renewalAmount;
      map['renewal_notes'] = renewalNotes;
      map['previous_document_id'] = previousDocumentId;
      map['renewal_count'] = renewalCount;
    }
    return map;
  }
}
