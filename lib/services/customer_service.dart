import '../constants/api_constants.dart';
import '../models/customer.dart';
import 'api_client.dart';

class CustomerService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches customers with pagination
  Future<List<Customer>> getCustomers({
    int page = 1,
    String? searchQuery,
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}/customers')
          .replace(queryParameters: queryParams);

      final response = await _apiClient.get(
        uri.toString(),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => Customer.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[CustomerService] Error fetching customers: $e');
      rethrow;
    }
  }

  /// Search customers by phone number
  Future<List<Customer>> searchCustomersByPhone({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/customers?search=$phone',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => Customer.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[CustomerService] Error searching customers: $e');
      rethrow;
    }
  }
}
