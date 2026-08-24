import 'address_model.dart';
import 'appliance_warranty_model.dart';
import 'personal_document_models.dart';
import 'utility_metadata_model.dart';

class DocumentModel {
  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String? categoryCode;
  final String subCategory;
  final String? folderId;
  final String? folderName;

  // File Details
  final String fileName;
  final String filePath;
  final String fileType;
  final String mimeType;
  final int fileSize;
  final String? thumbnailPath;

  // Identifiers & Status
  final String? documentNumber;
  final String status; // 'active', 'archived', 'pending_review', 'expired'
  final String? uploadedBy;
  final String? uploaderName;
  final Map<String, dynamic> extraAttributes;

  // Soft Delete
  final DateTime? deletedAt;
  final String? deletedBy;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined Specialized Metadata
  final AddressModel? address;
  final UtilityMetadataModel? utilityMetadata;
  final ApplianceWarrantyModel? applianceWarranty;
  final PersonalDocumentMetadataModel? personalMetadata;
  final bool isFavorite;

  DocumentModel({
    required this.id,
    required this.title,
    this.description,
    this.categoryId,
    this.categoryName,
    this.categoryCode,
    required this.subCategory,
    this.folderId,
    this.folderName,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.mimeType,
    required this.fileSize,
    this.thumbnailPath,
    this.documentNumber,
    this.status = 'active',
    this.uploadedBy,
    this.uploaderName,
    this.extraAttributes = const {},
    this.deletedAt,
    this.deletedBy,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.utilityMetadata,
    this.applianceWarranty,
    this.personalMetadata,
    this.isFavorite = false,
  });

  bool get isPdf =>
      fileType.toLowerCase() == 'pdf' || mimeType.contains('pdf');
  bool get isImage =>
      ['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg'].contains(fileType.toLowerCase()) ||
      mimeType.startsWith('image/');

  String get city => address?.city ?? 'All Cities';
  String get brand => applianceWarranty?.brand ?? 'Unknown';
  String get personName => personalMetadata?.personName ?? 'Unknown Person';
  String get docTypeName => personalMetadata?.docTypeName ?? subCategory;

  static Map<String, dynamic>? _extractMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  static List<dynamic>? _extractList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value;
    if (value is Map) return [value];
    return null;
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final cat = _extractMap(json['document_categories']);
    final fld = _extractMap(json['folders']);
    final prof = _extractMap(json['profiles']);
    final addr = _extractMap(json['document_addresses']);
    final util = _extractMap(json['utility_metadata']);
    final warranty = _extractMap(json['appliance_warranty_metadata']);
    final personal = _extractMap(json['personal_document_metadata']);
    final favs = _extractList(json['document_favorites']);

    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Document',
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: cat != null ? cat['name'] as String? : null,
      categoryCode: cat != null ? cat['code'] as String? : null,
      subCategory: json['sub_category'] as String? ?? 'General',
      folderId: json['folder_id'] as String?,
      folderName: fld != null ? fld['name'] as String? : null,
      fileName: json['file_name'] as String? ?? 'file',
      filePath: json['file_path'] as String? ?? '',
      fileType: json['file_type'] as String? ?? 'unknown',
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      thumbnailPath: json['thumbnail_path'] as String?,
      documentNumber: json['document_number'] as String?,
      status: json['status'] as String? ?? 'active',
      uploadedBy: json['uploaded_by'] as String?,
      uploaderName: prof != null ? prof['full_name'] as String? : null,
      extraAttributes: (json['extra_attributes'] is Map)
          ? Map<String, dynamic>.from(json['extra_attributes'] as Map)
          : {},
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
      deletedBy: json['deleted_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      address: addr != null ? AddressModel.fromJson(addr) : null,
      utilityMetadata: util != null ? UtilityMetadataModel.fromJson(util) : null,
      applianceWarranty:
          warranty != null ? ApplianceWarrantyModel.fromJson(warranty) : null,
      personalMetadata: personal != null ? PersonalDocumentMetadataModel.fromJson(personal) : null,
      isFavorite: favs != null && favs.isNotEmpty,
    );
  }

  DocumentModel copyWith({
    String? title,
    String? description,
    String? subCategory,
    String? status,
    bool? isFavorite,
    AddressModel? address,
    UtilityMetadataModel? utilityMetadata,
    ApplianceWarrantyModel? applianceWarranty,
    PersonalDocumentMetadataModel? personalMetadata,
  }) {
    return DocumentModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryCode: categoryCode,
      subCategory: subCategory ?? this.subCategory,
      folderId: folderId,
      folderName: folderName,
      fileName: fileName,
      filePath: filePath,
      fileType: fileType,
      mimeType: mimeType,
      fileSize: fileSize,
      thumbnailPath: thumbnailPath,
      documentNumber: documentNumber,
      status: status ?? this.status,
      uploadedBy: uploadedBy,
      uploaderName: uploaderName,
      extraAttributes: extraAttributes,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      address: address ?? this.address,
      utilityMetadata: utilityMetadata ?? this.utilityMetadata,
      applianceWarranty: applianceWarranty ?? this.applianceWarranty,
      personalMetadata: personalMetadata ?? this.personalMetadata,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'sub_category': subCategory,
      'folder_id': folderId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'mime_type': mimeType,
      'file_size': fileSize,
      'thumbnail_path': thumbnailPath,
      'document_number': documentNumber,
      'status': status,
      'uploaded_by': uploadedBy,
      'extra_attributes': extraAttributes,
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
    };
  }
}
