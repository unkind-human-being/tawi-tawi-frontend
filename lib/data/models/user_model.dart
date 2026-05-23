class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}