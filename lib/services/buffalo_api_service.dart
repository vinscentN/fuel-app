import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/buffalo_product.dart';
import '../models/buffalo_sale.dart';
import '../models/buffalo_balance.dart';
import '../models/buffalo_card_info.dart';

class BuffaloApiService {
  static const String baseUrl = 'http://51.91.103.132:5500/api/v1';

  // Test connectivity
  static Future<bool> testConnection() async {
    try {
      print('DEBUG API: Testing connection to $baseUrl');
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      print('DEBUG API: Connection test result: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('DEBUG API: Connection test failed: $e');
      return false;
    }
  }

  // Fetch all products
  static Future<List<BuffaloProduct>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> productsJson = jsonResponse['data'];
          return productsJson
              .map((json) => BuffaloProduct.fromJson(json))
              .toList();
        } else {
          throw Exception('Failed to fetch products: Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to fetch products: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get card information
  static Future<Map<String, dynamic>> getCardInfo(String cardNumber) async {
    try {
      final url = '$baseUrl/card-info';
      final requestBody = {'card_number': cardNumber};

      print('DEBUG API: Calling card-info endpoint');
      print('DEBUG API: URL: $url');
      print('DEBUG API: Request body: $requestBody');
      print('DEBUG API: Time: ${DateTime.now()}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('DEBUG API: Request timed out after 60 seconds');
          throw Exception('Connection timeout - please check network connectivity');
        },
      );

      print('DEBUG API: Response received at: ${DateTime.now()}');
      print('DEBUG API: Response status code: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final data = jsonResponse['data'];
      if (data is Map<String, dynamic>) {
        final rawProductId = data['product_id'] ??
            data['meal_product_id'] ??
            data['default_product_id'] ??
            ((data['product'] is Map<String, dynamic>) ? data['product']['id'] : null);
        print('DEBUG API: card-info product_id candidate: $rawProductId');
      }

      if (response.statusCode == 200) {
        print('DEBUG API: Success - parsing card info');
        return {
          'success': true,
          'data': BuffaloCardInfo.fromJson(jsonResponse['data']),
        };
      } else {
        print('DEBUG API: Failed - status ${response.statusCode}');
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to get card info',
          'errors': jsonResponse['errors'],
        };
      }
    } on http.ClientException catch (e) {
      print('DEBUG API: ClientException: $e');
      return {
        'success': false,
        'message': 'Network error: Cannot reach server. Check WiFi connection.',
      };
    } on FormatException catch (e) {
      print('DEBUG API: FormatException: $e');
      return {
        'success': false,
        'message': 'Invalid response from server',
      };
    } catch (e) {
      print('DEBUG API: Exception: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Submit a sale
  static Future<BuffaloSaleResponse> submitSale(
      BuffaloSaleRequest saleRequest) async {
    try {
      final payload = saleRequest.toJson();
      print('DEBUG API: Calling sale endpoint');
      print('DEBUG API: URL: $baseUrl/sale');
      print('DEBUG API: Request body: $payload');
      final response = await http.post(
        Uri.parse('$baseUrl/sale'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));
      print('DEBUG API: Sale response status: ${response.statusCode}');
      print('DEBUG API: Sale response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return BuffaloSaleResponse.fromJson(jsonResponse);
      } else {
        return BuffaloSaleResponse(
          success: false,
          error: jsonResponse['error'] ??
              jsonResponse['message'] ??
              'Sale failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      return BuffaloSaleResponse(
        success: false,
        error: 'Error submitting sale: $e',
      );
    }
  }

  // Check card balance
  static Future<BuffaloBalanceResponse> checkBalance(
      BuffaloBalanceRequest balanceRequest) async {
    try {
      final payload = balanceRequest.toJson();
      print('DEBUG API: Calling balance endpoint');
      print('DEBUG API: URL: $baseUrl/balance');
      print('DEBUG API: Request body: $payload');
      final response = await http.post(
        Uri.parse('$baseUrl/balance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 30));
      print('DEBUG API: Balance response status: ${response.statusCode}');
      print('DEBUG API: Balance response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return BuffaloBalanceResponse.fromJson(jsonResponse);
      } else {
        return BuffaloBalanceResponse(
          success: false,
          error: jsonResponse['error'] ??
              jsonResponse['message'] ??
              'Balance check failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      return BuffaloBalanceResponse(
        success: false,
        error: 'Error checking balance: $e',
      );
    }
  }

  // Reset PIN (assuming similar endpoint pattern)
  static Future<Map<String, dynamic>> resetPin({
    required String cardNumber,
    required String oldPin,
    required String newPin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-pin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'card_number': cardNumber,
          'old_pin': oldPin,
          'new_pin': newPin,
        }),
      ).timeout(const Duration(seconds: 30));

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': jsonResponse['success'] ?? true,
          'message': jsonResponse['message'] ?? 'PIN reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['error'] ??
              jsonResponse['message'] ??
              'PIN reset failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error resetting PIN: $e',
      };
    }
  }
}
