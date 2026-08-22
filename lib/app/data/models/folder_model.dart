class FolderModel {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final String color;
  final String? createdBy;
  final DateTime createdAt;
  final int documentCount;

  FolderModel({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.color = '#64748B',
    this.createdBy,
    required this.createdAt,
    this.documentCount = 0,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parent_id'] as String?,
      color: json['color'] as String? ?? '#64748B',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      documentCount: (json['documents'] as List?)?.length ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parent_id': parentId,
      'color': color,
      'created_by': createdBy,
    };
  }
}
