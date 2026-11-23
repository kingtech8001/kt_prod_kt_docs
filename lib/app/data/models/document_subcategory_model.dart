class DocumentSubcategoryModel {
  final String id;
  final String categoryId;
  final String name;
  final String code;
  final bool isActive;
  final int displayOrder;

  const DocumentSubcategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.code,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory DocumentSubcategoryModel.fromJson(Map<String, dynamic> json) {
    return DocumentSubcategoryModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}
