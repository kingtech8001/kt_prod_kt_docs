class CategoryModel {
  final String id;
  final String name;
  final String code;
  final String? icon;
  final String colorHex;
  final String? description;
  final bool hasCityFilter;
  final bool hasTitleField;

  CategoryModel({
    required this.id,
    required this.name,
    required this.code,
    this.icon,
    this.colorHex = '#3B82F6',
    this.description,
    this.hasCityFilter = true,
    this.hasTitleField = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      icon: json['icon'] as String?,
      colorHex: json['color_hex'] as String? ?? '#3B82F6',
      description: json['description'] as String?,
      hasCityFilter: json['has_city_filter'] as bool? ?? true,
      hasTitleField: json['has_title_field'] as bool? ?? true,
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
      'has_city_filter': hasCityFilter,
      'has_title_field': hasTitleField,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? code,
    String? icon,
    String? colorHex,
    String? description,
    bool? hasCityFilter,
    bool? hasTitleField,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      hasCityFilter: hasCityFilter ?? this.hasCityFilter,
      hasTitleField: hasTitleField ?? this.hasTitleField,
    );
  }
}
