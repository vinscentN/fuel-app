// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/user.dart';
import '../constants/api_constants.dart';

class AuthService {
  /// Mobile login with username and operator code
  Future<Map<String, dynamic>?> mobileLogin(String username, String operatorCode, String serialNumber) async {
    final url = Uri.parse(ApiConstants.mobileLogin);
    final requestBody = {
      "username": username,
      "operator_code": operatorCode,
      "serial_number": serialNumber,
    };

    // Log the request
    print('🔵 ========== MOBILE LOGIN REQUEST ==========');
    print('📍 URL: $url');
    print('📤 REQUEST BODY: ${json.encode(requestBody)}');
    print('🔵 ==========================================');

    try {
      print('⏳ Sending request...');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ REQUEST TIMEOUT after 30 seconds');
          print('💡 Please check:');
          print('   1. Is Laravel server running? (php artisan serve)');
          print('   2. Is the base URL correct? ($url)');
          print('   3. Can you access the URL in browser?');
          throw Exception('Connection timeout - server not responding');
        },
      );

      // Log the response
      print('🟢 ========== MOBILE LOGIN RESPONSE ==========');
      print('📍 URL: $url');
      print('📊 STATUS CODE: ${response.statusCode}');
      print('📥 RESPONSE HEADERS: ${response.headers}');
      print('📥 RESPONSE BODY: ${response.body}');
      print('🟢 ============================================');

      // Parse response body first
      Map<String, dynamic>? body;
      try {
        body = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ Failed to parse response body: $e');
        throw Exception('Invalid server response');
      }

      if (response.statusCode == 200) {
        if (body["success"] == true) {
          final token = body["data"]["token"];
          final user = User.fromJson(body["data"]);

          print('✅ Login successful - User: ${user.fullName}, Designation: ${user.designation}');
          return {"token": token, "user": user};
        } else {
          // Extract error message from backend (200 but success=false)
          print('❌ Login failed - success flag is false');
          final errorMessage = body["message"] ?? "Login failed";
          print('📝 Response message: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        // Handle non-200 status codes (403, 401, 422, etc.)
        print('❌ Login failed - HTTP ${response.statusCode}');
        print('📝 Error body: ${response.body}');

        // Extract error message from response body
        String errorMessage = body["message"] ??
                             body["error"] ??
                             body["detail"] ??
                             "Login failed";

        print('📝 Extracted error message: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('💥 ========== LOGIN ERROR ==========');
      print('❌ Error: $e');
      print('📍 Stack trace: $stackTrace');
      print('💥 ==================================');
      rethrow;
    }
  }

  /// Legacy POS login (keeping for backward compatibility)
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

  // Reset operator code with username, old code, new code, and confirmation
  Future<Map<String, dynamic>> resetOperatorCode({
    required String username,
    required String oldOperatorCode,
    required String newOperatorCode,
    required String newOperatorCodeConfirmation,
  }) async {
    final api = ApiClient();

    print('🔵 ========== RESET OPERATOR CODE REQUEST ==========');
    print('📍 URL: ${ApiConstants.resetOperatorCode}');
    print('👤 Username: $username');
    print('🔵 ==================================================');

    try {
      final response = await api.post(
        ApiConstants.resetOperatorCode,
        body: {
          'username': username.trim(),
          'old_operator_code': oldOperatorCode,
          'new_operator_code': newOperatorCode,
          'new_operator_code_confirmation': newOperatorCodeConfirmation,
        },
      );

      print('🟢 ========== RESET OPERATOR CODE RESPONSE ==========');
      print('✅ Success: ${response['success']}');
      print('📝 Message: ${response['message']}');
      print('🟢 ===================================================');

      return response;
    } catch (e) {
      print('💥 ========== RESET OPERATOR CODE ERROR ==========');
      print('❌ Error: $e');
      print('💥 =================================================');
      rethrow;
    }
  }
}
