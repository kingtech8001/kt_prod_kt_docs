class ActivityLogModel {
  final String id;
  final String? documentId;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? documentTitle;
  final String action; // 'uploaded', 'viewed', 'downloaded', 'updated', 'shared', 'moved', 'trashed', 'restored'
  final Map<String, dynamic> details;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    this.documentId,
    this.userId,
    this.userName,
    this.userEmail,
    this.documentTitle,
    required this.action,
    this.details = const {},
    required this.createdAt,
  });

  String get actionDisplay {
    switch (action) {
      case 'uploaded':
        return 'Uploaded document';
      case 'viewed':
        return 'Viewed document';
      case 'downloaded':
        return 'Downloaded document';
      case 'updated':
        return 'Updated document details';
      case 'shared':
        return 'Generated share link';
      case 'trashed':
        return 'Moved to trash';
      case 'restored':
        return 'Restored from trash';
      case 'permanently_deleted':
        return 'Permanently deleted';
      default:
        return action;
    }
  }

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

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    final profile = _extractMap(json['profiles']);
    final doc = _extractMap(json['documents']);

    return ActivityLogModel(
      id: json['id'] as String,
      documentId: json['document_id'] as String?,
      userId: json['user_id'] as String?,
      userName: profile?['full_name'] as String?,
      userEmail: profile?['email'] as String?,
      documentTitle: doc?['title'] as String?,
      action: json['action'] as String? ?? 'action',
      details: json['details'] is Map ? Map<String, dynamic>.from(json['details'] as Map) : {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
