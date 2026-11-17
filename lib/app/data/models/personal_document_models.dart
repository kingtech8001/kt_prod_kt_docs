import 'package:flutter/material.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class MasterPersonModel {
  final String id;
  final String fullName;
  final String relationship; // 'Self', 'Spouse', 'Father', 'Mother', 'Son', 'Daughter', 'Brother', 'Sister', 'Staff', 'Other'
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? email;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  MasterPersonModel({
    required this.id,
    required this.fullName,
    this.relationship = 'Self',
    this.dateOfBirth,
    this.phoneNumber,
    this.email,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MasterPersonModel.fromJson(Map<String, dynamic> json) {
    return MasterPersonModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      relationship: json['relationship'] as String? ?? 'Self',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
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
      'full_name': fullName,
      'relationship': relationship,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'phone_number': phoneNumber,
      'email': email,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  MasterPersonModel copyWith({
    String? id,
    String? fullName,
    String? relationship,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? email,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MasterPersonModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MasterPersonalDocTypeModel {
  final String id;
  final String name;
  final String code;
  final String iconName;
  final bool hasExpiry;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;

  MasterPersonalDocTypeModel({
    required this.id,
    required this.name,
    required this.code,
    this.iconName = 'badge',
    this.hasExpiry = false,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
  });

  factory MasterPersonalDocTypeModel.fromJson(Map<String, dynamic> json) {
    return MasterPersonalDocTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      iconName: json['icon_name'] as String? ?? 'badge',
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

class PersonalDocumentMetadataModel {
  final String? id;
  final String? documentId;
  final String? personId;
  final String personName;
  final String? relationship;
  final String? docTypeId;
  final String docTypeName;
  final String? idNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? issuingAuthority;
  final String? insuranceCompany;
  final String? policyType; // 'Individual', 'Family Floater', 'Group Mediclaim', 'Senior Citizen', 'Top-Up'
  final double? sumInsured;
  final double? premiumAmount;
  final String? tpaName;
  final String? previousDocumentId; // Reference to superseded previous policy
  final int renewalCount;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PersonalDocumentMetadataModel({
    this.id,
    this.documentId,
    this.personId,
    required this.personName,
    this.relationship,
    this.docTypeId,
    required this.docTypeName,
    this.idNumber,
    this.issueDate,
    this.expiryDate,
    this.issuingAuthority,
    this.insuranceCompany,
    this.policyType,
    this.sumInsured,
    this.premiumAmount,
    this.tpaName,
    this.previousDocumentId,
    this.renewalCount = 0,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasExpiry => expiryDate != null;

  String? get policyNumber => idNumber;

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
    final difference = expiryDate!.difference(today).inDays;
    return difference >= 0 && difference <= 60;
  }

  bool get isInsurance =>
      docTypeName.toLowerCase().contains('insurance') ||
      docTypeName.toLowerCase().contains('mediclaim') ||
      (policyType != null && policyType!.isNotEmpty) ||
      (sumInsured != null && sumInsured! > 0) ||
      docTypeId == 'fb2bf191-b2c0-40dc-a818-6e7758a07b56' ||
      docTypeId == '7b1c3e4a-9b12-4c56-8a78-9e1f3b5a7c90';

  bool get isRenewable =>
      isInsurance ||
      docTypeName.toLowerCase().contains('passport') ||
      docTypeName.toLowerCase().contains('license') ||
      docTypeName.toLowerCase().contains('licence');

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expiryDate!.difference(today).inDays;
  }

  String get expiryStatusLabel {
    if (expiryDate == null) return 'Lifetime (No Expiry)';
    if (isExpired) {
      final days = -daysUntilExpiry!;
      return days == 0 ? 'Expired Today' : 'Expired $days d ago';
    }
    final days = daysUntilExpiry!;
    if (days == 0) return 'Expires Today';
    if (days <= 60) return 'Expires in $days days';
    return 'Active';
  }

  Color get statusBadgeColor {
    if (expiryDate == null) return AppColors.success;
    if (isExpired) return AppColors.error;
    if (isExpiringSoon) return AppColors.warning;
    return AppColors.success;
  }

  factory PersonalDocumentMetadataModel.fromJson(Map<String, dynamic> json) {
    return PersonalDocumentMetadataModel(
      id: json['id'] as String?,
      documentId: json['document_id'] as String?,
      personId: json['person_id'] as String?,
      personName: json['person_name'] as String? ?? 'Unknown Person',
      relationship: json['relationship'] as String?,
      docTypeId: json['doc_type_id'] as String?,
      docTypeName: json['doc_type_name'] as String? ?? 'Identity Document',
      idNumber: json['id_number'] as String?,
      issueDate: json['issue_date'] != null
          ? DateTime.tryParse(json['issue_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      issuingAuthority: json['issuing_authority'] as String?,
      insuranceCompany: json['insurance_company'] as String? ??
          json['issuing_authority'] as String?,
      policyType: json['policy_type'] as String?,
      sumInsured: (json['sum_insured'] as num?)?.toDouble(),
      premiumAmount: (json['premium_amount'] as num?)?.toDouble(),
      tpaName: json['tpa_name'] as String?,
      previousDocumentId: json['previous_document_id'] as String?,
      renewalCount: (json['renewal_count'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool forSupabaseTable = true}) {
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (personId != null) 'person_id': personId,
      'person_name': personName,
      if (docTypeId != null) 'doc_type_id': docTypeId,
      'doc_type_name': docTypeName,
      if (idNumber != null) 'id_number': idNumber,
      if (issueDate != null)
        'issue_date': issueDate!.toIso8601String().split('T').first,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      if (issuingAuthority != null) 'issuing_authority': issuingAuthority,
      if (notes != null) 'notes': notes,
    };
    if (!forSupabaseTable) {
      if (insuranceCompany != null) map['insurance_company'] = insuranceCompany;
      if (policyType != null) map['policy_type'] = policyType;
      if (sumInsured != null) map['sum_insured'] = sumInsured;
      if (premiumAmount != null) map['premium_amount'] = premiumAmount;
      if (tpaName != null) map['tpa_name'] = tpaName;
      if (previousDocumentId != null) {
        map['previous_document_id'] = previousDocumentId;
      }
      map['renewal_count'] = renewalCount;
    }
    return map;
  }

  PersonalDocumentMetadataModel copyWith({
    String? id,
    String? documentId,
    String? personId,
    String? personName,
    String? relationship,
    String? docTypeId,
    String docTypeName = '',
    String? idNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    String? issuingAuthority,
    String? insuranceCompany,
    String? policyType,
    double? sumInsured,
    double? premiumAmount,
    String? tpaName,
    String? previousDocumentId,
    int? renewalCount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalDocumentMetadataModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      relationship: relationship ?? this.relationship,
      docTypeId: docTypeId ?? this.docTypeId,
      docTypeName: docTypeName.isNotEmpty ? docTypeName : this.docTypeName,
      idNumber: idNumber ?? this.idNumber,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      policyType: policyType ?? this.policyType,
      sumInsured: sumInsured ?? this.sumInsured,
      premiumAmount: premiumAmount ?? this.premiumAmount,
      tpaName: tpaName ?? this.tpaName,
      previousDocumentId: previousDocumentId ?? this.previousDocumentId,
      renewalCount: renewalCount ?? this.renewalCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
