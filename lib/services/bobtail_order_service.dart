import '../constants/api_constants.dart';
import '../models/bobtail_order.dart';
import 'api_client.dart';

class BobtailOrderService {
  final ApiClient _apiClient = ApiClient();

  Future<List<BobtailOrder>> getBobtailOrders({
    required String token,
    String? status,
    int? assignedDriverId,
    int? bobtailId,
    String? orderType,
  }) async {
    try {
      final query = <String, String>{};
      if (status != null && status.isNotEmpty) {
        query['status'] = status;
      }
      if (assignedDriverId != null) {
        query['assigned_driver_id'] = assignedDriverId.toString();
      }
      if (bobtailId != null) {
        query['bobtail_id'] = bobtailId.toString();
      }
      if (orderType != null && orderType.isNotEmpty) {
        query['order_type'] = orderType;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/bobtail-orders')
          .replace(queryParameters: query.isEmpty ? null : query);

      final response = await _apiClient.get(
        uri.toString(),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        return data
            .map((json) => BobtailOrder.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('[BobtailOrderService] Error fetching bobtail orders: $e');
      rethrow;
    }
  }

  Future<BobtailOrder> getBobtailOrder({
    required int id,
    required String token,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/bobtail-orders/$id',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        return BobtailOrder.fromJson(response['data'] as Map<String, dynamic>);
      }

      throw Exception('Failed to load bobtail order');
    } catch (e) {
      print('[BobtailOrderService] Error fetching bobtail order: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeOrder({
    required int id,
    required double actualKg,
    required double unitCost,
    String? notes,
    required String token,
  }) async {
    try {
      final payload = {
        'actual_kg': actualKg,
        'unit_cost': unitCost,
        'notes': notes,
      };

      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/bobtail-orders/$id/complete',
        body: payload,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response;
    } catch (e) {
      print('[BobtailOrderService] Error completing bobtail order: $e');
      rethrow;
    }
  }
}
