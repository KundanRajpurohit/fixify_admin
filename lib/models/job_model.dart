class JobModel {
  final String username;
  final String address;
  final int? price;
  final String workStatus;
  final String dateTime;
  final String token;
  final String title;

  JobModel({
    required this.username,
    required this.address,
    required this.price,
    required this.workStatus,
    required this.dateTime,
    required this.token,
    required this.title,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      username: json['username'] ?? "",
      address: json['address'] ?? "",
      price: json['price'],
      // nullable
      workStatus: json['work_status'] ?? "",
      dateTime: json['date_time'] ?? "",
      token: json['token'] ?? "",
      title: json['title'] ?? "",
    );
  }
}
