class AddressModel {
  final String? id;
  final String? documentId;
  final String? premiseName;
  final String? flatHouseNo;
  final String? buildingName;
  final String? streetAddress;
  final String areaLocality;
  final String city;
  final String state;
  final String? postalCode;
  final String country;

  AddressModel({
    this.id,
    this.documentId,
    this.premiseName,
    this.flatHouseNo,
    this.buildingName,
    this.streetAddress,
    required this.areaLocality,
    required this.city,
    this.state = 'Gujarat',
    this.postalCode,
    this.country = 'India',
  });

  String get formattedAddress {
    final parts = <String>[];
    if (premiseName != null && premiseName!.isNotEmpty) parts.add(premiseName!);
    if (flatHouseNo != null && flatHouseNo!.isNotEmpty) parts.add(flatHouseNo!);
    if (buildingName != null && buildingName!.isNotEmpty) parts.add(buildingName!);
    if (streetAddress != null && streetAddress!.isNotEmpty) parts.add(streetAddress!);
    parts.add(areaLocality);
    parts.add(city);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String?,
      documentId: json['document_id'] as String?,
      premiseName: json['premise_name'] as String?,
      flatHouseNo: json['flat_house_no'] as String?,
      buildingName: json['building_name'] as String?,
      streetAddress: json['street_address'] as String?,
      areaLocality: json['area_locality'] as String? ?? '',
      city: json['city'] as String? ?? 'Ahmedabad',
      state: json['state'] as String? ?? 'Gujarat',
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String? ?? 'India',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      'premise_name': premiseName,
      'flat_house_no': flatHouseNo,
      'building_name': buildingName,
      'street_address': streetAddress,
      'area_locality': areaLocality,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
    };
  }
}
