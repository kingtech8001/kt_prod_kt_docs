class MasterCityModel {
  final String id;
  final String name;
  final String state;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;

  MasterCityModel({
    required this.id,
    required this.name,
    this.state = 'Gujarat',
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
  });

  factory MasterCityModel.fromJson(Map<String, dynamic> json) {
    return MasterCityModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      state: json['state'] as String? ?? 'Gujarat',
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'state': state,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

class MasterBrandModel {
  final String id;
  final String name;
  final String categoryType;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;

  MasterBrandModel({
    required this.id,
    required this.name,
    this.categoryType = 'appliance',
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
  });

  factory MasterBrandModel.fromJson(Map<String, dynamic> json) {
    return MasterBrandModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      categoryType: json['category_type'] as String? ?? 'appliance',
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category_type': categoryType,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

class MasterApplianceSubcategoryModel {
  final String id;
  final String name;
  final int defaultWarrantyMonths;
  final String iconName;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;

  MasterApplianceSubcategoryModel({
    required this.id,
    required this.name,
    this.defaultWarrantyMonths = 12,
    this.iconName = 'kitchen',
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
  });

  factory MasterApplianceSubcategoryModel.fromJson(Map<String, dynamic> json) {
    return MasterApplianceSubcategoryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      defaultWarrantyMonths: (json['default_warranty_months'] as num?)?.toInt() ?? 12,
      iconName: json['icon_name'] as String? ?? 'kitchen',
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'default_warranty_months': defaultWarrantyMonths,
      'icon_name': iconName,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

class MasterUtilityProviderModel {
  final String id;
  final String name;
  final String utilityType;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;

  MasterUtilityProviderModel({
    required this.id,
    required this.name,
    required this.utilityType,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
  });

  factory MasterUtilityProviderModel.fromJson(Map<String, dynamic> json) {
    return MasterUtilityProviderModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      utilityType: json['utility_type'] as String? ?? 'Electricity / Light',
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'utility_type': utilityType,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}
