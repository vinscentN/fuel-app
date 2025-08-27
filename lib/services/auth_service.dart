// services/auth_service.dart
import '../models/user.dart';

class AuthService {
  // Dummy data for authentication
  static const List<Map<String, dynamic>> _dummyUsers = [
    {
      'id': '1',
      'username': 'test',
      'password': '1234',
      'fullName': 'John Doe',
      'role': 'attendant',
      'isActive': true,
    },
    {
      'id': '2',
      'username': 'manager',
      'password': 'admin',
      'fullName': 'Jane Smith',
      'role': 'manager',
      'isActive': true,
    },
    {
      'id': '3',
      'username': 'attendant2',
      'password': '1234',
      'fullName': 'Mike Johnson',
      'role': 'attendant',
      'isActive': true,
    },
  ];

  Future<User?> login(String username, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final userData = _dummyUsers.firstWhere(
            (user) => user['username'] == username && user['password'] == password,
      );

      return User.fromJson(userData);
    } catch (e) {
      return null; // User not found
    }
  }

  Future<void> logout() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    // Clear any stored tokens or session data
  }

  // API endpoint placeholders for future implementation
  static const String loginEndpoint = '/api/auth/login';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String refreshTokenEndpoint = '/api/auth/refresh';
}
