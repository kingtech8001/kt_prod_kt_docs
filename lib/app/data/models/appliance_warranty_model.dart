class ApplianceWarrantyModel {
  final String? id;
  final String? documentId;
  final String productName;
  final String productCategory;
  final String brand;
  final String? modelNumber;
  final String? serialNumber;
  final String billingName;
  final String storeVendorName;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final double purchaseAmount;
  final int warrantyPeriodMonths;
  final DateTime warrantyValidUpto;
  final DateTime? extendedWarrantyUpto;
  final String? customerCareNumber;
  final String warrantyStatus; // 'active', 'expiring_soon', 'expired'

  ApplianceWarrantyModel({
    this.id,
    this.documentId,
    required this.productName,
    required this.productCategory,
    required this.brand,
    this.modelNumber,
    this.serialNumber,
    required this.billingName,
    required this.storeVendorName,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.purchaseAmount,
    required this.warrantyPeriodMonths,
    required this.warrantyValidUpto,
    this.extendedWarrantyUpto,
    this.customerCareNumber,
    this.warrantyStatus = 'active',
  });

  bool get isExpired => warrantyValidUpto.isBefore(DateTime.now());
  bool get isExpiringSoon {
    final now = DateTime.now();
    final diff = warrantyValidUpto.difference(now).inDays;
    return diff >= 0 && diff <= 30;
  }

  int get remainingDays {
    final now = DateTime.now();
    return warrantyValidUpto.difference(now).inDays;
  }

  int get daysUntilExpiry => remainingDays;

  String get warrantyStatusDisplay {
    if (isExpired) return 'EXPIRED';
    if (isExpiringSoon) return 'EXPIRING SOON';
    return 'ACTIVE';
  }

  factory ApplianceWarrantyModel.fromJson(Map<String, dynamic> json) {
    final validUpto = json['warranty_valid_upto'] != null
        ? DateTime.parse(json['warranty_valid_upto'] as String)
        : DateTime.now();

    String computedStatus = 'active';
    if (validUpto.isBefore(DateTime.now())) {
      computedStatus = 'expired';
    } else if (validUpto.difference(DateTime.now()).inDays <= 30) {
      computedStatus = 'expiring_soon';
    }

    return ApplianceWarrantyModel(
      id: json['id'] as String?,
      documentId: json['document_id'] as String?,
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
      warrantyPeriodMonths: (json['warranty_period_months'] as num?)?.toInt() ?? 12,
      warrantyValidUpto: validUpto,
      extendedWarrantyUpto: json['extended_warranty_upto'] != null
          ? DateTime.parse(json['extended_warranty_upto'] as String)
          : null,
      customerCareNumber: json['customer_care_number'] as String?,
      warrantyStatus: json['warranty_status'] as String? ?? computedStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      'product_name': productName,
      'product_category': productCategory,
      'brand': brand,
      'model_number': modelNumber,
      'serial_number': serialNumber,
      'billing_name': billingName,
      'store_vendor_name': storeVendorName,
      'invoice_number': invoiceNumber,
      'purchase_date': purchaseDate.toIso8601String().split('T').first,
      'purchase_amount': purchaseAmount,
      'warranty_period_months': warrantyPeriodMonths,
      'warranty_valid_upto': warrantyValidUpto.toIso8601String().split('T').first,
      'extended_warranty_upto': extendedWarrantyUpto?.toIso8601String().split('T').first,
      'customer_care_number': customerCareNumber,
      'warranty_status': warrantyStatus,
    };
  }
}
