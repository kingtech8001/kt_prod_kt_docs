import 'package:kt_prod_kt_docs/core/utils/app_formatters.dart';
import 'address_model.dart';
import 'appliance_warranty_model.dart';
import 'personal_document_models.dart';
import 'utility_metadata_model.dart';
import 'vehicle_document_models.dart';

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
  final VehicleDocumentMetadataModel? vehicleMetadata;
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
    this.vehicleMetadata,
    this.isFavorite = false,
  });

  bool get isPdf =>
      fileType.toLowerCase() == 'pdf' || mimeType.contains('pdf');
  bool get isImage =>
      ['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg'].contains(fileType.toLowerCase()) ||
      mimeType.startsWith('image/');
  String get fileSizeFormatted => AppFormatters.formatFileSize(fileSize);

  /// Identifies whether the document's link is genuinely a Google Drive link.
  /// Displays the Google Drive icon ONLY if the link is a Google Drive link; otherwise false.
  bool get isGoogleAttachment {
    final provider = (extraAttributes['storage_provider'] ?? '')
        .toString()
        .toLowerCase()
        .trim();

    // If storage is Supabase or VPS, it is stored in storage, NOT Google Drive.
    if (provider == 'supabase' || provider == 'vps') {
      return false;
    }
    if (extraAttributes['is_google_attachment'] == false ||
        extraAttributes['is_google_attachment'] == 'false') {
      return false;
    }

    final path = filePath.toLowerCase().trim();

    // Exclude any storage path
    if (path.startsWith('vps_storage/') ||
        path.contains('/vps_storage/') ||
        path.startsWith('vps/') ||
        path.contains('supabase.co/storage')) {
      return false;
    }

    // ONLY display if the link is genuinely a Google Drive link
    if (path.startsWith('gdrive://') ||
        path.contains('drive.google.com') ||
        path.contains('docs.google.com')) {
      return true;
    }

    // Fallback: check if an explicit google drive link is stored in extra_attributes,
    // but only if filePath is NOT an uploaded storage file path (which contains directory slashes)
    if (!path.contains('/')) {
      final gUrl = (extraAttributes['google_drive_url'] ??
              extraAttributes['web_view_link'] ??
              extraAttributes['web_content_link'])
          ?.toString()
          .toLowerCase()
          .trim();
      if (gUrl != null &&
          (gUrl.contains('drive.google.com') || gUrl.contains('docs.google.com'))) {
        return true;
      }
    }

    return false;
  }

  /// Returns the resolved Google Drive or Google Docs URL if present.
  String? get googleAttachmentUrl {
    if (!isGoogleAttachment) return null;

    final path = filePath.trim();
    if (path.startsWith('gdrive://')) {
      final fileId = path.replaceFirst('gdrive://', '').trim();
      if (fileId.isNotEmpty) {
        return 'https://drive.google.com/file/d/$fileId/view?usp=sharing';
      }
    }

    if (path.contains('drive.google.com') || path.contains('docs.google.com')) {
      return path;
    }

    final gUrl = (extraAttributes['google_drive_url'] ??
            extraAttributes['web_view_link'] ??
            extraAttributes['web_content_link'])
        ?.toString()
        .trim();
    if (gUrl != null &&
        (gUrl.contains('drive.google.com') || gUrl.contains('docs.google.com'))) {
      return gUrl;
    }

    return null;
  }

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
    final vehicle = _extractMap(json['vehicle_document_metadata']);
    final favs = _extractList(json['document_favorites']);
    final extra = (json['extra_attributes'] is Map)
        ? Map<String, dynamic>.from(json['extra_attributes'] as Map)
        : <String, dynamic>{};

    Map<String, dynamic>? warrantyMap = warranty;
    if (warrantyMap != null) {
      if (warrantyMap['items'] == null && extra['appliance_items'] != null) {
        warrantyMap = Map<String, dynamic>.from(warrantyMap);
        warrantyMap['items'] = extra['appliance_items'];
      }
    } else if (extra['appliance_items'] != null) {
      warrantyMap = {
        'items': extra['appliance_items'],
        'billing_name': '',
        'store_vendor_name': '',
        'invoice_number': json['document_number'] ?? '',
        'purchase_date': json['created_at'],
        'purchase_amount': 0.0,
      };
    }

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
      extraAttributes: extra,
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
          warrantyMap != null ? ApplianceWarrantyModel.fromJson(warrantyMap) : null,
      personalMetadata: personal != null ? PersonalDocumentMetadataModel.fromJson(personal) : null,
      vehicleMetadata: vehicle != null ? VehicleDocumentMetadataModel.fromJson(vehicle) : null,
      isFavorite: favs != null && favs.isNotEmpty,
    );
  }

  DocumentModel copyWith({
    String? title,
    String? description,
    String? documentNumber,
    String? subCategory,
    String? status,
    bool? isFavorite,
    String? fileName,
    String? filePath,
    String? fileType,
    String? mimeType,
    int? fileSize,
    Map<String, dynamic>? extraAttributes,
    AddressModel? address,
    UtilityMetadataModel? utilityMetadata,
    ApplianceWarrantyModel? applianceWarranty,
    PersonalDocumentMetadataModel? personalMetadata,
    VehicleDocumentMetadataModel? vehicleMetadata,
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
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      thumbnailPath: thumbnailPath,
      documentNumber: documentNumber ?? this.documentNumber,
      status: status ?? this.status,
      uploadedBy: uploadedBy,
      uploaderName: uploaderName,
      extraAttributes: extraAttributes ?? this.extraAttributes,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      address: address ?? this.address,
      utilityMetadata: utilityMetadata ?? this.utilityMetadata,
      applianceWarranty: applianceWarranty ?? this.applianceWarranty,
      personalMetadata: personalMetadata ?? this.personalMetadata,
      vehicleMetadata: vehicleMetadata ?? this.vehicleMetadata,
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
