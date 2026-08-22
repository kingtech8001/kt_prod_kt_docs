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
  final String? docTypeId;
  final String docTypeName;
  final String? idNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? issuingAuthority;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PersonalDocumentMetadataModel({
    this.id,
    this.documentId,
    this.personId,
    required this.personName,
    this.docTypeId,
    required this.docTypeName,
    this.idNumber,
    this.issueDate,
    this.expiryDate,
    this.issuingAuthority,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference >= 0 && difference <= 60;
  }

  factory PersonalDocumentMetadataModel.fromJson(Map<String, dynamic> json) {
    return PersonalDocumentMetadataModel(
      id: json['id'] as String?,
      documentId: json['document_id'] as String?,
      personId: json['person_id'] as String?,
      personName: json['person_name'] as String? ?? 'Unknown Person',
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
      notes: json['notes'] as String?,
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
      if (personId != null) 'person_id': personId,
      'person_name': personName,
      if (docTypeId != null) 'doc_type_id': docTypeId,
      'doc_type_name': docTypeName,
      if (idNumber != null) 'id_number': idNumber,
      if (issueDate != null) 'issue_date': issueDate!.toIso8601String().split('T').first,
      if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String().split('T').first,
      if (issuingAuthority != null) 'issuing_authority': issuingAuthority,
      if (notes != null) 'notes': notes,
    };
  }
}
