class JobModel {
  final String username;
  final String address;
  final double? price;
  final String workStatus;
  final String dateTime;
  final String token;
  final String title;
  final num? distanceKm;

  JobModel({
    required this.username,
    required this.address,
    required this.price,
    required this.workStatus,
    required this.dateTime,
    required this.token,
    required this.title,
    required this.distanceKm,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      username: json['username'] ?? "",
      address: json['address'] ?? "",
      price:
          json['price'] is num
              ? (json['price'] as num).toDouble()
              : double.tryParse(json['price']?.toString() ?? ''),
      // nullable
      workStatus: json['work_status'] ?? "",
      dateTime: json['date_time'] ?? "",
      token: json['token'] ?? "",
      title: json['title'] ?? "",
      distanceKm:
          json['distance_km'] is num
              ? json['distance_km']
              : num.tryParse(json['distance_km']?.toString() ?? ''),
    );
  }
}
