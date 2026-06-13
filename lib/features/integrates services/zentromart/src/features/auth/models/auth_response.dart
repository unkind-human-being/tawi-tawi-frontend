class AuthResponse {
  final String accessToken;
  final User user;

  AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'user': user.toJson(),
    };
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? shopName;
  final String? shopAddress;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.shopName,
    this.shopAddress,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      // FIXED: Swapped explicit null checks out for clean, idiomatic ?. null-aware chains
      shopName: json['shopName']?.toString(),
      shopAddress: json['shopAddress']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'shopName': shopName,
      'shopAddress': shopAddress,
    };
  }
}
