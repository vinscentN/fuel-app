import '../constants/api_constants.dart';
import '../models/delivery_order.dart';
import 'api_client.dart';

class DeliveryOrderService {
  final ApiClient _apiClient = ApiClient();

  Future<List<DeliveryOrder>> getHomeDeliveryOrders({
    required String token,
    String? status,
  }) async {
    try {
      final uri = status == null
          ? '${ApiConstants.baseUrl}/delivery-orders/home'
          : '${ApiConstants.baseUrl}/delivery-orders/home?status=$status';
      final response = await _apiClient.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => DeliveryOrder.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[DeliveryOrderService] Error fetching home deliveries: $e');
      rethrow;
    }
  }

  Future<List<DeliveryOrder>> getCommercialDeliveryOrders({
    required String token,
    String? status,
  }) async {
    try {
      final uri = status == null
          ? '${ApiConstants.baseUrl}/delivery-orders/commercial'
          : '${ApiConstants.baseUrl}/delivery-orders/commercial?status=$status';
      final response = await _apiClient.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((json) => DeliveryOrder.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[DeliveryOrderService] Error fetching commercial deliveries: $e');
      rethrow;
    }
  }

  Future<DeliveryOrder> updateDeliveryStatus({
    required int deliveryOrderId,
    required String status,
    required int assignedDriverId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.baseUrl}/delivery-orders/$deliveryOrderId/status',
        body: {
          'status': status,
          'assigned_driver_id': assignedDriverId,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['data'] != null) {
        return DeliveryOrder.fromJson(response['data'] as Map<String, dynamic>);
      }

      throw Exception(response['message'] ?? 'Failed to update delivery status');
    } catch (e) {
      print('[DeliveryOrderService] Error updating delivery status: $e');
      rethrow;
    }
  }
}
