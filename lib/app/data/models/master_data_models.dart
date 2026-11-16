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

class MasterLocationModel {
  final String id;
  final String name;
  final String? premiseName;
  final String? flatHouseNo;
  final String? buildingName;
  final String? streetAddress;
  final String areaLocality;
  final String city;
  final String state;
  final String? postalCode;
  final String country;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;

  MasterLocationModel({
    required this.id,
    required this.name,
    this.premiseName,
    this.flatHouseNo,
    this.buildingName,
    this.streetAddress,
    required this.areaLocality,
    required this.city,
    this.state = 'Gujarat',
    this.postalCode,
    this.country = 'India',
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
  });

  String get fullAddress {
    final parts = <String>[];
    if (flatHouseNo != null && flatHouseNo!.trim().isNotEmpty) {
      parts.add(flatHouseNo!.trim());
    }
    if (buildingName != null && buildingName!.trim().isNotEmpty) {
      parts.add(buildingName!.trim());
    }
    if (streetAddress != null && streetAddress!.trim().isNotEmpty) {
      parts.add(streetAddress!.trim());
    }
    if (areaLocality.trim().isNotEmpty) parts.add(areaLocality.trim());
    if (city.trim().isNotEmpty) {
      if (postalCode != null && postalCode!.trim().isNotEmpty) {
        parts.add('${city.trim()} - ${postalCode!.trim()}');
      } else {
        parts.add(city.trim());
      }
    }
    if (state.trim().isNotEmpty) parts.add(state.trim());
    if (country.trim().isNotEmpty) parts.add(country.trim());
    return parts.join(', ');
  }

  String get summary =>
      '$name ($city${postalCode != null && postalCode!.isNotEmpty ? " - $postalCode" : ""}, $country)';

  factory MasterLocationModel.fromJson(Map<String, dynamic> json) {
    return MasterLocationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      premiseName: json['premise_name'] as String?,
      flatHouseNo: json['flat_house_no'] as String?,
      buildingName: json['building_name'] as String?,
      streetAddress: json['street_address'] as String?,
      areaLocality: json['area_locality'] as String? ?? '',
      city: json['city'] as String? ?? 'Rajkot',
      state: json['state'] as String? ?? 'Gujarat',
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String? ?? 'India',
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'premise_name': premiseName,
      'flat_house_no': flatHouseNo,
      'building_name': buildingName,
      'street_address': streetAddress,
      'area_locality': areaLocality,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

