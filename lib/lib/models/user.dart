class User {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      fullName: json['fullName'],
      role: json['role'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'role': role,
      'isActive': isActive,
    };
  }
}