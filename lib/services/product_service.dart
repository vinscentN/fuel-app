// services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'session_expiry_service.dart';

class ProductService {
  Future<Map<String, dynamic>> fetchProducts(String token) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/pos/products");

    // Logging the request
    // Note: Do not log sensitive tokens in production; this is for debugging.
    print('[ProductService] GET: ${url.toString()}');
    print('[ProductService] Headers: {Authorization: Bearer ***redacted***, Content-Type: application/json}');

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    // Log response
    print('[ProductService] Response [${response.statusCode}]: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      await SessionExpiryService.handleUnauthorized();
      throw Exception('Session expired. Please sign in again.');
    }
    throw Exception("Failed to fetch products (${response.statusCode})");
  }

  Future<Map<String, dynamic>> fetchProductsByStation(String serviceStationId) async {
    final uri = Uri.parse("${ApiConstants.serviceStationsProducts}/$serviceStationId");

    // Logging the request
    print('[ProductService] GET: ${uri.toString()}');
    print('[ProductService] Fetching products for station: $serviceStationId');

    final response = await http.get(
      uri,
      headers: const {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    // Log response
    print('[ProductService] Response [${response.statusCode}]: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      await SessionExpiryService.handleUnauthorized();
      throw Exception('Session expired. Please sign in again.');
    }
    throw Exception("Failed to fetch products for station $serviceStationId (${response.statusCode})");
  }
}
