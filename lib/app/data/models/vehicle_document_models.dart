import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class MasterVehicleModel {
  final String id;
  final String vehicleNumber; // e.g. GJ-01-AB-1234
  final String? nickname; // e.g. Creta SX, Activa 6G
  final String vehicleType; // 'Two Wheeler', 'Four Wheeler', 'Commercial', 'Electric Vehicle', 'Other'
  final String? brandMake; // Hyundai, Honda, Tata, Maruti Suzuki, etc.
  final String? modelName; // Creta, Activa, etc.
  final String? fuelType; // Petrol, Diesel, CNG, Electric, Hybrid
  final String? chassisNumber;
  final String? engineNumber;
  final DateTime? registrationDate;
  final String? ownerName;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  MasterVehicleModel({
    required this.id,
    required this.vehicleNumber,
    this.nickname,
    this.vehicleType = 'Four Wheeler',
    this.brandMake,
    this.modelName,
    this.fuelType,
    this.chassisNumber,
    this.engineNumber,
    this.registrationDate,
    this.ownerName,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName {
    if (nickname != null && nickname!.trim().isNotEmpty) {
      return '$nickname ($vehicleNumber)';
    }
    return vehicleNumber;
  }

  String get shortLabel {
    if (nickname != null && nickname!.trim().isNotEmpty) {
      return '$vehicleNumber • $nickname';
    }
    return vehicleNumber;
  }

  factory MasterVehicleModel.fromJson(Map<String, dynamic> json) {
    return MasterVehicleModel(
      id: json['id'] as String,
      vehicleNumber: (json['vehicle_number'] as String).toUpperCase(),
      nickname: json['nickname'] as String?,
      vehicleType: json['vehicle_type'] as String? ?? 'Four Wheeler',
      brandMake: json['brand_make'] as String?,
      modelName: json['model_name'] as String?,
      fuelType: json['fuel_type'] as String?,
      chassisNumber: json['chassis_number'] as String?,
      engineNumber: json['engine_number'] as String?,
      registrationDate: json['registration_date'] != null
          ? DateTime.tryParse(json['registration_date'] as String)
          : null,
      ownerName: json['owner_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_number': vehicleNumber.toUpperCase(),
      'nickname': nickname,
      'vehicle_type': vehicleType,
      'brand_make': brandMake,
      'model_name': modelName,
      'fuel_type': fuelType,
      'chassis_number': chassisNumber,
      'engine_number': engineNumber,
      'registration_date':
          registrationDate?.toIso8601String().split('T').first,
      'owner_name': ownerName,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  MasterVehicleModel copyWith({
    String? id,
    String? vehicleNumber,
    String? nickname,
    String? vehicleType,
    String? brandMake,
    String? modelName,
    String? fuelType,
    String? chassisNumber,
    String? engineNumber,
    DateTime? registrationDate,
    String? ownerName,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MasterVehicleModel(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      nickname: nickname ?? this.nickname,
      vehicleType: vehicleType ?? this.vehicleType,
      brandMake: brandMake ?? this.brandMake,
      modelName: modelName ?? this.modelName,
      fuelType: fuelType ?? this.fuelType,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      engineNumber: engineNumber ?? this.engineNumber,
      registrationDate: registrationDate ?? this.registrationDate,
      ownerName: ownerName ?? this.ownerName,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MasterVehicleDocTypeModel {
  final String id;
  final String name;
  final String code;
  final String iconName;
  final bool hasExpiry;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;

  MasterVehicleDocTypeModel({
    required this.id,
    required this.name,
    required this.code,
    this.iconName = 'directions_car',
    this.hasExpiry = false,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
  });

  factory MasterVehicleDocTypeModel.fromJson(Map<String, dynamic> json) {
    return MasterVehicleDocTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      iconName: json['icon_name'] as String? ?? 'directions_car',
      hasExpiry: json['has_expiry'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'icon_name': iconName,
      'has_expiry': hasExpiry,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

class VehicleDocumentMetadataModel {
  final String? id;
  final String? documentId;
  final String? vehicleId;
  final String vehicleNumber;
  final String vehicleName;
  final String? docTypeId;
  final String docTypeName;
  final String? policyOrCertNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? insuranceCompany;
  final double? premiumAmount;
  final String? serviceCenter;
  final int? odometerReading;
  final String? notes;
  final String? passType;
  final String? tollPlazaName;
  final String? fastagId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleDocumentMetadataModel({
    this.id,
    this.documentId,
    this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleName,
    this.docTypeId,
    required this.docTypeName,
    this.policyOrCertNumber,
    this.issueDate,
    this.expiryDate,
    this.insuranceCompany,
    this.premiumAmount,
    this.serviceCenter,
    this.odometerReading,
    this.notes,
    this.passType,
    this.tollPlazaName,
    this.fastagId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPassOrFastag =>
      docTypeName.toLowerCase().contains('fastag') ||
      docTypeName.toLowerCase().contains('toll') ||
      docTypeName.toLowerCase().contains('pass') ||
      (passType != null && passType!.isNotEmpty);

  bool get isExpired {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expiryDate!.isBefore(today);
  }

  bool get isExpiringSoon {
    if (expiryDate == null || isExpired) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = expiryDate!.difference(today).inDays;
    return days >= 0 && days <= 30;
  }

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expiryDate!.difference(today).inDays;
  }

  String get expiryStatusLabel {
    if (expiryDate == null) return 'No Expiry';
    if (isExpired) {
      final days = -daysUntilExpiry!;
      return days == 0 ? 'Expired Today' : 'Expired $days d ago';
    }
    final days = daysUntilExpiry!;
    if (days == 0) return 'Expires Today';
    if (days <= 30) return 'Expires in $days days';
    return 'Active';
  }

  Color get statusBadgeColor {
    if (expiryDate == null) return AppColors.textSecondary;
    if (isExpired) return AppColors.error;
    if (isExpiringSoon) return AppColors.warning;
    return AppColors.success;
  }

  factory VehicleDocumentMetadataModel.fromJson(Map<String, dynamic> json) {
    return VehicleDocumentMetadataModel(
      id: json['id'] as String?,
      documentId: json['document_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      vehicleNumber: (json['vehicle_number'] as String? ?? '').toUpperCase(),
      vehicleName: json['vehicle_name'] as String? ?? '',
      docTypeId: json['doc_type_id'] as String?,
      docTypeName: json['doc_type_name'] as String? ?? 'Vehicle Document',
      policyOrCertNumber: json['policy_or_cert_number'] as String?,
      issueDate: json['issue_date'] != null
          ? DateTime.tryParse(json['issue_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      insuranceCompany: json['insurance_company'] as String?,
      premiumAmount: (json['premium_amount'] as num?)?.toDouble(),
      serviceCenter: json['service_center'] as String?,
      odometerReading: (json['odometer_reading'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      passType: json['pass_type'] as String?,
      tollPlazaName: json['toll_plaza_name'] as String?,
      fastagId: json['fastag_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber.toUpperCase(),
      'vehicle_name': vehicleName,
      if (docTypeId != null) 'doc_type_id': docTypeId,
      'doc_type_name': docTypeName,
      if (policyOrCertNumber != null)
        'policy_or_cert_number': policyOrCertNumber,
      if (issueDate != null)
        'issue_date': issueDate!.toIso8601String().split('T').first,
      if (expiryDate != null)
        'expiry_date': expiryDate!.toIso8601String().split('T').first,
      if (insuranceCompany != null) 'insurance_company': insuranceCompany,
      if (premiumAmount != null) 'premium_amount': premiumAmount,
      if (serviceCenter != null) 'service_center': serviceCenter,
      if (odometerReading != null) 'odometer_reading': odometerReading,
      if (notes != null) 'notes': notes,
      if (passType != null) 'pass_type': passType,
      if (tollPlazaName != null) 'toll_plaza_name': tollPlazaName,
      if (fastagId != null) 'fastag_id': fastagId,
    };
  }

  VehicleDocumentMetadataModel copyWith({
    String? id,
    String? documentId,
    String? vehicleId,
    String? vehicleNumber,
    String? vehicleName,
    String? docTypeId,
    String? docTypeName,
    String? policyOrCertNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? insuranceCompany,
    double? premiumAmount,
    String? serviceCenter,
    int? odometerReading,
    String? notes,
    String? passType,
    String? tollPlazaName,
    String? fastagId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleDocumentMetadataModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleName: vehicleName ?? this.vehicleName,
      docTypeId: docTypeId ?? this.docTypeId,
      docTypeName: docTypeName ?? this.docTypeName,
      policyOrCertNumber: policyOrCertNumber ?? this.policyOrCertNumber,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      premiumAmount: premiumAmount ?? this.premiumAmount,
      serviceCenter: serviceCenter ?? this.serviceCenter,
      odometerReading: odometerReading ?? this.odometerReading,
      notes: notes ?? this.notes,
      passType: passType ?? this.passType,
      tollPlazaName: tollPlazaName ?? this.tollPlazaName,
      fastagId: fastagId ?? this.fastagId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VehicleServiceModel {
  final String id;
  final String vehicleId;
  final DateTime serviceDate;
  final int odometerKm;
  final List<String> serviceTypes;
  final String? serviceCenterName;
  final String? billNumber;
  final double costAmount;
  final DateTime? nextServiceDate;
  final int? nextServiceKm;
  final String? notes;
  final String? documentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleServiceModel({
    required this.id,
    required this.vehicleId,
    required this.serviceDate,
    required this.odometerKm,
    this.serviceTypes = const [],
    this.serviceCenterName,
    this.billNumber,
    this.costAmount = 0.0,
    this.nextServiceDate,
    this.nextServiceKm,
    this.notes,
    this.documentId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isNextServiceOverdue {
    if (nextServiceDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextServiceDate!.isBefore(today);
  }

  bool get isNextServiceDueSoon {
    if (nextServiceDate == null || isNextServiceOverdue) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = nextServiceDate!.difference(today).inDays;
    return days >= 0 && days <= 30;
  }

  int? get daysUntilNextService {
    if (nextServiceDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextServiceDate!.difference(today).inDays;
  }

  String get serviceTypesSummary {
    if (serviceTypes.isEmpty) return 'General Service';
    return serviceTypes.join(', ');
  }

  factory VehicleServiceModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTypes = [];
    if (json['service_types'] is List) {
      parsedTypes = (json['service_types'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return VehicleServiceModel(
      id: json['id'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? '',
      serviceDate: json['service_date'] != null
          ? DateTime.parse(json['service_date'] as String)
          : DateTime.now(),
      odometerKm: (json['odometer_km'] as num?)?.toInt() ?? 0,
      serviceTypes: parsedTypes,
      serviceCenterName: json['service_center_name'] as String?,
      billNumber: json['bill_number'] as String?,
      costAmount: (json['cost_amount'] as num?)?.toDouble() ?? 0.0,
      nextServiceDate: json['next_service_date'] != null
          ? DateTime.parse(json['next_service_date'] as String)
          : null,
      nextServiceKm: (json['next_service_km'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      documentId: json['document_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'vehicle_id': vehicleId,
      'service_date': serviceDate.toIso8601String().split('T').first,
      'odometer_km': odometerKm,
      'service_types': serviceTypes,
      if (serviceCenterName != null) 'service_center_name': serviceCenterName,
      if (billNumber != null) 'bill_number': billNumber,
      'cost_amount': costAmount,
      if (nextServiceDate != null)
        'next_service_date':
            nextServiceDate!.toIso8601String().split('T').first,
      if (nextServiceKm != null) 'next_service_km': nextServiceKm,
      if (notes != null) 'notes': notes,
      if (documentId != null) 'document_id': documentId,
    };
  }

  VehicleServiceModel copyWith({
    String? id,
    String? vehicleId,
    DateTime? serviceDate,
    int? odometerKm,
    List<String>? serviceTypes,
    String? serviceCenterName,
    String? billNumber,
    double? costAmount,
    DateTime? nextServiceDate,
    int? nextServiceKm,
    String? notes,
    String? documentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleServiceModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceDate: serviceDate ?? this.serviceDate,
      odometerKm: odometerKm ?? this.odometerKm,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      serviceCenterName: serviceCenterName ?? this.serviceCenterName,
      billNumber: billNumber ?? this.billNumber,
      costAmount: costAmount ?? this.costAmount,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      nextServiceKm: nextServiceKm ?? this.nextServiceKm,
      notes: notes ?? this.notes,
      documentId: documentId ?? this.documentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

