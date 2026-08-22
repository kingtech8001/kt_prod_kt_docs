class DocumentVersionModel {
  final String id;
  final String documentId;
  final int versionNumber;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String? changeSummary;
  final String? uploadedBy;
  final DateTime createdAt;

  DocumentVersionModel({
    required this.id,
    required this.documentId,
    required this.versionNumber,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.changeSummary,
    this.uploadedBy,
    required this.createdAt,
  });

  factory DocumentVersionModel.fromJson(Map<String, dynamic> json) {
    return DocumentVersionModel(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      versionNumber: json['version_number'] as int? ?? 1,
      filePath: json['file_path'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      changeSummary: json['change_summary'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'version_number': versionNumber,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'change_summary': changeSummary,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
