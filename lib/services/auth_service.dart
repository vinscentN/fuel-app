// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/user.dart';
import '../constants/api_constants.dart';

class AuthService {
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse(ApiConstants.login);

    final response = await http.post(
      url,
      body: {"username": username, "password": password},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      if (body["status"] == "success") {
        final token = body["token"];
        final user = User.fromJson(body["data"]);

        return {"token": token, "user": user};
      }
    }

    return null;
  }

  Future<void> logout(String? token) async {
    final url = Uri.parse(ApiConstants.logout);

    await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
  }

  // Request an attendant/operator code reset via email or phone
  Future<Map<String, dynamic>> requestAttendantResetCode(String emailOrPhone) async {
    final api = ApiClient();
    final response = await api.post(
      ApiConstants.attendantsResetCode,
      body: {
        'email_mobile_number': emailOrPhone.trim(),
      },
    );
    return response;
  }
}
