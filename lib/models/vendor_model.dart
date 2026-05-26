class VendorModel {
  final String name;
  final String mobile;
  final String address;
  final VendorLocation location;

  VendorModel({
    required this.name,
    required this.mobile,
    required this.address,
    required this.location,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      address: json['address'] ?? '',
      location: VendorLocation.fromJson(json['location'] ?? {}),
    );
  }
}

class VendorLocation {
  final double latitude;
  final double longitude;

  VendorLocation({required this.latitude, required this.longitude});

  factory VendorLocation.fromJson(Map<String, dynamic> json) {
    return VendorLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
