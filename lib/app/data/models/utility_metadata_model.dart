class UtilityMetadataModel {
  final String? id;
  final String? documentId;
  final String utilityType;
  final String providerName;
  final String consumerNumber;
  final String? meterNumber;
  final DateTime billDate;
  final DateTime? dueDate;
  final DateTime? billingPeriodStart;
  final DateTime? billingPeriodEnd;
  final double billAmount;
  final String paymentStatus; // 'paid', 'pending', 'overdue', 'auto_debit'
  final DateTime? paymentDate;
  final String? paymentReferenceId;
  final double? unitsConsumed;

  UtilityMetadataModel({
    this.id,
    this.documentId,
    required this.utilityType,
    required this.providerName,
    required this.consumerNumber,
    this.meterNumber,
    required this.billDate,
    this.dueDate,
    this.billingPeriodStart,
    this.billingPeriodEnd,
    required this.billAmount,
    this.paymentStatus = 'pending',
    this.paymentDate,
    this.paymentReferenceId,
    this.unitsConsumed,
  });

  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'auto_debit';
  bool get isOverdue =>
      paymentStatus != 'paid' &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  factory UtilityMetadataModel.fromJson(Map<String, dynamic> json) {
    return UtilityMetadataModel(
      id: json['id'] as String?,
      documentId: json['document_id'] as String?,
      utilityType: json['utility_type'] as String? ?? 'Electricity / Light',
      providerName: json['provider_name'] as String? ?? '',
      consumerNumber: json['consumer_number'] as String? ?? '',
      meterNumber: json['meter_number'] as String?,
      billDate: json['bill_date'] != null
          ? DateTime.parse(json['bill_date'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      billingPeriodStart: json['billing_period_start'] != null
          ? DateTime.parse(json['billing_period_start'] as String)
          : null,
      billingPeriodEnd: json['billing_period_end'] != null
          ? DateTime.parse(json['billing_period_end'] as String)
          : null,
      billAmount: (json['bill_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String)
          : null,
      paymentReferenceId: json['payment_reference_id'] as String?,
      unitsConsumed: (json['units_consumed'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      'utility_type': utilityType,
      'provider_name': providerName,
      'consumer_number': consumerNumber,
      'meter_number': meterNumber,
      'bill_date': billDate.toIso8601String().split('T').first,
      if (dueDate != null)
        'due_date': dueDate!.toIso8601String().split('T').first,
      if (billingPeriodStart != null)
        'billing_period_start':
            billingPeriodStart!.toIso8601String().split('T').first,
      if (billingPeriodEnd != null)
        'billing_period_end':
            billingPeriodEnd!.toIso8601String().split('T').first,
      'bill_amount': billAmount,
      'payment_status': paymentStatus,
      if (paymentDate != null)
        'payment_date': paymentDate!.toIso8601String().split('T').first,
      'payment_reference_id': paymentReferenceId,
      'units_consumed': unitsConsumed,
    };
  }
}
