class CategoryModel {
  final String id;
  final String name;
  final String code;
  final String? icon;
  final String colorHex;
  final String? description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.code,
    this.icon,
    this.colorHex = '#3B82F6',
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      icon: json['icon'] as String?,
      colorHex: json['color_hex'] as String? ?? '#3B82F6',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'icon': icon,
      'color_hex': colorHex,
      'description': description,
    };
  }
}
